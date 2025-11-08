from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List, Literal, Optional, Dict, Any
from app.core.firestore_client import get_firestore_client
from app.providers.gemini.gemini_recipe_calculation import compute_deduction
import hashlib, time

router = APIRouter()

UnitCanon = Literal["g", "ml", "count"]        # inventory units (canonical)
UnitAny   = Literal[
    "g","kg","ml","l","cup","tbsp","tsp","count","pcs","piece","unit","oz","lb"
]                                             # recipe may use these

class RecipeIngredient(BaseModel):
    name: str = Field(..., description="Raw text name e.g., 'chopped onions'")
    amount: float = Field(..., ge=0)
    unit: str = Field(..., description="Original unit from recipe (any string)")

class InventoryItem(BaseModel):
    key: str                  # Firestore docId (item name in your schema)
    name: str                 # Display name (often same as key)
    unit: UnitCanon           # g | ml | count
    quantity: float           # current quantity

class DeductionDecision(BaseModel):
    inventory_key: str
    inventory_name: str
    unit: UnitCanon
    starting_quantity: float
    deducted: float
    new_quantity: float
    recipe_name: str

class DeductionResponse(BaseModel):
    decision_id: str
    patch: List[DeductionDecision]
    unmatched: List[str]
    applied: bool

class DeductionRequest(BaseModel):
    uid: str
    ingredients: List[RecipeIngredient]
    apply: bool = True

BLUE = "\x1B[34m"; END = "\x1B[0m"
def blog(msg: str): print(f"{BLUE}[DEBUG][deduct-inventory] {msg}{END}")

@router.post("/InvDeduct", response_model=DeductionResponse)
def deduct_inventory(req: DeductionRequest) -> DeductionResponse:
    blog(f"Start for uid={req.uid}, items={len(req.ingredients)}, apply={req.apply}")

    db = get_firestore_client()
    if db is None:
        raise HTTPException(status_code=500, detail="Firestore client not available")

    # 1) Load inventory (canonical units: g/ml/count)
    inv_ref = db.collection("users").document(req.uid).collection("inventory")
    inv_docs = list(inv_ref.stream())
    inventory: List[InventoryItem] = []
    for d in inv_docs:
        data = d.to_dict() or {}
        inventory.append(InventoryItem(
            key=d.id,
            name=data.get("name", d.id),
            unit=data.get("unit", "count"),
            quantity=float(data.get("quantity", 0.0))
        ))
    blog(f"Inventory loaded: {len(inventory)} items")

    # 2) Ask Gemini to compute patch (name-only matching + unit conversion)
    decision_id = hashlib.sha256(f"{time.time()}-{req.uid}-{len(inventory)}".encode()).hexdigest()[:16]
    patch, unmatched = compute_deduction(
        decision_id=decision_id,
        recipe=req.ingredients,
        inventory=inventory
    )
    blog(f"Gemini patch: {len(patch)} decisions; unmatched={len(unmatched)}")

    # 🔧 Coerce provider models → API response models (minimal fix)
    api_patch: List[DeductionDecision] = []
    for p in patch:
        try:
            data = p.model_dump()              # provider Pydantic model
        except Exception:
            try:
                data = dict(p)                 # already a dict
            except Exception:
                data = getattr(p, "__dict__", {})
        api_patch.append(DeductionDecision(**data))
    blog(f"API patch coerced: {len(api_patch)} items")

    # 3) Apply to Firestore (optional)
    applied = False
    if req.apply:
        batch = db.batch()
        for dec in api_patch:
            doc = inv_ref.document(dec.inventory_key)
            if dec.new_quantity <= 0:
                batch.delete(doc)
            else:
                batch.update(doc, {"quantity": dec.new_quantity})
        batch.commit()
        applied = True
        blog("Firestore commit complete")

    # 4) Return
    return DeductionResponse(
        decision_id=decision_id,
        patch=api_patch,          # use API-model list
        unmatched=unmatched,
        applied=applied
    )
