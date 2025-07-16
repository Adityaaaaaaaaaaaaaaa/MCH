from pydantic import BaseModel, Field
from typing import List, Optional

class RecipeSearchRequest(BaseModel):
    ingredients: List[str]
    maxTime: int
    allergies: Optional[List[str]] = Field(default_factory=list)
    diets: Optional[List[str]] = Field(default_factory=list)
    cuisines: Optional[List[str]] = Field(default_factory=list)
    spiceLevel: Optional[str] = ""

class Ingredient(BaseModel):
    name: str
    quantity: str

class Recipe(BaseModel):
    id: Optional[str] = None
    title: str
    summary: Optional[str] = ""
    imageUrl: Optional[str] = ""
    totalTime: Optional[int] = 0
    ingredients: List[Ingredient] = Field(default_factory=list)
    instructions: List[str] = Field(default_factory=list)
    equipment: List[str] = Field(default_factory=list)
    substitutions: List[str] = Field(default_factory=list)
    website: Optional[str] = ""
    videos: List[str] = Field(default_factory=list)
    aiGenerated: bool = False

class RecipeSearchResponse(BaseModel):
    recipes: List[Recipe]
    raw_gemini: Optional[dict] = None  # Optional for debugging
