import os
from google import genai
from google.genai import types
from app.schemas.recipe import RecipeSchema

# Load your Markdown instructions
with open("instructions/recipe_creator.md", "r") as f:
    SYSTEM_PROMPT = f.read()

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

async def generate_recipe(user_input: str) -> RecipeSchema:
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=user_input,
        config=types.GenerateContentConfig(
            system_instruction=SYSTEM_PROMPT,
            response_mime_type="application/json",
            # This forces Gemini to match your Pydantic model
            response_schema=RecipeSchema,
        ),
    )
    return response.parsed