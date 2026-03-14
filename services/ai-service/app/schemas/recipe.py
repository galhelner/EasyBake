from pydantic import BaseModel, Field
from typing import List

class Ingredient(BaseModel):
    name: str
    amount: float
    unit: str

class RecipeSchema(BaseModel):
    title: str = Field(..., description="The name of the dish")
    ingredients: List[Ingredient]
    instructions: List[str]
    health_score: int = Field(..., ge=1, le=10)