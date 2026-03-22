from typing import Literal

from pydantic import AliasChoices, BaseModel, Field, field_validator


class RouterRequest(BaseModel):
    prompt: str = Field(
        ...,
        min_length=1,
        validation_alias=AliasChoices("prompt", "message"),
        description="User prompt to classify",
    )
    page_context: Literal["home", "recipe_detail"] = Field(
        ...,
        description="Normalized UI context. Allowed values: home, recipe_detail",
    )
    recipe_context: str | None = Field(
        default=None,
        description="Optional formatted recipe context when the user is on a recipe detail page",
    )

    @field_validator("page_context", mode="before")
    @classmethod
    def normalize_page_context(cls, value: object) -> object:
        if not isinstance(value, str):
            return value

        normalized = value.strip().lower().replace("-", "_").replace(" ", "_")
        if normalized in {"home", "homepage", "recipes_page", "recipe_list", "discover"}:
            return "home"
        if normalized in {"recipe_detail", "recipe_details", "recipe_page", "recipe_detail_page"}:
            return "recipe_detail"
        return normalized


class RouterResponse(BaseModel):
    intent: Literal[
        "CREATE_RECIPE",
        "SEARCH_RECIPES",
        "HEALTH_AUDIT",
        "ASSISTANT_HELP",
        "GENERAL_CHAT",
    ]
    confidence: float = Field(..., ge=0.0, le=1.0)


class MessageRequest(BaseModel):
    prompt: str = Field(
        ...,
        min_length=1,
        validation_alias=AliasChoices("prompt", "message"),
        description="User prompt to send to a specialist",
    )
    recipe_context: str | None = Field(
        default=None,
        description="Optional formatted recipe context when the user is on a recipe detail page",
    )


class AssistantResponse(BaseModel):
    answer: str = Field(..., description="Helpful kitchen assistant response")
    suggested_swaps: list[str] = Field(default_factory=list, description="Ingredient swap suggestions when relevant")
    technique_tips: list[str] = Field(default_factory=list, description="Cooking technique tips when relevant")


class HealthAuditResponse(BaseModel):
    summary: str = Field(..., description="Nutrition-focused answer for the user")
    healthier_swaps: list[str] = Field(default_factory=list, description="Actionable healthier substitutions")
    nutrition_flags: list[str] = Field(default_factory=list, description="Important nutrition considerations")


class SearchFiltersResponse(BaseModel):
    query: str = Field(..., description="Normalized search query for downstream retrieval")
    ingredients: list[str] = Field(default_factory=list, description="Ingredients explicitly requested by the user")
    tags: list[str] = Field(default_factory=list, description="Dietary or descriptive tags such as vegan or quick")
    max_time_minutes: int | None = Field(default=None, ge=1, description="Maximum cook time if specified")
    meal_type: str | None = Field(default=None, description="Meal type such as breakfast, lunch, dinner, or dessert")
    cuisine: str | None = Field(default=None, description="Cuisine preference if present")


class EmbeddingRequest(BaseModel):
    text: str = Field(..., min_length=1, description="Text to convert into an embedding vector")


class EmbeddingResponse(BaseModel):
    embedding: list[float] = Field(..., description="Embedding vector from gemini-embedding-001")


class HealthScoreRequest(BaseModel):
    title: str = Field(..., min_length=1, description="Recipe title")
    ingredients: list[str] = Field(default_factory=list, description="List of ingredient names")
    instructions: list[str] = Field(default_factory=list, description="Recipe instructions")


class HealthScoreResponse(BaseModel):
    health_score: int = Field(..., ge=0, le=100, description="Calculated recipe health score")