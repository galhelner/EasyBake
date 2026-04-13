from typing import List

from pydantic import BaseModel, Field, model_validator

class Ingredient(BaseModel):
    name: str = Field(..., min_length=1)
    amount: str | None = Field(default=None, description="Optional quantity such as 2, 200 g, or 120 ml")
    icon: str | None = Field(default=None, description="Optional emoji icon that represents the ingredient (single emoji only)")

class RecipeSchema(BaseModel):
    title: str = Field(..., description="The name of the dish")
    ingredients: List[Ingredient]
    instructions: List[str]
    healthScore: int = Field(..., ge=0, le=100)


class ImageRecipeExtractionSchema(BaseModel):
    can_create: bool = Field(
        ...,
        description="True when the image can be converted into a valid recipe",
    )
    error_message: str | None = Field(
        default=None,
        description="User-facing reason when can_create is false",
    )
    recipe: RecipeSchema | None = Field(
        default=None,
        description="Generated recipe payload when can_create is true",
    )

    @model_validator(mode="after")
    def validate_payload(self) -> "ImageRecipeExtractionSchema":
        if self.can_create and self.recipe is None:
            raise ValueError("recipe is required when can_create is true")
        if not self.can_create and (self.error_message is None or not self.error_message.strip()):
            raise ValueError("error_message is required when can_create is false")
        return self
