import os
import httpx
import contextvars
from pydantic import BaseModel
from typing import Optional
from app.services.llm_service import generate_recipe, generate_embedding


# Context variables for HTTP callbacks and streaming metadata
auth_token_var = contextvars.ContextVar("auth_token", default=None)
stream_queue_var = contextvars.ContextVar("stream_queue", default=None)
recipe_id_var = contextvars.ContextVar("recipe_id", default=None)

INTERNAL_APP_SECRET = os.getenv("INTERNAL_APP_SECRET", "x-easybake-secret")
RECIPE_SERVICE_URL = os.getenv("RECIPE_SERVICE_URL", "http://localhost:4000").rstrip("/")

# ----------------------------------------------------------------------
# Callback Tools
# ----------------------------------------------------------------------

async def search_user_recipes(query: str) -> dict:
    """
    Search the user's existing recipe book semantically for matching recipes.
    Use this tool when the user is searching for a recipe they own, asking about
    their own recipes, or filtering their recipes by ingredients, tags, or time.
    
    Args:
        query: The search keywords or filter terms to search for.
    """
    auth_token = auth_token_var.get()
    headers = {
        "X-App-Secret": INTERNAL_APP_SECRET,
    }
    if auth_token:
        headers["Authorization"] = auth_token
        
    try:
        # Pre-calculate search vector embedding locally in Python to avoid circular loopback calls
        vector = await generate_embedding(query)
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{RECIPE_SERVICE_URL}/chat/internal/recipes/search",
                json={"embedding": vector},
                headers=headers,
                timeout=30.0
            )
        response.raise_for_status()
        results = response.json()
        return {"status": "success", "results": results}
    except Exception as e:
        return {"status": "error", "error": str(e)}


class ShoppingListItemInput(BaseModel):
    name: str
    amount: Optional[str] = None


async def add_to_shopping_list(items: list[ShoppingListItemInput]) -> dict:
    """
    Add raw items (ingredients, quantities, etc.) directly to the user's shopping list.
    
    Args:
        items: A list of dict items, where each dict has keys 'name' (string, required)
               and 'amount' (string, optional, e.g. "2 cups" or "100g").
    """
    auth_token = auth_token_var.get()
    headers = {
        "X-App-Secret": INTERNAL_APP_SECRET,
    }
    if auth_token:
        headers["Authorization"] = auth_token
        
    try:
        serialized_items = [
            item.model_dump() if hasattr(item, "model_dump") else item 
            for item in items
        ]
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{RECIPE_SERVICE_URL}/chat/internal/shopping-list/add",
                json={"items": serialized_items},
                headers=headers,
                timeout=30.0
            )
        response.raise_for_status()
        added_items = response.json()
        
        q = stream_queue_var.get()
        if q is not None:
            q.put_nowait({"type": "shoppingListAdded", "items": added_items})
            
        return {"status": "success", "items": added_items}
    except Exception as e:
        return {"status": "error", "error": str(e)}


async def add_recipe_to_shopping_list(recipe_name: str) -> dict:
    """
    Add all the ingredients of a specific recipe in the user's recipe book to their shopping list.
    Use this when the user requests to add a recipe by name, or asks to "add this recipe"
    or "add the ingredients of this recipe" to their shopping list.
    
    Args:
        recipe_name: The name/title of the recipe to add. If the user refers to "this recipe" or
                     "the current recipe", pass the title of the recipe context if available,
                     or pass empty string.
    """
    auth_token = auth_token_var.get()
    recipe_id = recipe_id_var.get()
    
    headers = {
        "X-App-Secret": INTERNAL_APP_SECRET,
    }
    if auth_token:
        headers["Authorization"] = auth_token
        
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{RECIPE_SERVICE_URL}/chat/internal/shopping-list/add-recipe",
                json={"recipeName": recipe_name, "recipeId": recipe_id},
                headers=headers,
                timeout=30.0
            )
        response.raise_for_status()
        added_items = response.json()
        
        q = stream_queue_var.get()
        if q is not None:
            q.put_nowait({"type": "shoppingListAdded", "items": added_items})
            
        return {"status": "success", "items": added_items}
    except Exception as e:
        return {"status": "error", "error": str(e)}


async def create_recipe(prompt: str) -> dict:
    """
    Generate a new structured recipe based on the user's prompt (cravings, ingredients, etc.).
    Use this tool when the user explicitly requests a recipe to be created or generated.
    
    Args:
        prompt: Detailed user request for the recipe creation.
    """
    try:
        recipe_schema_obj = await generate_recipe(prompt)
        recipe_dict = recipe_schema_obj.model_dump()
        
        q = stream_queue_var.get()
        if q is not None:
            q.put_nowait({"type": "recipeCreated", "recipe": recipe_dict})
            
        return {"status": "success", "recipe": recipe_dict}
    except Exception as e:
        return {"status": "error", "error": str(e)}


class SearchResultRecipeInput(BaseModel):
    id: str
    title: str
    healthScore: int
    imageUrl: str
    ingredients: list[str]


async def display_recipes(recipes: list[SearchResultRecipeInput]) -> dict:
    """
    Display the filtered list of matching recipes to the user in the UI.
    Only call this tool AFTER you have retrieved candidate recipes using `search_user_recipes`
    and filtered out the irrelevant ones.
    
    Args:
        recipes: A list of filtered recipe objects to display.
    """
    try:
        serialized_recipes = [
            r.model_dump() if hasattr(r, "model_dump") else r
            for r in recipes
        ]
        q = stream_queue_var.get()
        if q is not None:
            q.put_nowait({"type": "searchResults", "recipes": serialized_recipes})
            
        return {"status": "success"}
    except Exception as e:
        return {"status": "error", "error": str(e)}
