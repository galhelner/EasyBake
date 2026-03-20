import asyncio
import os
from collections.abc import Iterator
from functools import lru_cache
from pathlib import Path
from typing import TypeVar

from google import genai
from google.genai import types
from pydantic import BaseModel

from app.schemas.recipe import RecipeSchema
from app.schemas.router import (
    AssistantResponse,
    HealthAuditResponse,
    RouterRequest,
    RouterResponse,
    SearchFiltersResponse,
)

MODEL_NAME = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
INSTRUCTIONS_DIR = Path(__file__).resolve().parents[1] / "instructions"

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

SchemaT = TypeVar("SchemaT", bound=BaseModel)
ALLOWED_INTENTS_BY_CONTEXT: dict[str, set[str]] = {
    "home": {"CREATE_RECIPE", "SEARCH_RECIPES", "GENERAL_CHAT"},
    "recipe_detail": {"ASSISTANT_HELP", "HEALTH_AUDIT", "GENERAL_CHAT"},
}


@lru_cache(maxsize=None)
def _load_instruction(filename: str) -> str:
    return (INSTRUCTIONS_DIR / filename).read_text(encoding="utf-8")


def _generate_structured_content(
    contents: str,
    instruction_file: str,
    response_schema: type[SchemaT],
) -> SchemaT:
    response = client.models.generate_content(
        model=MODEL_NAME,
        contents=contents,
        config=types.GenerateContentConfig(
            system_instruction=_load_instruction(instruction_file),
            response_mime_type="application/json",
            response_schema=response_schema,
        ),
    )

    parsed_response = response.parsed
    if parsed_response is None:
        raise ValueError("Gemini returned an unparseable structured response")

    return parsed_response


def stream_generate_content(prompt: str, instruction_file: str) -> Iterator[str]:
    config = types.GenerateContentConfig(
        system_instruction=_load_instruction(instruction_file),
    )

    if hasattr(client.models, "generate_content_stream"):
        stream = client.models.generate_content_stream(
            model=MODEL_NAME,
            contents=prompt,
            config=config,
        )
    else:
        stream = client.models.generate_content(
            model=MODEL_NAME,
            contents=prompt,
            config=config,
            stream=True,
        )

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
        "router.md",
        RouterResponse,
    )
    return _enforce_context_intent_policy(request, response)


async def generate_recipe(prompt: str) -> RecipeSchema:
    return await asyncio.to_thread(
        _generate_structured_content,
        prompt,
        "recipe_creator.md",
        RecipeSchema,
    )


async def generate_assistant_response(prompt: str) -> AssistantResponse:
    return await asyncio.to_thread(
        _generate_structured_content,
        prompt,
        "assistant_specialist.md",
        AssistantResponse,
    )


async def generate_health_audit(prompt: str) -> HealthAuditResponse:
    return await asyncio.to_thread(
        _generate_structured_content,
        prompt,
        "health_specialist.md",
        HealthAuditResponse,
    )


async def parse_search_filters(prompt: str) -> SearchFiltersResponse:
    return await asyncio.to_thread(
        _generate_structured_content,
        prompt,
        "search_specialist.md",
        SearchFiltersResponse,
    )