import json
import re
from collections.abc import Iterator

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from app.core.logger import get_logger
from app.schemas.recipe import RecipeSchema
from app.schemas.router import (
    MessageRequest,
    RouterRequest,
    RouterResponse,
    SearchFiltersResponse,
    AssistantResponse,
    HealthAuditResponse,
    EmbeddingRequest,
    EmbeddingResponse,
)
from app.services.gemini_service import (
    classify_intent,
    generate_embedding,
    generate_recipe,
    parse_search_filters,
    stream_generate_content,
)

router = APIRouter()
logger = get_logger()

SSE_HEADERS = {
    "Cache-Control": "no-cache",
    "Connection": "keep-alive",
    "X-Accel-Buffering": "no",
}


def _stream_json_text_field(raw_stream: Iterator[str], text_field: str = "answer") -> Iterator[str]:
    """Stream text immediately, then metadata. Enables true streaming without buffering.
    
    This function implements a two-phase streaming protocol with edge-case handling for
    delimiters split across chunks:
    
    PHASE 1 - TEXT STREAMING:
    - Reads chunks from raw_stream and yields them immediately as type: "text" SSE messages
    - No character-level buffering - entire chunks are sent as single deltas
    - Maintains a look-back buffer to detect delimiters split across chunk boundaries
    - Continues until the ---METADATA--- delimiter is found
    
    PHASE 2 - METADATA:
    - Stops streaming text deltas
    - Buffers remaining chunks (which contain JSON metadata)
    - Parses the JSON and sends one final SSE message with type: "metadata"
    
    Edge Case Handling:
    - If delimiter is split across chunks (e.g., "---META" in chunk 1, "DATA---" in chunk 2),
      the look-back buffer ensures it's detected.
    - Text held in the look-back buffer is only yielded once the delimiter is confirmed
      not to be present.
    
    Args:
        raw_stream: Raw text chunks from Gemini (streaming iterator)
        text_field: Unused (kept for compatibility, metadata now comes from the stream format)
    """
    DELIMITER = "---METADATA---"
    DELIMITER_LEN = len(DELIMITER)  # 14
    LOOKBACK_SIZE = DELIMITER_LEN - 1  # 13
    
    metadata_buffer = ""
    found_delimiter = False
    pending_text = ""  # Text held back in case delimiter spans chunks
    
    try:
        for chunk in raw_stream:
            if not chunk:
                continue
            
            chunk_str = str(chunk)
            
            if not found_delimiter:
                # PHASE 1: Combine pending text with current chunk to search for delimiter
                search_space = pending_text + chunk_str
                delimiter_index = search_space.find(DELIMITER)
                
                if delimiter_index == -1:
                    # Delimiter not found - yield confirmed text, buffer potential end
                    if len(search_space) > LOOKBACK_SIZE:
                        # We have enough text to be confident it's not part of a delimiter
                        text_to_yield = search_space[:-LOOKBACK_SIZE]
                        if text_to_yield:
                            yield f"data: {json.dumps({'delta': text_to_yield, 'type': 'text'})}\n\n"
                        # Keep the last LOOKBACK_SIZE chars in case delimiter starts there
                        pending_text = search_space[-LOOKBACK_SIZE:]
                    else:
                        # search_space is small, hold it all pending
                        pending_text = search_space
                else:
                    # Delimiter found! Yield text before it and switch to metadata phase
                    text_before_delimiter = search_space[:delimiter_index]
                    if text_before_delimiter:
                        yield f"data: {json.dumps({'delta': text_before_delimiter, 'type': 'text'})}\n\n"
                    
                    # Start buffering metadata (everything after the delimiter)
                    metadata_buffer = search_space[delimiter_index + DELIMITER_LEN:].lstrip('\n')
                    found_delimiter = True
                    pending_text = ""
            else:
                # PHASE 2: Accumulate metadata chunks
                metadata_buffer += chunk_str
        
        # After stream ends, process metadata
        if metadata_buffer.strip():
            try:
                # Parse the JSON metadata line
                metadata_obj = json.loads(metadata_buffer.strip())
                # Send metadata as a single SSE message
                metadata_message = {"type": "metadata", **metadata_obj}
                yield f"data: {json.dumps(metadata_message)}\n\n"
            except json.JSONDecodeError:
                # Log but don't fail - malformed JSON is non-fatal
                pass
    
    finally:
        # Send completion marker
        yield "data: [DONE]\n\n"


def _sse_json_generator(raw_stream: Iterator[str]) -> Iterator[str]:
    """Legacy SSE generator for non-structured responses (fallback)."""
    try:
        for chunk in raw_stream:
            if chunk:
                json_obj = json.dumps({"delta": chunk, "type": "text"})
                yield f"data: {json_obj}\n\n"
    finally:
        yield "data: [DONE]\n\n"


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
    logger.info("Received request for: /api/route")
    try:
        return await classify_intent(payload)
    except Exception as e:
        raise _http_exception_from_error(e)


@router.post("/generate-recipe", response_model=RecipeSchema)
async def generate_recipe_endpoint(payload: MessageRequest):
    logger.info("Received request for: /api/generate-recipe")
    try:
        return await generate_recipe(
            _build_specialist_prompt(payload.prompt, payload.recipe_context)
        )
    except Exception as e:
        raise _http_exception_from_error(e)


@router.post("/stream-assistant")
async def stream_assistant_endpoint(payload: MessageRequest):
    logger.info("Received request for: /api/stream-assistant")
    try:
        raw_stream = stream_generate_content(
            _build_specialist_prompt(payload.prompt, payload.recipe_context),
            "assistant_specialist.md",
        )
        # Extract answer text and stream it, then send metadata
        return _streaming_response(_stream_json_text_field(raw_stream, text_field="answer"))
    except Exception as e:
        raise _http_exception_from_error(e)


@router.post("/stream-health")
async def stream_health_endpoint(payload: MessageRequest):
    logger.info("Received request for: /api/stream-health")
    try:
        raw_stream = stream_generate_content(
            _build_specialist_prompt(payload.prompt, payload.recipe_context),
            "health_specialist.md",
        )
        # Extract summary text and stream it, then send metadata
        return _streaming_response(_stream_json_text_field(raw_stream, text_field="summary"))
    except Exception as e:
        raise _http_exception_from_error(e)


@router.post("/search-specialist", response_model=SearchFiltersResponse)
async def search_specialist_endpoint(payload: MessageRequest):
    logger.info("Received request for: /api/search-specialist")
    try:
        return await parse_search_filters(
            _build_specialist_prompt(payload.prompt, payload.recipe_context)
        )
    except Exception as e:
        raise _http_exception_from_error(e)


@router.post("/embeddings", response_model=EmbeddingResponse)
async def embeddings_endpoint(payload: EmbeddingRequest):
    logger.info("Received request for: /api/embeddings")
    try:
        embedding = await generate_embedding(payload.text)
        logger.info("Embedding generation successful.")
        return EmbeddingResponse(embedding=embedding)
    except Exception as e:
        raise _http_exception_from_error(e)