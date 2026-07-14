import json
import re
from collections.abc import Iterator
from fastapi import HTTPException
from fastapi.responses import StreamingResponse
from app.core.logger import get_logger

logger = get_logger()

SSE_HEADERS = {
    "Cache-Control": "no-cache",
    "Connection": "keep-alive",
    "X-Accel-Buffering": "no",
}


def stream_json_text_field(raw_stream: Iterator[str], text_field: str = "answer") -> Iterator[str]:
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


def sse_json_generator(raw_stream: Iterator[str]) -> Iterator[str]:
    """Legacy SSE generator for non-structured responses (fallback)."""
    try:
        for chunk in raw_stream:
            if chunk:
                json_obj = json.dumps({"delta": chunk, "type": "text"})
                yield f"data: {json_obj}\n\n"
    finally:
        yield "data: [DONE]\n\n"


def streaming_response(stream: object) -> StreamingResponse:
    return StreamingResponse(
        stream,
        media_type="text/event-stream",
        headers=SSE_HEADERS,
    )


def http_exception_from_error(error: Exception) -> HTTPException:
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


def build_specialist_prompt(prompt: str, recipe_context: str | None) -> str:
    if not recipe_context:
        return prompt

    return (
        "Current recipe context:\n"
        f"{recipe_context}\n\n"
        "User prompt:\n"
        f"{prompt}"
    )


def strip_markdown_json_fences(raw_text: str) -> str:
    cleaned = raw_text.strip()
    cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"\s*```$", "", cleaned)
    return cleaned.strip()
