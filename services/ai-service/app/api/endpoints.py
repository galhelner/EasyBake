from fastapi import APIRouter, HTTPException
from app.schemas.recipe import RecipeSchema
from app.services.gemini_service import generate_recipe

router = APIRouter()

@router.post("/parse-recipe", response_model=RecipeSchema)
async def parse_recipe_endpoint(payload: dict):
    user_prompt = payload.get("prompt")
    if not user_prompt:
        raise HTTPException(status_code=400, detail="No prompt provided")
    
    try:
        recipe = await generate_recipe(user_prompt)
        return recipe
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))