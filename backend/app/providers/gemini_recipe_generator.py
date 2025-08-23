# app/providers/gemini_recipe_generator.py
import os, json
from typing import List, Dict, Any, Optional, Literal
from pydantic import BaseModel, Field, ValidationError, field_validator
from google import genai
from app.utils.ai_prompt import build_gemini_recipe_prompt
import json
import re
from typing import Tuple

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
    readyInMinutes: int = Field(..., description="Must be > 0")
    servings: Optional[int] = None
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
    
    @field_validator("readyInMinutes")
    def check_ready(cls, v):
        if v <= 0:
            raise ValueError("readyInMinutes must be > 0")
        return v

    @field_validator("servings")
    def check_servings(cls, v):
        if v is not None and v <= 0:
            raise ValueError("servings must be > 0")
        return v

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
if not GOOGLE_API_KEY:
    _blue("[Gemini][recipes] WARNING: GOOGLE_API_KEY not set — will fall back to stub if called")

# ... keep your existing classes & GOOGLE_API_KEY ...

def _strip_code_fences(s: str) -> str:
    s = s.strip()
    # ```json ... ```
    if s.startswith("```"):
        s = re.sub(r"^```(?:json|JSON)?\s*", "", s, flags=re.IGNORECASE)
        s = re.sub(r"\s*```$", "", s)
    return s.strip()

def _extract_json_array(text: str) -> str:
    """
    Find the first top-level JSON array [ ... ] with bracket matching.
    Returns the substring or raises ValueError.
    """
    i = text.find("[")
    if i == -1:
        raise ValueError("No '[' found")
    depth = 0
    for j in range(i, len(text)):
        c = text[j]
        if c == "[":
            depth += 1
        elif c == "]":
            depth -= 1
            if depth == 0:
                return text[i:j+1]
    raise ValueError("Unbalanced brackets")

def _common_fixes(s: str) -> str:
    """
    Fix a few common LLM JSON hiccups safely:
    - remove BOM
    - remove trailing commas before ] or }
    """
    s = s.replace("\ufeff", "")
    # Trailing commas: ", ]" -> "]", ", }" -> "}"
    s = re.sub(r",\s*([\]\}])", r"\1", s)
    return s

def _coerce_candidates_from_text(raw_text: str) -> list[dict]:
    """
    Try multiple strategies to turn Gemini text into a Python list[dict].
    """
    t = raw_text.strip()

    # If Gemini returned a *quoted* JSON array string, unquote once.
    if (t.startswith('"') and t.endswith('"')) or (t.startswith("'") and t.endswith("'")):
        try:
            t = json.loads(t)  # becomes the inner JSON string
        except Exception:
            pass

    t = _strip_code_fences(t)

    # Now extract the array portion (handles surrounding prose)
    arr = _extract_json_array(t)
    arr = _common_fixes(arr)
    return json.loads(arr)

def _minimal_validate_list(lst: list) -> bool:
    if not isinstance(lst, list) or len(lst) == 0:
        return False
    for item in lst:
        if not isinstance(item, dict):
            return False
        if "title" not in item or "readyInMinutes" not in item:
            return False
        if "required_ingredients" not in item:
            return False
    return True

async def generate_recipes(
    *,
    query: str,
    max_time: int,
    spice_level: int,
    allergies: List[str],
    cuisines: List[str],
    diets: List[str],
) -> Dict[str, Any]:
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
                # Prefer schema (works when the model obeys it)
                "response_schema": list[_RecipeCandidateLite],
            },
        )

        # Path A: schema-parsed
        if getattr(resp, "parsed", None):
            parsed: List[_RecipeCandidateLite] = resp.parsed  # type: ignore
            _blue(f"[Gemini][recipes] parsed via schema: {len(parsed)} candidates")
            return {"candidates": [c.model_dump() for c in parsed]}

        # Path B: fallback parse from text
        raw = getattr(resp, "text", "") or ""
        _blue("[Gemini][recipes][RAW text] ↓")
        _blue(raw[:1000] + ("…" if len(raw) > 1000 else ""))

        try:
            lst = _coerce_candidates_from_text(raw)
            if not _minimal_validate_list(lst):
                raise ValueError("Minimal validation failed")
            _blue(f"[Gemini][recipes] parsed via fallback: {len(lst)} candidates")
            return {"candidates": lst}
        except Exception as pe:
            _blue(f"[Gemini][recipes] fallback parse failed: {pe}")
            raise

    except Exception as e:
        _blue(f"[Gemini][recipes] ERROR {e} — returning stub")
        # … keep your existing stub exactly …
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
                    "cuisines": [],
                    "diets": [],
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
                    "cuisines": [],
                    "diets": [],
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
                    "cuisines": [],
                    "diets": [],
                },
            ]
        }
