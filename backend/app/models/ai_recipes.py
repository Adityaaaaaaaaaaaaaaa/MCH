from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class IngredientReq(BaseModel):
    name: str
    quantity: float = 0.0
    unit: str = Field(default="count", pattern="^(g|ml|count)$")

class NutritionLite(BaseModel):
    calories: Optional[float] = None
    protein_g: Optional[float] = None
    fat_g: Optional[float] = None
    carbs_g: Optional[float] = None

class RecipeCandidate(BaseModel):
    id: str                       # prompt requires an id; make it required
    title: str
    readyInMinutes: int = Field(..., gt=0)
    servings: Optional[int] = Field(default=None, gt=0)

    cuisines: List[str] = Field(default_factory=list)
    diets: List[str]    = Field(default_factory=list)

    vegetarian: Optional[bool] = None
    vegan: Optional[bool]      = None
    glutenFree: Optional[bool] = None
    dairyFree: Optional[bool]  = None

    reasons: List[str] = Field(default_factory=list)
    required_ingredients: List[IngredientReq] = Field(default_factory=list)
    optional_ingredients: List[IngredientReq] = Field(default_factory=list)

    # 🔁 IMPORTANT: strings, not objects — matches your prompt
    instructions: List[str] = Field(default_factory=list)

    summary: Optional[str] = None
    nutrition: Optional[NutritionLite] = None

    # future-proof
    extra: Dict[str, Any] = Field(default_factory=dict)
