import asyncio
import json
import os
from collections.abc import Iterator
from functools import lru_cache
from pathlib import Path
from typing import TypeVar

from google import genai
from google.genai import types
from google.genai.errors import APIError
from pydantic import BaseModel, TypeAdapter

from app.core.logger import get_logger
from app.schemas.ingredient import IngredientSchema
from app.schemas.recipe import ImageRecipeExtractionSchema, RecipeSchema
from app.schemas.router import (
    AssistantResponse,
    HealthScoreResponse,
    HealthAuditResponse,
    RouterRequest,
    RouterResponse,
    SearchFiltersResponse,
    ShoppingListResponse,
)
from app.utils.helpers import strip_markdown_json_fences

MODEL_NAME = os.getenv("GEMINI_MODEL", "gemini-3.1-flash-lite")
FALLBACK_MODEL_NAME = os.getenv("GEMINI_FALLBACK_MODEL", "gemini-3.1-flash-lite")
EMBEDDING_DIM = int(os.getenv("GEMINI_EMBEDDING_DIM", "768"))
INSTRUCTIONS_DIR = Path(__file__).resolve().parents[1] / "instructions"
logger = get_logger()

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

SchemaT = TypeVar("SchemaT", bound=BaseModel)
IngredientListAdapter = TypeAdapter(list[IngredientSchema])
ALLOWED_INTENTS_BY_CONTEXT: dict[str, set[str]] = {
    "home": {"CREATE_RECIPE", "SEARCH_RECIPES", "GENERAL_CHAT", "ADD_TO_SHOPPING_LIST"},
    "recipe_detail": {"ASSISTANT_HELP", "HEALTH_AUDIT", "GENERAL_CHAT", "ADD_TO_SHOPPING_LIST"},
}


@lru_cache(maxsize=None)
def _load_instruction(filename: str) -> str:
    return (INSTRUCTIONS_DIR / filename).read_text(encoding="utf-8")


def _load_instruction_safe(filename: str) -> str:
    try:
        return _load_instruction(filename)
    except FileNotFoundError:
        return ""


def is_fallback_worthy_error(error: Exception) -> bool:
    """Return True when an error indicates transient model unavailability or rate limiting."""
    target: Exception = error
    last_attempt = getattr(error, "last_attempt", None)
    if last_attempt is not None and hasattr(last_attempt, "exception"):
        inner = last_attempt.exception()
        if isinstance(inner, Exception):
            target = inner

    if isinstance(target, APIError) and getattr(target, "code", None) in (429, 503):
        return True

    message = str(target)
    return any(token in message for token in ("503", "UNAVAILABLE", "429", "RESOURCE_EXHAUSTED"))


def _generate_content_with_fallback(
    *,
    contents: object,
    config: types.GenerateContentConfig,
    model: str = MODEL_NAME,
):
    try:
        return client.models.generate_content(
            model=model,
            contents=contents,
            config=config,
        )
    except Exception as error:
        if not FALLBACK_MODEL_NAME or FALLBACK_MODEL_NAME == model or not is_fallback_worthy_error(error):
            raise
        logger.warning(
            f"Primary model '{model}' failed ({error}); falling back to '{FALLBACK_MODEL_NAME}'."
        )
        return client.models.generate_content(
            model=FALLBACK_MODEL_NAME,
            contents=contents,
            config=config,
        )


def _generate_structured_content(
    contents: str,
    system_instruction: str,
    response_schema: type[SchemaT],
) -> SchemaT:
    response = _generate_content_with_fallback(
        contents=contents,
        config=types.GenerateContentConfig(
            system_instruction=system_instruction,
            response_mime_type="application/json",
            response_schema=response_schema,
        ),
    )

    parsed_response = response.parsed
    if parsed_response is None:
        raise ValueError("Gemini returned an unparseable structured response")

    return parsed_response


def _extract_embedding_values(response: object) -> list[float]:
    embeddings = getattr(response, "embeddings", None)
    if embeddings:
        first_embedding = embeddings[0]
        values = getattr(first_embedding, "values", None)
        if values is not None:
            return [float(value) for value in values]

    embedding = getattr(response, "embedding", None)
    if embedding is not None:
        values = getattr(embedding, "values", None)
        if values is not None:
            return [float(value) for value in values]

    raise ValueError("Gemini returned an unexpected embedding response")


