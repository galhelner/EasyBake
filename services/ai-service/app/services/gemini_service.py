import asyncio
import os
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

MODEL_NAME = "gemini-2.5-flash"
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


def _format_router_input(request: RouterRequest) -> str:
    return (
        f"page_context: {request.page_context}\n"
        f"message: {request.message}"
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


async def generate_recipe(message: str) -> RecipeSchema:
    return await asyncio.to_thread(
        _generate_structured_content,
        message,
        "recipe_creator.md",
        RecipeSchema,
    )


async def generate_assistant_response(message: str) -> AssistantResponse:
    return await asyncio.to_thread(
        _generate_structured_content,
        message,
        "assistant_specialist.md",
        AssistantResponse,
    )


async def generate_health_audit(message: str) -> HealthAuditResponse:
    return await asyncio.to_thread(
        _generate_structured_content,
        message,
        "health_specialist.md",
        HealthAuditResponse,
    )


async def parse_search_filters(message: str) -> SearchFiltersResponse:
    return await asyncio.to_thread(
        _generate_structured_content,
        message,
        "search_specialist.md",
        SearchFiltersResponse,
    )