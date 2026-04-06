from pydantic import BaseModel, Field


class IngredientSchema(BaseModel):
    name: str = Field(min_length=1)
    icon: str = Field(min_length=1)
