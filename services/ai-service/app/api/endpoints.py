import re

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from app.schemas.recipe import RecipeSchema
from app.schemas.router import (
    MessageRequest,
    RouterRequest,
    RouterResponse,
    SearchFiltersResponse,
)
from app.services.gemini_service import (
    classify_intent,
    generate_recipe,
    parse_search_filters,
    stream_generate_content,
)

router = APIRouter()

SSE_HEADERS = {
    "Cache-Control": "no-cache",
    "Connection": "keep-alive",
    "X-Accel-Buffering": "no",
}


def _streaming_response(stream: object) -> StreamingResponse:
    return StreamingResponse(
        stream,
        media_type="text/event-stream",
        headers=SSE_HEADERS,
    )


def _http_exception_from_error(error: Exception) -> HTTPException:
    error_message = str(error)
    if "RESOURCE_EXHAUSTED" in error_message or "quota" in error_message.lower():
        retry_after_match = re.search(r"retry in ([0-9]+(?:\.[0-9]+)?)s", error_message, re.IGNORECASE)
        retry_after_seconds = None
        if retry_after_match:
            retry_after_seconds = str(max(1, round(float(retry_after_match.group(1)))))

        headers = {"Retry-After": retry_after_seconds} if retry_after_seconds else None
        return HTTPException(
            status_code=429,
            detail=error_message,
            headers=headers,
        )

    return HTTPException(status_code=500, detail=error_message)


def _build_specialist_prompt(prompt: str, recipe_context: str | None) -> str:
    if not recipe_context:
        return prompt

    return (
        "Current recipe context:\n"
        f"{recipe_context}\n\n"
        "User prompt:\n"
        f"{prompt}"
    )

@router.post("/route", response_model=RouterResponse)
async def classify_intent_endpoint(payload: RouterRequest):
    try:
        return await classify_intent(payload)
    except Exception as e:
        raise _http_exception_from_error(e)


@router.post("/generate-recipe", response_model=RecipeSchema)
async def generate_recipe_endpoint(payload: MessageRequest):
    try:
        return await generate_recipe(
            _build_specialist_prompt(payload.prompt, payload.recipe_context)
        )
    except Exception as e:
        raise _http_exception_from_error(e)


@router.post("/stream-assistant")
async def stream_assistant_endpoint(payload: MessageRequest):
    try:
        return _streaming_response(
            stream_generate_content(
                _build_specialist_prompt(payload.prompt, payload.recipe_context),
                "assistant_specialist.md",
            )
        )
    except Exception as e:
        raise _http_exception_from_error(e)


@router.post("/stream-health")
async def stream_health_endpoint(payload: MessageRequest):
    try:
        return _streaming_response(
            stream_generate_content(
                _build_specialist_prompt(payload.prompt, payload.recipe_context),
                "health_specialist.md",
            )
        )
    except Exception as e:
        raise _http_exception_from_error(e)


@router.post("/search-specialist", response_model=SearchFiltersResponse)
async def search_specialist_endpoint(payload: MessageRequest):
    try:
        return await parse_search_filters(
            _build_specialist_prompt(payload.prompt, payload.recipe_context)
        )
    except Exception as e:
        raise _http_exception_from_error(e)