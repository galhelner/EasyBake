from typing import List

from pydantic import BaseModel, Field

class Ingredient(BaseModel):
    name: str = Field(..., min_length=1)
    amount: str | None = Field(default=None, description="Optional quantity such as 2, 200 g, or 120 ml")
    icon: str | None = Field(default=None, description="Optional emoji icon that represents the ingredient (single emoji only)")

class RecipeSchema(BaseModel):
    title: str = Field(..., description="The name of the dish")
    ingredients: List[Ingredient]
    instructions: List[str]
    healthScore: int = Field(..., ge=0, le=100)
