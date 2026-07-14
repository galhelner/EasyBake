from pathlib import Path
from google.adk import Agent
from app.services.llm_service import MODEL_NAME
from app.agents.tools import add_to_shopping_list, add_recipe_to_shopping_list

# Load instructions from instructions.md in the same directory
instructions_path = Path(__file__).resolve().parent / "instructions.md"
with open(instructions_path, "r", encoding="utf-8") as f:
    shopping_list_instruction = f.read()

def get_shopping_list_specialist_agent(model: str = MODEL_NAME, tools: list = None) -> Agent:
    if tools is None:
        tools = [add_to_shopping_list, add_recipe_to_shopping_list]
    return Agent(
        name="shopping_list_specialist_agent",
        description="Specialist for parsing ingredients and adding items or recipes to the user's shopping list.",
        model=model,
        instruction=shopping_list_instruction,
        tools=tools
    )
