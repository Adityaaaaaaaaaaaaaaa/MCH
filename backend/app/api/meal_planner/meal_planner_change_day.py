# app/api/meal_planner_change_day.py

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List, Tuple
from datetime import datetime, timezone
import os

from app.core.firestore_client import get_firestore_client
from app.providers.spoonacular.day_plan_generate import generate_day_plan
from app.providers.spoonacular.spoonacular_recipe_details import SpoonacularRecipeDetailsProvider
from app.models.recipe import Recipe
from app.models.meal_plan import MealPlanDay

router = APIRouter(tags=["Meal Planner - Change Day"])

db = get_firestore_client()

BLUE = "\x1B[34m"
RESET = "\x1B[0m"

_DAY_NAMES = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

# ---------- Helpers ----------

def _parse_items_day(items: List[Dict[str, Any]]) -> Tuple[Dict[int, Dict[str, Any]], List[int]]:
    """
    Parse the 'items' shape (like the week endpoint). Returns
    (slot_map, ids). slot_map keys are slot 1/2/3.
    """
    slot_map: Dict[int, Dict[str, Any]] = {}
    ids: List[int] = []
    seen = set()

    for it in items:
        slot = int(it.get("slot", 0))
        if slot not in (1, 2, 3):
            continue
        val_raw = it.get("value")
        # 'value' can be JSON string with { id, title, ... }
        v = None
        if isinstance(val_raw, str):
            try:
                import json
                v = json.loads(val_raw)
            except Exception:
                v = None
        elif isinstance(val_raw, dict):
            v = val_raw

        if not isinstance(v, dict):
            continue

        rid = v.get("id")
        if isinstance(rid, int):
            slot_map[slot] = v
            if rid not in seen:
                seen.add(rid)
                ids.append(rid)

    return slot_map, ids


def _parse_meals_day(meals: List[Dict[str, Any]]) -> Tuple[Dict[int, Dict[str, Any]], List[int]]:
    """
    Parse the 'meals' shape (timeFrame=day).
    Index 0 -> slot 1 (breakfast), 1 -> slot 2 (lunch), 2 -> slot 3 (dinner).
    """
    slot_map: Dict[int, Dict[str, Any]] = {}
    ids: List[int] = []
    seen = set()

    for idx, m in enumerate(meals[:3]):  # only care about first three
        rid = m.get("id")
        if not isinstance(rid, int):
            continue
        slot = idx + 1  # 1..3
        slot_map[slot] = m
        if rid not in seen:
            seen.add(rid)
            ids.append(rid)

    return slot_map, ids


def _slot_to_key(slot: int) -> str:
    return {1: "breakfast", 2: "lunch", 3: "dinner"}.get(slot, "unknown")


# ---------- Request model ----------

class ChangeDayRequest(BaseModel):
    userId: str
    planId: str                               # ISO Monday, e.g. "2025-08-11"
    dayIndex: int = Field(ge=1, le=7)         # 1..7 (Mon..Sun)
    diet: Optional[str] = None
    exclude: Optional[str] = None
    targetCalories: Optional[int] = None


# ---------- Endpoint ----------

@router.post("/changeDay")
def change_day(req: ChangeDayRequest):
    """
    Generate a new single-day plan from Spoonacular and replace the given day
    (breakfast/lunch/dinner) in Firestore under:
      users/{userId}/mealPlans/{planId}/days/{monday..sunday}
    """
    if not os.getenv("RAPIDAPI_KEY"):
        raise HTTPException(status_code=500, detail="Server not configured with RAPIDAPI_KEY")

    print(f"{BLUE}[DEBUG] /mealPlanner/day/changeDay -> userId={req.userId}, planId={req.planId}, "
          f"dayIndex={req.dayIndex} ({_DAY_NAMES[req.dayIndex-1].title()}), "
          f"diet={req.diet}, exclude={req.exclude}, targetCalories={req.targetCalories}{RESET}")

    # 1) Call upstream for a single day
    upstream = generate_day_plan(
        diet=(req.diet or "").strip() or None,
        exclude_csv=(req.exclude or "").strip() or None,
        target_calories=req.targetCalories,
    )
    if not upstream.get("ok"):
        status = int(upstream.get("status", 502))
        error = upstream.get("error", "Upstream error")
        body = upstream.get("body", "")
        raise HTTPException(status_code=status, detail={"error": error, "upstream": body[:800]})

    data = upstream.get("data") or {}
    items = data.get("items") or []
    meals = data.get("meals") or []

    print(f"{BLUE}[DEBUG] changeDay: day.items={len(items)}, day.meals={len(meals)}{RESET}")

    # 2) Normalize to slot_map (1..3) + collect recipe IDs
    slot_map: Dict[int, Dict[str, Any]] = {}
    ids: List[int] = []

    if items:
        slot_map, ids = _parse_items_day(items)
    elif meals:
        slot_map, ids = _parse_meals_day(meals)

    print(f"{BLUE}[DEBUG] changeDay: slots={list(slot_map.keys())}, ids={ids}{RESET}")

    if not ids:
        raise HTTPException(status_code=502, detail="No recipe IDs found for generated day")

    # 3) Bulk fetch full details (like week endpoint)
    provider = SpoonacularRecipeDetailsProvider()
    recipes_full: List[Dict[str, Any]] = []
    try:
        res = provider.get_bulk_recipe_details(ids, include_nutrition=True)
        if isinstance(res, list):
            recipes_full.extend(res)
    except Exception as ex:
        print(f"{BLUE}[DEBUG] Bulk fetch error for ids={ids}: {ex}{RESET}")

    recipes_by_id: Dict[str, Recipe] = {}
    for r in recipes_full:
        rid = r.get("id")
        if rid is not None:
            try:
                recipes_by_id[str(rid)] = Recipe(**r)
            except Exception as ex:
                print(f"{BLUE}[DEBUG] Failed to parse recipe id={rid}: {ex}{RESET}")

    # 4) Build the replacement day payload
    breakfast = lunch = dinner = None
    for slot, val in slot_map.items():
        rid = val.get("id")
        rec = recipes_by_id.get(str(rid))
        key = _slot_to_key(slot)
        if key == "breakfast":
            breakfast = rec
        elif key == "lunch":
            lunch = rec
        elif key == "dinner":
            dinner = rec

    if not any([breakfast, lunch, dinner]):
        raise HTTPException(status_code=502, detail="Failed to fetch full recipe details for day")

    payload = MealPlanDay(
        dayIndex=req.dayIndex,
        dayName=_DAY_NAMES[req.dayIndex - 1].title(),
        breakfast=breakfast,
        lunch=lunch,
        dinner=dinner,
    )
    out = payload.model_dump() if hasattr(payload, "model_dump") else payload.dict()

    # 5) Save to Firestore
    if db is None:
        raise HTTPException(status_code=500, detail="Firestore not configured on server")

    doc_id = _DAY_NAMES[req.dayIndex - 1]  # "monday".."sunday"
    plan_ref = (
        db.collection("users").document(req.userId)
          .collection("mealPlans").document(req.planId)
          .collection("days").document(doc_id)
    )
    out["updatedAt"] = datetime.now(timezone.utc).isoformat()
    plan_ref.set(out, merge=True)

    print(f"{BLUE}[DEBUG] changeDay: saved users/{req.userId}/mealPlans/{req.planId}/days/{doc_id}{RESET}")

    return {
        "ok": True,
        "path": f"users/{req.userId}/mealPlans/{req.planId}/days/{doc_id}",
        "ids": ids,
        "slots": list(slot_map.keys()),
    }
