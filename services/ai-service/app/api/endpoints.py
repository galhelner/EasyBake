from fastapi import APIRouter, HTTPException
from app.schemas.recipe import RecipeSchema
from app.schemas.router import (
    AssistantResponse,
    HealthAuditResponse,
    MessageRequest,
    RouterRequest,
    RouterResponse,
    SearchFiltersResponse,
)
from app.services.gemini_service import (
    classify_intent,
    generate_assistant_response,
    generate_health_audit,
    generate_recipe,
    parse_search_filters,
)

router = APIRouter()

@router.post("/route", response_model=RouterResponse)
async def classify_intent_endpoint(payload: RouterRequest):
    try:
        return await classify_intent(payload)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/generate-recipe", response_model=RecipeSchema)
async def generate_recipe_endpoint(payload: MessageRequest):
    try:
        return await generate_recipe(payload.message)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/chat-assistant", response_model=AssistantResponse)
async def assistant_endpoint(payload: MessageRequest):
    try:
        return await generate_assistant_response(payload.message)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/analyze-health", response_model=HealthAuditResponse)
async def health_audit_endpoint(payload: MessageRequest):
    try:
        return await generate_health_audit(payload.message)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/parse-search-filters", response_model=SearchFiltersResponse)
async def parse_search_filters_endpoint(payload: MessageRequest):
    try:
        return await parse_search_filters(payload.message)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))