def _generate_embedding_sync(text: str) -> list[float]:
    try:
        response = client.models.embed_content(
            model="gemini-embedding-001",
            contents=text,
            config=types.EmbedContentConfig(output_dimensionality=EMBEDDING_DIM),
        )
    except TypeError:
        # Backward compatibility for older SDK variants that do not expose embed config.
        response = client.models.embed_content(
            model="gemini-embedding-001",
            contents=text,
        )

    values = _extract_embedding_values(response)

    if len(values) == EMBEDDING_DIM:
        return values

    if len(values) > EMBEDDING_DIM:
        return values[:EMBEDDING_DIM]

    raise ValueError(
        f"Gemini returned {len(values)} embedding dimensions, expected at least {EMBEDDING_DIM}"
    )


def _open_stream(model: str, prompt: str, config: types.GenerateContentConfig):
    return client.models.generate_content_stream(
        model=model,
        contents=prompt,
        config=config,
    )


def stream_generate_content(prompt: str, instruction_file: str) -> Iterator[str]:
    config = types.GenerateContentConfig(
        system_instruction=_load_instruction(instruction_file),
    )

    try:
        stream = _open_stream(MODEL_NAME, prompt, config)
    except Exception as error:
        if not FALLBACK_MODEL_NAME or FALLBACK_MODEL_NAME == MODEL_NAME or not is_fallback_worthy_error(error):
            raise
        logger.warning(
            f"Primary model '{MODEL_NAME}' stream failed ({error}); falling back to '{FALLBACK_MODEL_NAME}'."
        )
        stream = _open_stream(FALLBACK_MODEL_NAME, prompt, config)

    def _raw_chunk_iterator() -> Iterator[str]:
        for chunk in stream:
            chunk_text = getattr(chunk, "text", None)
            if not isinstance(chunk_text, str):
                continue

            if not chunk_text:
                continue

            yield chunk_text

    return _raw_chunk_iterator()


def _format_router_input(request: RouterRequest) -> str:
    recipe_context = (
        f"recipe_context:\n{request.recipe_context}\n"
        if request.recipe_context
        else ""
    )
    return (
        f"page_context: {request.page_context}\n"
        f"{recipe_context}"
        f"prompt: {request.prompt}"
    )


def _truncate_prompt(prompt: str, max_chars: int = 180) -> str:
    normalized = " ".join(prompt.split())
    if len(normalized) <= max_chars:
        return normalized
    return f"{normalized[:max_chars]}..."


def _enforce_context_intent_policy(
    request: RouterRequest,
    response: RouterResponse,
) -> RouterResponse:
    allowed_intents = ALLOWED_INTENTS_BY_CONTEXT.get(request.page_context, set())
    if response.intent in allowed_intents:
        return response

    # Safety fallback: keep routing inside allowed capabilities for this page.
    return RouterResponse(intent="GENERAL_CHAT", confidence=min(response.confidence, 0.45))


async def classify_intent(request: RouterRequest) -> RouterResponse:
    response = await asyncio.to_thread(
        _generate_structured_content,
        _format_router_input(request),
        _load_instruction_safe("router.md"),
        RouterResponse,
    )
    return _enforce_context_intent_policy(request, response)


RECIPE_CREATOR_INSTRUCTION_PATH = Path(__file__).resolve().parents[1] / "agents" / "recipe_specialist" / "recipe_creator.md"


async def generate_recipe(prompt: str) -> RecipeSchema:
    instruction = RECIPE_CREATOR_INSTRUCTION_PATH.read_text(encoding="utf-8")
    recipe = await asyncio.to_thread(
        _generate_structured_content,
        prompt,
        instruction,
        RecipeSchema,
    )
    ingredient_names = [ingredient.name for ingredient in recipe.ingredients]
    score = await calculate_health_score(recipe.title, ingredient_names, recipe.instructions)
    recipe.healthScore = score
    return recipe


def _generate_recipe_from_image_sync(
    image_bytes: bytes,
    mime_type: str,
) -> ImageRecipeExtractionSchema:
    response = _generate_content_with_fallback(
        contents=[types.Part.from_bytes(data=image_bytes, mime_type=mime_type)],
        config=types.GenerateContentConfig(
            system_instruction=_load_instruction("image_recipe_creator.md"),
            response_mime_type="application/json",
            response_schema=ImageRecipeExtractionSchema,
        ),
    )

    parsed_response = response.parsed
    if parsed_response is None:
        raise ValueError("Gemini returned an unparseable image recipe response")

    return parsed_response


