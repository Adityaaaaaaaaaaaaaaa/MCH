# app/providers/gemini/gemini_recipe_generator.py
import os, json
from typing import List, Dict, Any, Optional, Literal
from typing import List as _TList
from pydantic import BaseModel, Field, ValidationError, field_validator
from google import genai
from app.utils.cravings.ai_prompt import build_gemini_recipe_prompt
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

# NEW: bubble 503 up to the router so the UI can show a proper error
class ProviderUnavailable(Exception):
    def __init__(self, status_code: int = 503, message: str = "Service unavailable"):
        super().__init__(message)
        self.status_code = status_code


# --- Lite, local validation models (no JSON schema sent to Gemini) ---
class _IngredientReq(BaseModel):
    name: str
    quantity: float = 0.0
    unit: Literal["g", "ml", "count"] = "count"
    canonical: Optional[str] = None      # e.g., "apple", "bell pepper", "yogurt"
    pantryLikely: Optional[bool] = None  # model’s hint: common pantry item?

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
    Turn Gemini text into a list[dict] of recipes.
    Handles:
      - a pure JSON array:      [ {...}, {...} ]
      - a wrapper JSON object:  {"candidates":[ {...}, {...} ], ... }
      - code fences / trailing commas / BOM
    """
    t = _strip_code_fences(raw_text.strip())
    t = _common_fixes(t)

    # 1) Try direct parse first (often succeeds even with prose-free JSON)
    try:
        obj = json.loads(t)
        if isinstance(obj, list):
            return obj
        if isinstance(obj, dict) and "candidates" in obj and isinstance(obj["candidates"], list):
            return obj["candidates"]
    except Exception:
        pass

    # 2) Try extracting the largest top-level object {...} then read "candidates"
    try:
        obj_str = _extract_top_level_object(t)
        obj = json.loads(_common_fixes(obj_str))
        if isinstance(obj, dict) and "candidates" in obj and isinstance(obj["candidates"], list):
            return obj["candidates"]
    except Exception:
        pass

    # 3) Fall back to extracting the largest top-level array [...]
    try:
        arr_str = _extract_json_array(t)
        return json.loads(_common_fixes(arr_str))
    except Exception as e:
        raise ValueError(f"Could not coerce JSON candidates: {e}")

def _extract_top_level_object(text: str) -> str:
    """
    Find the first top-level JSON object {...} with brace matching (ignores braces in strings).
    Returns substring or raises ValueError.
    """
    start = text.find("{")
    if start == -1:
        raise ValueError("No '{' found")
    depth = 0
    in_str = False
    escape = False
    for i in range(start, len(text)):
        ch = text[i]
        if in_str:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_str = False
            continue
        else:
            if ch == '"':
                in_str = True
            elif ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    return text[start:i+1]
    raise ValueError("Unbalanced braces")

def _extract_json_array(text: str) -> str:
    """
    Find the first top-level JSON array [ ... ] with bracket matching (ignores brackets in strings).
    """
    start = text.find("[")
    if start == -1:
        raise ValueError("No '[' found")
    depth = 0
    in_str = False
    escape = False
    for i in range(start, len(text)):
        ch = text[i]
        if in_str:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_str = False
            continue
        else:
            if ch == '"':
                in_str = True
            elif ch == "[":
                depth += 1
            elif ch == "]":
                depth -= 1
                if depth == 0:
                    return text[start:i+1]
    raise ValueError("Unbalanced brackets")

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

def _repair_to_json_array(raw_text: str) -> Optional[list[dict]]:
    """
    Ask the model to reformat whatever it produced into a STRICT JSON array of candidates.
    Returns list[dict] or None if it still can't be parsed.
    """
    try:
        client = genai.Client(api_key=GOOGLE_API_KEY)
        sys_prompt = (
            "You are a JSON repair tool. "
            "Given arbitrary text that contains recipes, output ONLY a strict JSON array of recipe objects. "
            "No markdown, no explanation, no comments. Keys must match:\n"
            "{id?, title, readyInMinutes, reasons[], required_ingredients[], optional_ingredients[], "
            "instructions[], cuisines[], diets[], vegetarian?, vegan?, glutenFree?, dairyFree?, summary?, nutrition?}\n"
            "If any field is missing, omit it; never invent extra keys. Output MUST be a valid JSON array."
        )
        resp = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=[{"role":"system","parts":[sys_prompt]}, {"role":"user","parts":[raw_text]}],
            config={
                "response_mime_type": "application/json",
                "candidate_count": 1,
                "temperature": 0.0,
                "max_output_tokens": 2048,
            },
        )
        text = getattr(resp, "text", "") or ""
        arr = _coerce_candidates_from_text(text)
        return arr if _minimal_validate_list(arr) else None
    except Exception:
        return None

def _gemini_call(prompt, *, temperature: float = 0.6):
    client = genai.Client(api_key=GOOGLE_API_KEY)

    # Base config always asks for JSON back
    base_config = {
        "response_mime_type": "application/json",
        "temperature": temperature,
        "candidate_count": 1,
    }

    # 1) Try with a proper Schema (NOT pydantic)
    try:
        from google.genai.types import Schema

        # Only try schema mode if Schema.Type seems available in this SDK version
        if not hasattr(Schema, "Type") or not hasattr(Schema.Type, "STRING"):
            raise RuntimeError("Schema.Type not available in this SDK")

        STR = Schema.Type.STRING
        NUM = Schema.Type.NUMBER
        BOOL = Schema.Type.BOOLEAN
        ARR = Schema.Type.ARRAY
        OBJ = Schema.Type.OBJECT

        ingredient_schema = Schema(
            type=OBJ,
            properties={
                "name": Schema(type=STR),
                "quantity": Schema(type=NUM),
                "unit": Schema(type=STR),
                "canonical": Schema(type=STR, nullable=True),
                "pantryLikely": Schema(type=BOOL, nullable=True),
            },
            required=["name"],
        )

        nutrition_schema = Schema(
            type=OBJ,
            properties={
                "calories": Schema(type=NUM, nullable=True),
                "protein_g": Schema(type=NUM, nullable=True),
                "fat_g": Schema(type=NUM, nullable=True),
                "carbs_g": Schema(type=NUM, nullable=True),
            },
        )

        recipe_schema = Schema(
            type=OBJ,
            properties={
                "id": Schema(type=STR, nullable=True),
                "title": Schema(type=STR),
                "readyInMinutes": Schema(type=NUM),
                "servings": Schema(type=NUM, nullable=True),
                "cuisines": Schema(type=ARR, items=Schema(type=STR)),
                "diets": Schema(type=ARR, items=Schema(type=STR)),
                "vegetarian": Schema(type=BOOL, nullable=True),
                "vegan": Schema(type=BOOL, nullable=True),
                "glutenFree": Schema(type=BOOL, nullable=True),
                "dairyFree": Schema(type=BOOL, nullable=True),
                "reasons": Schema(type=ARR, items=Schema(type=STR)),
                "required_ingredients": Schema(type=ARR, items=ingredient_schema),
                "optional_ingredients": Schema(type=ARR, items=ingredient_schema),
                "instructions": Schema(type=ARR, items=Schema(type=STR)),
                "summary": Schema(type=STR, nullable=True),
                "nutrition": nutrition_schema,
            },
            required=["title", "readyInMinutes", "required_ingredients", "instructions"],
        )

        cfg = dict(base_config)
        cfg["response_schema"] = Schema(type=ARR, items=recipe_schema)

        return client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config=cfg,
        )
        
    except Exception as e:
        _blue(f"[Gemini][recipes] WARN schema mode unavailable ({e}); retrying without schema")
        # 2) Fall back to "no schema" but still JSON
        return client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config=base_config,
        )

async def generate_recipes(
    *,
    query: str,
    max_time: int,
    spice_level: int,
    allergies: List[str],
    cuisines: List[str],
    diets: List[str],
    allowed_canonicals: Optional[list[str]] = None
) -> Dict[str, Any]:
    prompt = build_gemini_recipe_prompt(
        query=query,
        max_time=max_time,
        spice_level=spice_level,
        allergies=allergies,
        cuisines=cuisines,
        diets=diets,
        allowed_canonicals=allowed_canonicals or [],
    )

    try:
        _blue("[Gemini][recipes] calling gemini-2.5-flash …")
        resp = _gemini_call(prompt, temperature=0.6)

        if getattr(resp, "parsed", None):
            parsed: List[_RecipeCandidateLite] = resp.parsed  # type: ignore
            _blue(f"[Gemini][recipes] parsed via schema: {len(parsed)} candidates")
            return {"candidates": [c.model_dump() for c in parsed]}

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
            # --- one controlled retry, schema-only, lower temp ---
            _blue("[Gemini][recipes] retrying with stricter generation …")
            resp2 = _gemini_call(prompt, temperature=0.3)
            if getattr(resp2, "parsed", None):
                parsed2: List[_RecipeCandidateLite] = resp2.parsed  # type: ignore
                _blue(f"[Gemini][recipes] parsed via schema (retry): {len(parsed2)} candidates")
                return {"candidates": [c.model_dump() for c in parsed2]}
            # last-ditch: try text on retry too
            raw2 = getattr(resp2, "text", "") or ""
            try:
                lst2 = _coerce_candidates_from_text(raw2)
                if not _minimal_validate_list(lst2):
                    raise ValueError("Minimal validation failed (retry)")
                _blue(f"[Gemini][recipes] parsed via fallback (retry): {len(lst2)} candidates")
                return {"candidates": lst2}
            except Exception as pe2:
                _blue(f"[Gemini][recipes] retry fallback parse failed: {pe2}")
                # --- JSON repair pass before giving up ---
                try_source = raw2 or raw
                _blue("[Gemini][recipes] attempting JSON repair pass …")
                repaired = _repair_to_json_array(try_source)
                if repaired and _minimal_validate_list(repaired):
                    _blue(f"[Gemini][recipes] repaired JSON: {len(repaired)} candidates")
                    return {"candidates": repaired}
                # if repair didn't help, bubble up to outer except (stub)
                raise

    except Exception as e:
        msg = str(e)
        # If Gemini is overloaded, don't return stubs — signal 503 upstream
        if ("503" in msg) or ("UNAVAILABLE" in msg) or ("overloaded" in msg):
            _blue(f"[Gemini][recipes] UNAVAILABLE/503: {msg}")
            raise ProviderUnavailable(503, "The model is overloaded. Please try again later.")
        # Otherwise keep your current behavior

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
