# app/api/cravings/ai_recipe_generator.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import json
import anyio
from app.utils.shopping.shopping_normalize import normalize_name
from app.utils.shopping.firestore_inventory import fetch_inventory_once
from app.providers.gemini.gemini_recipe_generator import generate_recipes
from app.providers.gemini.gemini_image_generator import generate_image_for_title
from app.utils.cravings.id_utils import make_mru_id
from app.utils.shopping.shopping import attach_shopping_to_candidates

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

# ---------- Request models (mirror Flutter payload) ----------
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
class ShoppingItem(BaseModel):
    name: str
    need: float
    unit: str
    have: float
    tag: str  # "buy" | "missing"

class Candidate(BaseModel):
    id: str
    title: str
    image: Optional[str] = None
    readyInMinutes: Optional[int] = None
    reasons: List[str] = []
    shopping: List[ShoppingItem] = []   # computed per-recipe

class AiRecipeResponse(BaseModel):
    received: bool
    message: str
    items: List[Candidate]

# ---------- Helpers for verbose previews ----------
def _preview_candidates_short(cands: List[Dict[str, Any]]) -> None:
    _blue(f"[AI-RECIPES] Candidates received: {len(cands)}")
    for i, c in enumerate(cands, start=1):
        _blue(f"  [{i}] id={c.get('id')} title={c.get('title')} mins={c.get('readyInMinutes')}")
        rs = c.get("reasons", [])
        if rs:
            _blue("      reasons: " + "; ".join(rs[:3]) + ("" if len(rs) <= 3 else " …"))

def _preview_shopping_lists(cands_with_shopping: List[Dict[str, Any]]) -> None:
    _blue("[AI-RECIPES] Shopping list preview per candidate:")
    for i, c in enumerate(cands_with_shopping, start=1):
        title = c.get("title", f"Candidate #{i}")
        shop = c.get("shopping", [])
        _blue(f"  [{i}] {title} — shopping items: {len(shop)}")
        if not shop:
            _blue("       (no missing items ✅)")
            continue
        for s in shop:
            name = s.get("name")
            need = s.get("need")
            have = s.get("have")
            unit = s.get("unit")
            tag  = s.get("tag")
            _blue(f"       - {name}: need {need} {unit} (have {have}) [{tag}]")

# ---------- Endpoint ----------
@router.post("/aiRecipe", response_model=AiRecipeResponse)
async def ai_recipe(req: AiRecipeRequest):
    try:
        # ── Step 1: Get the data ─────────────────────────────────────────
        _blue("[AI-RECIPES] Step 1/6: Received bundle")
        _blue(f"  user={req.userId} query='{req.query}' time={req.constraints.maxTimeMinutes}m spice={req.constraints.spice.resolvedLevel}")
        _blue(f"  prefs: allergies={req.preferences.allergies} cuisines={req.preferences.cuisines} diets={req.preferences.diets}")
        _blue(f"  inventory items (UI payload)={len(req.inventory)}")
        
        live_inventory = await anyio.to_thread.run_sync(fetch_inventory_once, req.userId)
        _blue(f"[AI-RECIPES] Using Firestore inventory snapshot: {len(live_inventory)} items")
        
        allowed = sorted({ normalize_name(i["name"]) for i in live_inventory })
        _blue(f"[AI-RECIPES] allowed_canonicals (from inventory): {len(allowed)}")
        if allowed:
            _blue("  e.g.: " + ", ".join(allowed[:15]) + (" …" if len(allowed) > 15 else ""))
        
        # ── Step 2: Call Gemini to generate 3 recipes ───────────────────
        _blue("[AI-RECIPES] Step 2/6: Calling Gemini recipe generator…")
        gen = await generate_recipes(
            query=req.query,
            max_time=req.constraints.maxTimeMinutes,
            spice_level=req.constraints.spice.resolvedLevel,
            allergies=req.preferences.allergies,
            cuisines=req.preferences.cuisines,
            diets=req.preferences.diets,
            allowed_canonicals=allowed,
        )
        _blue("[AI-RECIPES] Gemini raw candidates (truncated):")
        _blue(_pp(gen))

        cands: List[Dict[str, Any]] = gen.get("candidates", [])
        _preview_candidates_short(cands)

        # ── Step 3: Generate images (sequential; 1 per candidate) ───────
        _blue("[AI-RECIPES] Step 3/6: Generating images per candidate…")
        images: List[Optional[str]] = []
        for i, cand in enumerate(cands, start=1):
            title = cand.get("title", f"Candidate #{i}")
            try:
                img_data_url = await generate_image_for_title(title=title)
                got_img = bool(img_data_url) and img_data_url.startswith("data:image/")
                size_hint = len(img_data_url) if img_data_url else 0
                _blue(f"  [img] {title!r}: {'OK' if got_img else 'TEXT-ONLY'} ({size_hint} chars)")
                images.append(img_data_url if got_img else None)
            except Exception as img_err:
                _blue(f"  [img] {title!r}: ERROR {img_err}")
                images.append(None)
                
        # ── Step 4: Compute shopping list per candidate ─────────────────
        _blue("[AI-RECIPES] Step 4/6: Computing shopping lists…")
        cands_with_shopping = attach_shopping_to_candidates(
            candidates=cands,
            inventory=live_inventory, # use live inventory from Firestore
        )
        _preview_shopping_lists(cands_with_shopping)

        # ── Step 5: Build final items (merge images + shopping) ─────────
        _blue("[AI-RECIPES] Step 5/6: Building response items…")
        items: List[Candidate] = []
        for idx, cand in enumerate(cands_with_shopping):
            title = cand.get("title", f"Candidate #{idx+1}")
            items.append(Candidate(
                id=cand.get("id", f"cand_{idx+1}"),
                title=title,
                image=images[idx] if idx < len(images) else None,
                readyInMinutes=cand.get("readyInMinutes"),
                reasons=cand.get("reasons", []),
                shopping=[ShoppingItem(**s) for s in cand.get("shopping", [])],
            ))

        # ── Step 6: Overwrite IDs with Mauritius-time-based IDs ─────────
        _blue("[AI-RECIPES] Step 6/6: Overwriting candidate IDs …")
        base_id = make_mru_id()  # e.g., '230825_2012'
        seen: set[str] = set()
        suffix = ["A", "B", "C", "D", "E", "F"]

        for idx, it in enumerate(items):
            new_id = f"{base_id}_{suffix[idx]}" if idx < len(suffix) else f"{base_id}_{idx+1}"
            while new_id in seen:
                new_id = f"{base_id}_{idx+1}"
            _blue(f"  id {it.id!r} -> {new_id!r}")
            seen.add(new_id)
            it.id = new_id

        _blue("[AI-RECIPES] Responding to client with items:")
        _blue(_pp([
            {
                "id": it.id,
                "title": it.title,
                "hasImage": bool(it.image),
                "shoppingCount": len(it.shopping),
            } for it in items
        ]))

        return AiRecipeResponse(
            received=True,
            message="OK",
            items=items
        )

    except Exception as e:
        _blue(f"[AI-RECIPES] ERROR: {e}")
        raise HTTPException(status_code=500, detail=str(e))
