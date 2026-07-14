from pathlib import Path
from google.adk import Agent
from app.services.llm_service import MODEL_NAME
from app.agents.recipe_specialist.agent import get_recipe_specialist_agent
from app.agents.shopping_list_specialist.agent import get_shopping_list_specialist_agent
from app.agents.kitchen_assistant.agent import get_kitchen_assistant_agent

# Load instructions from instructions.md in the same directory
instructions_path = Path(__file__).resolve().parent / "instructions.md"
with open(instructions_path, "r", encoding="utf-8") as f:
    root_router_instruction = f.read()

def get_root_router_agent(model: str = MODEL_NAME, sub_agents: list = None) -> Agent:
    if sub_agents is None:
        sub_agents = [
            get_recipe_specialist_agent(),
            get_shopping_list_specialist_agent(),
            get_kitchen_assistant_agent(),
        ]
    return Agent(
        name="root_router_agent",
        description="Coordinator router agent that delegates user requests to the appropriate specialist agent.",
        model=model,
        instruction=root_router_instruction,
        sub_agents=sub_agents,
    )
