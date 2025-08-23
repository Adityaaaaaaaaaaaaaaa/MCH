# app/api/ai_recipe_generator.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import json
import math 
from app.providers.gemini_recipe_generator import generate_recipes
from app.providers.gemini_image_generator import generate_image_for_title
from app.utils.id_utils import make_mru_id
from datetime import datetime

router = APIRouter()

BLUE = "\x1B[34m"; RESET = "\x1B[0m"
def _blue(msg: str) -> None:
    print(f"{BLUE}{msg}{RESET}")

def _pp(obj: Any, max_len: int = 1500) -> str:
    try:
        s = json.dumps(obj, indent=2, ensure_ascii=False)
        return s if len(s) <= max_len else s[:max_len] + " … [truncated]"
    except Exception:
        return str(obj)


# ---------- Models (mirror Flutter payload) ----------
class InventoryItem(BaseModel):
    name: str
    quantity: float = 0.0
    unit: str = "count"

class SpiceSpec(BaseModel):
    random: bool
    requestedLevel: Optional[int] = Field(None, ge=0, le=4)
    resolvedLevel: int = Field(..., ge=0, le=4)

class Constraints(BaseModel):
    maxTimeMinutes: int = Field(..., gt=0)
    spice: SpiceSpec

class Preferences(BaseModel):
    allergies: List[str] = []
    cuisines: List[str] = []
    diets: List[str] = []

class AiRecipeRequest(BaseModel):
    userId: str
    query: str = ""
    constraints: Constraints
    preferences: Preferences
    inventory: List[InventoryItem] = []

# ---------- Response models (UI-friendly) ----------
class Candidate(BaseModel):
    id: str
    title: str
    image: Optional[str] = None
    readyInMinutes: Optional[int] = None
    reasons: List[str] = []

class AiRecipeResponse(BaseModel):
    received: bool
    message: str
    items: List[Candidate]

# ---------- Endpoint ----------
@router.post("/aiRecipe", response_model=AiRecipeResponse)
async def ai_recipe(req: AiRecipeRequest):
    try:
        _blue("[AI-RECIPES] Step 1/3: Received bundle")
        _blue(f"  user={req.userId} query='{req.query}' time={req.constraints.maxTimeMinutes}m spice={req.constraints.spice.resolvedLevel}")
        _blue(f"  prefs: allergies={req.preferences.allergies} cuisines={req.preferences.cuisines} diets={req.preferences.diets}")
        _blue(f"  inventory items={len(req.inventory)}")

        # Step 2: Gemini recipe candidates
        _blue("[AI-RECIPES] Step 2/3: Calling Gemini recipe generator…")
        gen = await generate_recipes(
            query=req.query,
            max_time=req.constraints.maxTimeMinutes,
            spice_level=req.constraints.spice.resolvedLevel,
            allergies=req.preferences.allergies,
            cuisines=req.preferences.cuisines,
            diets=req.preferences.diets,
        )

        # Log raw response (truncated to avoid megaspam)
        _blue("[AI-RECIPES] Gemini raw candidates (truncated):")
        _blue(_pp(gen))

        # Summaries per candidate
        cands = gen.get("candidates", [])
        _blue(f"[AI-RECIPES] Candidates received: {len(cands)}")
        for i, c in enumerate(cands, start=1):
            _blue(f"  [{i}] id={c.get('id')} title={c.get('title')} mins={c.get('readyInMinutes')}")
            rs = c.get("reasons", [])
            if rs:
                _blue("      reasons: " + "; ".join(rs[:3]) + ("" if len(rs) <= 3 else " …"))

        # Step 3: Image generation for each title (sequential; 3 calls)
        _blue("[AI-RECIPES] Step 3/3: Generating images per candidate…")
        items: List[Candidate] = []
        for i, cand in enumerate(cands, start=1):
            title = cand.get("title", f"Candidate #{i}")

            try:
                img_data_url = await generate_image_for_title(title=title)
                # Log if image came back (don’t print the whole base64)
                got_img = bool(img_data_url) and img_data_url.startswith("data:image/")
                size_hint = len(img_data_url) if img_data_url else 0
                _blue(f"  [img] {title!r}: {'OK' if got_img else 'TEXT-ONLY'} ({size_hint} chars)")
            except Exception as img_err:
                _blue(f"  [img] {title!r}: ERROR {img_err}")
                img_data_url = None

            items.append(Candidate(
                id=cand.get("id", f"cand_{i}"),
                title=title,
                image=img_data_url,
                readyInMinutes=cand.get("readyInMinutes"),
                reasons=cand.get("reasons", []),
            ))
            
        # Step 4: Overwrite IDs with Mauritius-time-based IDs
        _blue("[AI-RECIPES] Step 4/4: Overwriting candidate IDs …")
        base_id = make_mru_id()  # e.g., '230825_2012'
        seen: set[str] = set()
        suffix = ["A", "B", "C", "D", "E", "F"]  # enough for our 3 items

        for idx, it in enumerate(items):
            new_id = f"{base_id}_{suffix[idx]}" if idx < len(suffix) else f"{base_id}_{idx+1}"
            # just-in-case uniqueness
            while new_id in seen:
                new_id = f"{base_id}_{idx+1}"
            seen.add(new_id)
            _blue(f"  id {it.id!r} -> {new_id!r}")
            it.id = new_id


        _blue("[AI-RECIPES] Responding to client with items:")
        _blue(_pp([{"id": it.id, "title": it.title, "hasImage": bool(it.image)} for it in items]))

        return AiRecipeResponse(
            received=True,
            message="OK",
            items=items
        )

    except Exception as e:
        _blue(f"[AI-RECIPES] ERROR: {e}")
        raise HTTPException(status_code=500, detail=str(e))
