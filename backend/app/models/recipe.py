from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class IngredientMeasure(BaseModel):
    amount: Optional[float] = None
    unitShort: Optional[str] = None
    unitLong: Optional[str] = None

class IngredientMeasures(BaseModel):
    us: Optional[IngredientMeasure] = None
    metric: Optional[IngredientMeasure] = None

class ExtendedIngredient(BaseModel):
    id: Optional[int] = None
    aisle: Optional[str] = None
    image: Optional[str] = None
    consistency: Optional[str] = None
    name: Optional[str] = None
    nameClean: Optional[str] = None
    original: Optional[str] = None
    originalName: Optional[str] = None
    amount: Optional[float] = None
    unit: Optional[str] = None
    meta: Optional[List[str]] = Field(default_factory=list)
    measures: Optional[IngredientMeasures] = None

class Equipment(BaseModel):
    id: Optional[int] = None
    name: Optional[str] = None
    localizedName: Optional[str] = None
    image: Optional[str] = None
    temperature: Optional[Dict[str, Any]] = None

class Step(BaseModel):
    number: Optional[int] = None
    step: Optional[str] = None
    ingredients: Optional[List[Dict[str, Any]]] = Field(default_factory=list)
    equipment: Optional[List[Equipment]] = Field(default_factory=list)
    length: Optional[Dict[str, Any]] = Field(default_factory=dict)

class AnalyzedInstruction(BaseModel):
    name: Optional[str] = None
    steps: Optional[List[Step]] = Field(default_factory=list)

class WinePairing(BaseModel):
    pairedWines: Optional[List[str]] = Field(default_factory=list)
    pairingText: Optional[str] = None
    productMatches: Optional[List[Dict[str, Any]]] = Field(default_factory=list)

class Recipe(BaseModel):
    id: Optional[int] = None
    title: Optional[str] = None
    image: Optional[str] = None
    imageType: Optional[str] = None
    readyInMinutes: Optional[int] = None
    servings: Optional[int] = None
    sourceUrl: Optional[str] = None
    vegetarian: Optional[bool] = None
    vegan: Optional[bool] = None
    glutenFree: Optional[bool] = None
    dairyFree: Optional[bool] = None
    veryHealthy: Optional[bool] = None
    cheap: Optional[bool] = None
    veryPopular: Optional[bool] = None
    sustainable: Optional[bool] = None
    lowFodmap: Optional[bool] = None
    weightWatcherSmartPoints: Optional[int] = None
    gaps: Optional[str] = None
    preparationMinutes: Optional[int] = None
    cookingMinutes: Optional[int] = None
    aggregateLikes: Optional[int] = None
    healthScore: Optional[float] = None
    creditsText: Optional[str] = None
    license: Optional[str] = None
    sourceName: Optional[str] = None
    pricePerServing: Optional[float] = None
    extendedIngredients: Optional[List[ExtendedIngredient]] = Field(default_factory=list)
    summary: Optional[str] = None
    cuisines: Optional[List[str]] = Field(default_factory=list)
    dishTypes: Optional[List[str]] = Field(default_factory=list)
    diets: Optional[List[str]] = Field(default_factory=list)
    occasions: Optional[List[str]] = Field(default_factory=list)
    winePairing: Optional[WinePairing] = None
    instructions: Optional[str] = None
    analyzedInstructions: Optional[List[AnalyzedInstruction]] = Field(default_factory=list)
    originalId: Optional[int] = None
    spoonacularScore: Optional[float] = None
    spoonacularSourceUrl: Optional[str] = None

class RecipeSearchRequest(BaseModel):
    ingredients: List[str]
    maxTime: Optional[int] = None
    allergies: Optional[List[str]] = Field(default_factory=list)
    diets: Optional[List[str]] = Field(default_factory=list)
    cuisines: Optional[List[str]] = Field(default_factory=list)
    spiceLevel: Optional[str] = None

class RecipeSearchResponse(BaseModel):
    recipes: List[Recipe]
    raw_gemini: Optional[Any] = None
    raw_gemini_str: Optional[str] = None

    class Config:
        from_attributes = True
