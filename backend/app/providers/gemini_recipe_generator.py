# app/providers/gemini_recipe_generator.py
import os, json
from typing import List, Dict, Any, Optional, Literal

from pydantic import BaseModel, Field, ValidationError
from google import genai
from app.utils.ai_prompt import build_gemini_recipe_prompt

BLUE = "\x1B[34m"; YELLOW = "\x1B[33m"; RESET = "\x1B[0m"
def _blue(msg: str) -> None:  print(f"{BLUE}{msg}{RESET}")
def _yell(msg: str) -> None:  print(f"{YELLOW}{msg}{RESET}")

def _pretty(obj: Any, max_chars: int = 50000) -> str:
    try:
        s = json.dumps(obj, indent=2, ensure_ascii=False)
    except Exception:
        s = str(obj)
    return s if len(s) <= max_chars else s[:max_chars] + "\n... [truncated]"

# --- Lite, local validation models (no JSON schema sent to Gemini) ---
class _IngredientReq(BaseModel):
    name: str
    quantity: float = 0.0
    unit: Literal["g", "ml", "count"] = "count"

class _NutritionLite(BaseModel):
    calories: Optional[float] = None
    protein_g: Optional[float] = None
    fat_g: Optional[float] = None
    carbs_g: Optional[float] = None

class _RecipeCandidateLite(BaseModel):
    id: Optional[str] = None
    title: str
    readyInMinutes: int = Field(..., gt=0)
    servings: Optional[int] = Field(default=None, gt=0)
    cuisines: List[str] = []
    diets: List[str] = []
    vegetarian: Optional[bool] = None
    vegan: Optional[bool] = None
    glutenFree: Optional[bool] = None
    dairyFree: Optional[bool] = None
    reasons: List[str] = []
    required_ingredients: List[_IngredientReq] = []
    optional_ingredients: List[_IngredientReq] = []
    instructions: List[str] = []
    summary: Optional[str] = None
    nutrition: Optional[_NutritionLite] = None

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
if not GOOGLE_API_KEY:
    _blue("[Gemini][recipes] WARNING: GOOGLE_API_KEY not set — will fall back to stub if called")

async def generate_recipes(
    *,
    query: str,
    max_time: int,
    spice_level: int,            # 0..4 (resolved)
    allergies: List[str],
    cuisines: List[str],
    diets: List[str],
) -> Dict[str, Any]:
    """
    Ask Gemini for JSON (no response_schema). Then parse+validate locally.
    """
    prompt = build_gemini_recipe_prompt(
        query=query,
        max_time=max_time,
        spice_level=spice_level,
        allergies=allergies,
        cuisines=cuisines,
        diets=diets,
    )

    try:
        _blue("[Gemini][recipes] calling gemini-2.5-flash …")
        client = genai.Client(api_key=GOOGLE_API_KEY)
        resp = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config={
                "response_mime_type": "application/json",
                # 👇 NO response_schema — avoids Gemini’s validator issues
            },
        )

        # Log raw JSON
        raw_text = getattr(resp, "text", None)
        if raw_text is None or not raw_text.strip():
            raise RuntimeError("Gemini returned empty JSON response")

        _yell("[Gemini][recipes][RAW text] ↓")
        _yell(_pretty(raw_text, max_chars=2000))

        # Parse JSON
        data = json.loads(raw_text)
        if not isinstance(data, list):
            # Some prompts/models may wrap in an object — try a few common keys
            if isinstance(data, dict) and "candidates" in data and isinstance(data["candidates"], list):
                data = data["candidates"]
            else:
                raise ValueError("Expected a top-level JSON array (or {candidates: [...]})")

        # Validate each candidate
        validated: List[_RecipeCandidateLite] = []
        for i, item in enumerate(data, start=1):
            try:
                validated.append(_RecipeCandidateLite.model_validate(item))
            except ValidationError as ve:
                _yell(f"[Gemini][recipes] item {i} failed validation:\n{ve}")

        if not validated:
            raise ValueError("No valid candidates after validation")

        _blue(f"[Gemini][recipes] validated {len(validated)} candidates")
        _yell("[Gemini][recipes][validated preview] ↓")
        _yell(_pretty([c.model_dump() for c in validated][:1], max_chars=1000))

        return {"candidates": [c.model_dump() for c in validated]}

    except Exception as e:
        _blue(f"[Gemini][recipes] ERROR {e} — returning stub")
        return {
            "candidates": [
                {
                    "id": "stub_r1",
                    "title": "Spicy Garlic Tomato Pasta",
                    "readyInMinutes": min(max_time, 25),
                    "reasons": [
                        "Uses pantry pasta and tomatoes",
                        f"Targets spice level {spice_level}",
                        "Quick mid-week cook",
                    ],
                    "required_ingredients": [
                        {"name": "Pasta", "quantity": 250, "unit": "g"},
                        {"name": "Tomato", "quantity": 4, "unit": "count"},
                        {"name": "Garlic", "quantity": 3, "unit": "count"},
                    ],
                    "optional_ingredients": [],
                    "instructions": [
                        "Boil salted water; cook pasta until al dente.",
                        "Sauté garlic and tomatoes; season to taste.",
                        "Toss pasta with sauce and serve.",
                    ],
                    "cuisines": [], "diets": [],
                },
                {
                    "id": "stub_r2",
                    "title": "Cheesy Veggie Quesadillas",
                    "readyInMinutes": min(max_time, 20),
                    "reasons": ["Great with tortillas + cheese", "Customizable fillings"],
                    "required_ingredients": [
                        {"name": "Tortillas", "quantity": 4, "unit": "count"},
                        {"name": "Cheddar", "quantity": 200, "unit": "g"},
                        {"name": "Onion", "quantity": 1, "unit": "count"},
                    ],
                    "optional_ingredients": [],
                    "instructions": [
                        "Warm tortilla; add cheese and sautéed veggies.",
                        "Fold and toast both sides until melted.",
                        "Slice and serve with salsa.",
                    ],
                    "cuisines": [], "diets": [],
                },
                {
                    "id": "stub_r3",
                    "title": "Zesty Pineapple Fried Rice",
                    "readyInMinutes": min(max_time, 30),
                    "reasons": ["Sweet-heat balance", "One-pan convenience"],
                    "required_ingredients": [
                        {"name": "Rice", "quantity": 300, "unit": "g"},
                        {"name": "Pineapple", "quantity": 0.5, "unit": "count"},
                        {"name": "Eggs", "quantity": 2, "unit": "count"},
                    ],
                    "optional_ingredients": [],
                    "instructions": [
                        "Scramble eggs; set aside.",
                        "Stir-fry rice with pineapple and aromatics.",
                        "Return eggs, season; serve.",
                    ],
                    "cuisines": [], "diets": [],
                },
            ]
        }
