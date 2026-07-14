import json
import base64
import binascii
from typing import Optional
from pydantic import BaseModel

from fastapi import APIRouter, HTTPException, Header
from app.core.logger import get_logger
from app.schemas.ingredient import IngredientSchema
from app.schemas.recipe import RecipeSchema
from app.schemas.router import (
    MessageRequest,
    ImageRecipeRequest,
    EmbeddingRequest,
    EmbeddingResponse,
    HealthScoreRequest,
    HealthScoreResponse,
)
from app.services.llm_service import (
    calculate_health_score,
    generate_ingredients_archive,
    generate_embedding,
    generate_recipe_from_image,
    stream_generate_content,
)
from app.services.agent_service import agent_service
from app.utils.helpers import (
    streaming_response,
    stream_json_text_field,
    http_exception_from_error,
    build_specialist_prompt,
)


class ChatHistoryItem(BaseModel):
    role: str
    content: str


class AgentChatRequest(BaseModel):
    prompt: str
    page_context: str
    session_id: str
    recipe_context: Optional[str] = None
    recipe_id: Optional[str] = None
    history: Optional[list[ChatHistoryItem]] = None


router = APIRouter()
logger = get_logger()


@router.post("/agent/chat")
async def agent_chat_endpoint(
    payload: AgentChatRequest,
    authorization: Optional[str] = Header(None)
):
    logger.info("Received request for: /api/agent/chat")
    session_id = payload.session_id
    
    async def sse_event_generator():
        DELIMITER = "---METADATA---"
        DELIMITER_LEN = len(DELIMITER)
        LOOKBACK_SIZE = DELIMITER_LEN - 1
        
        metadata_buffer = ""
        found_delimiter = False
        pending_text = ""
        
        try:
            async for item in agent_service.chat_stream(
                prompt=payload.prompt,
                page_context=payload.page_context,
                session_id=session_id,
                recipe_context=payload.recipe_context,
                recipe_id=payload.recipe_id,
                authorization=authorization,
                history=payload.history,
            ):
                if item == "[DONE]":
                    # Yield any leftover pending text
                    if pending_text and not found_delimiter:
                        yield f"data: {json.dumps({'delta': pending_text, 'type': 'text'})}\n\n"
                    # Process and yield metadata if accumulated
                    if metadata_buffer.strip():
                        try:
                            metadata_obj = json.loads(metadata_buffer.strip())
                            yield f"data: {json.dumps({'type': 'metadata', **metadata_obj})}\n\n"
                        except json.JSONDecodeError:
                            pass
                    yield "data: [DONE]\n\n"
                    break
                
                if isinstance(item, dict):
                    if item.get("type") == "text":
                        chunk_str = item["delta"]
                        
                        if not found_delimiter:
                            search_space = pending_text + chunk_str
                            delimiter_index = search_space.find(DELIMITER)
                            
                            if delimiter_index == -1:
                                if len(search_space) > LOOKBACK_SIZE:
                                    text_to_yield = search_space[:-LOOKBACK_SIZE]
                                    if text_to_yield:
                                        yield f"data: {json.dumps({'delta': text_to_yield, 'type': 'text'})}\n\n"
                                    pending_text = search_space[-LOOKBACK_SIZE:]
                                else:
                                    pending_text = search_space
                            else:
                                text_before_delimiter = search_space[:delimiter_index]
                                if text_before_delimiter:
                                    yield f"data: {json.dumps({'delta': text_before_delimiter, 'type': 'text'})}\n\n"
                                metadata_buffer = search_space[delimiter_index + DELIMITER_LEN:].lstrip('\n')
                                found_delimiter = True
                                pending_text = ""
                        else:
                            metadata_buffer += chunk_str
                    else:
                        yield f"data: {json.dumps(item)}\n\n"
        except Exception as e:
            logger.error(f"SSE generator failed: {e}")
            yield f"data: {json.dumps({'type': 'error', 'message': 'AI stream interrupted. Please try again.'})}\n\n"
            yield "data: [DONE]\n\n"
            
    return streaming_response(sse_event_generator())


@router.post("/generate-recipe-from-image", response_model=RecipeSchema)
async def generate_recipe_from_image_endpoint(payload: ImageRecipeRequest):
    logger.info("Received request for: /api/generate-recipe-from-image")
    try:
        image_bytes = base64.b64decode(payload.image_base64, validate=True)
    except binascii.Error:
        raise HTTPException(status_code=400, detail="Invalid image payload")

    if not image_bytes:
        raise HTTPException(status_code=400, detail="Image payload is empty")

    try:
        image_recipe = await generate_recipe_from_image(image_bytes, payload.mime_type)
        if not image_recipe.can_create or image_recipe.recipe is None:
            raise HTTPException(
                status_code=422,
                detail=image_recipe.error_message or "Unable to create a recipe from this image.",
            )

        return image_recipe.recipe
    except HTTPException:
        raise
    except Exception as e:
        raise http_exception_from_error(e)


@router.post("/stream-assistant")
async def stream_assistant_endpoint(payload: MessageRequest):
    logger.info("Received request for: /api/stream-assistant")
    try:
        raw_stream = stream_generate_content(
            build_specialist_prompt(payload.prompt, payload.recipe_context),
            "assistant_specialist.md",
        )
        # Extract answer text and stream it, then send metadata
        return streaming_response(stream_json_text_field(raw_stream, text_field="answer"))
    except Exception as e:
        raise http_exception_from_error(e)


@router.post("/embeddings", response_model=EmbeddingResponse)
async def embeddings_endpoint(payload: EmbeddingRequest):
    logger.info("Received request for: /api/embeddings")
    try:
        embedding = await generate_embedding(payload.text)
        logger.info("Embedding generation successful.")
        return EmbeddingResponse(embedding=embedding)
    except Exception as e:
        raise http_exception_from_error(e)


@router.post("/analyze-health-score", response_model=HealthScoreResponse)
async def analyze_health_score_endpoint(payload: HealthScoreRequest):
    logger.info("Received request for: /api/analyze-health-score")
    try:
        score = await calculate_health_score(
            payload.title,
            payload.ingredients,
            payload.instructions,
        )
        return HealthScoreResponse(health_score=score)
    except Exception as e:
        raise http_exception_from_error(e)


@router.post("/generate-ingredients", response_model=list[IngredientSchema])
async def generate_ingredients_endpoint():
    logger.info("Received request for: /api/generate-ingredients")

    try:
        return await generate_ingredients_archive()
    except Exception as e:
        raise http_exception_from_error(e)