from pathlib import Path
from google.adk import Agent
from app.services.llm_service import MODEL_NAME
from app.agents.tools import search_user_recipes, create_recipe, display_recipes

# Load instructions from instructions.md in the same directory
instructions_path = Path(__file__).resolve().parent / "instructions.md"
with open(instructions_path, "r", encoding="utf-8") as f:
    recipe_specialist_instruction = f.read()

def get_recipe_specialist_agent(model: str = MODEL_NAME, tools: list = None) -> Agent:
    if tools is None:
        tools = [search_user_recipes, create_recipe, display_recipes]
    return Agent(
        name="recipe_specialist_agent",
        description="Specialist for generating new recipes or searching the user's recipe library.",
        model=model,
        instruction=recipe_specialist_instruction,
        tools=tools
    )
