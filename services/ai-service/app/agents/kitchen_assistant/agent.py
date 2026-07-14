from pathlib import Path
from google.adk import Agent
from app.services.llm_service import MODEL_NAME

# Load instructions from instructions.md in the same directory
instructions_path = Path(__file__).resolve().parent / "instructions.md"
with open(instructions_path, "r", encoding="utf-8") as f:
    kitchen_assistant_instruction = f.read()

def get_kitchen_assistant_agent(model: str = MODEL_NAME) -> Agent:
    return Agent(
        name="kitchen_assistant_agent",
        description="Specialist for general kitchen assistance, ingredient substitutions, general culinary advice, and recipe health audits.",
        model=model,
        instruction=kitchen_assistant_instruction,
    )