async def generate_recipe_from_image(
    image_bytes: bytes,
    mime_type: str,
) -> ImageRecipeExtractionSchema:
    return await asyncio.to_thread(
        _generate_recipe_from_image_sync,
        image_bytes,
        mime_type,
    )


async def generate_assistant_response(prompt: str) -> AssistantResponse:
    return await asyncio.to_thread(
        _generate_structured_content,
        prompt,
        _load_instruction_safe("assistant_specialist.md"),
        AssistantResponse,
    )


async def generate_health_audit(prompt: str) -> HealthAuditResponse:
    return await asyncio.to_thread(
        _generate_structured_content,
        prompt,
        _load_instruction_safe("health_specialist.md"),
        HealthAuditResponse,
    )


async def parse_search_filters(prompt: str) -> SearchFiltersResponse:
    return await asyncio.to_thread(
        _generate_structured_content,
        prompt,
        _load_instruction_safe("search_specialist.md"),
        SearchFiltersResponse,
    )


async def parse_shopping_list(prompt: str, recipe_context: str | None = None) -> ShoppingListResponse:
    contents = (
        f"recipe_context:\n{recipe_context}\n\nprompt: {prompt}"
        if recipe_context
        else f"prompt: {prompt}"
    )
    return await asyncio.to_thread(
        _generate_structured_content,
        contents,
        _load_instruction_safe("shopping_list_specialist.md"),
        ShoppingListResponse,
    )


async def generate_embedding(text: str) -> list[float]:
    embedding = await asyncio.to_thread(_generate_embedding_sync, text)
    logger.info("Embedding generation successful.")
    return embedding


def _calculate_health_score_sync(
    title: str,
    ingredients: list[str],
    instructions: list[str],
) -> int:
    response = _generate_content_with_fallback(
        contents=(
            f"Title: {title}\n"
            f"Ingredients: {', '.join(ingredients)}\n"
            f"Instructions: {' '.join(instructions)}"
        ),
        config=types.GenerateContentConfig(
            system_instruction=(
                "Analyze the nutritional balance of the provided recipe. "
                "Return a single integer between 0-100. "
                "High protein/fiber/veg = high score. "
                "High sugar/trans-fat/processed = low score."
            ),
            response_mime_type="application/json",
            response_schema=HealthScoreResponse,
        ),
    )

    parsed_response = response.parsed
    if parsed_response is None:
        raise ValueError("Gemini returned an unparseable health score response")

    score = int(parsed_response.health_score)
    return max(0, min(100, score))


async def calculate_health_score(
    title: str,
    ingredients: list[str],
    instructions: list[str],
) -> int:
    score = await asyncio.to_thread(
        _calculate_health_score_sync,
        title,
        ingredients,
        instructions,
    )
    logger.info(f"Calculated Health Score for {title}: {score}")
    return score


def _extract_text_from_generative_response(response: object) -> str:
    response_text = getattr(response, "text", None)
    if isinstance(response_text, str) and response_text.strip():
        return response_text

    candidates = getattr(response, "candidates", None)
    if candidates:
        for candidate in candidates:
            content = getattr(candidate, "content", None)
            parts = getattr(content, "parts", None)
            if not parts:
                continue

            text_parts: list[str] = []
            for part in parts:
                part_text = getattr(part, "text", None)
                if isinstance(part_text, str) and part_text.strip():
                    text_parts.append(part_text)

            if text_parts:
                return "".join(text_parts)

    raise ValueError("Gemini returned no text for ingredient generation")


def _generate_ingredients_archive_sync() -> list[IngredientSchema]:
    response = _generate_content_with_fallback(
        contents="Generate the ingredient archive now.",
        config=types.GenerateContentConfig(
            system_instruction=_load_instruction("ingredient_generator.md"),
        ),
    )
    raw_text = _extract_text_from_generative_response(response)
    cleaned_text = strip_markdown_json_fences(raw_text)

    try:
        payload = json.loads(cleaned_text)
    except json.JSONDecodeError as error:
        raise ValueError("Gemini returned invalid ingredient JSON") from error

    ingredients = IngredientListAdapter.validate_python(payload)
    if len(ingredients) < 150:
        raise ValueError("Gemini returned fewer than 150 ingredients")

    return ingredients


async def generate_ingredients_archive() -> list[IngredientSchema]:
    return await asyncio.to_thread(_generate_ingredients_archive_sync)
