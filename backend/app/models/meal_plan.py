# app/models/meal_plan.py

from __future__ import annotations
from typing import List, Optional, Dict, Any, Tuple
from pydantic import BaseModel, Field
from app.models.recipe import Recipe
import json

BLUE = "\x1B[34m"
RESET = "\x1B[0m"

# ---------- LITE models (used for initial normalization from Spoonacular "items") ----------
class MealLite(BaseModel):
    id: int
    title: str
    imageType: Optional[str] = None

class DayPlanLite(BaseModel):
    dayIndex: int
    breakfast: Optional[MealLite] = None
    lunch: Optional[MealLite] = None
    dinner: Optional[MealLite] = None
    # capture unexpected duplicates for debugging (avoid mutable default!)
    extras: List[MealLite] = Field(default_factory=list)

# ---------- FINAL models (what you’ll return/store when using full Recipe objects) ----------
class MealPlanDay(BaseModel):
    dayIndex: int
    dayName: str
    breakfast: Optional[Recipe] = None
    lunch: Optional[Recipe] = None
    dinner: Optional[Recipe] = None

class WeeklyPlanResponse(BaseModel):
    timeFrame: str
    meta: Dict[str, Any]
    week: List[MealPlanDay]      # final: contains full Recipe objects

# ---------- Helpers ----------
_SLOT_TO_KEY = {1: "breakfast", 2: "lunch", 3: "dinner"}

def _safe_parse_value(val: Any) -> Optional[Dict[str, Any]]:
    """Spoonacular returns `value` as a JSON string; parse defensively."""
    if isinstance(val, dict):
        return val
    if isinstance(val, str):
        try:
            return json.loads(val)
        except Exception as ex:
            print(f"{BLUE}[DEBUG] Failed to parse item.value as JSON: {ex}{RESET}")
            return None
    return None

def build_week_lite_from_items(items: List[Dict[str, Any]]) -> Tuple[List[DayPlanLite], List[int]]:
    """
    Normalize Spoonacular items into 7 DayPlanLite objects and collect unique recipe IDs.
    Ensures slots are not overwritten (duplicates go to `extras` and are logged).
    Returns (week_lite, unique_ids_in_order).
    """
    # Initialize days 1..7
    days_map: Dict[int, DayPlanLite] = {d: DayPlanLite(dayIndex=d) for d in range(1, 8)}
    seen_ids: set[int] = set()
    ordered_ids: List[int] = []

    for it in items:
        try:
            day = int(it.get("day"))
            slot = int(it.get("slot"))
        except Exception:
            print(f"{BLUE}[DEBUG] Skipping item without valid day/slot: {it}{RESET}")
            continue

        if day not in days_map or slot not in _SLOT_TO_KEY:
            print(f"{BLUE}[DEBUG] Skipping item with invalid mapping: day={day}, slot={slot}{RESET}")
            continue

        key = _SLOT_TO_KEY[slot]
        val = _safe_parse_value(it.get("value"))
        if not val:
            continue

        rid = val.get("id")
        title = val.get("title", "")
        image_type = val.get("imageType")

        if not isinstance(rid, int):
            print(f"{BLUE}[DEBUG] Skipping item without numeric id: {val}{RESET}")
            continue

        meal = MealLite(id=rid, title=title, imageType=image_type)
        day_plan = days_map[day]

        # Do NOT overwrite an existing slot; extras logged for diagnostics.
        current = getattr(day_plan, key)
        if current is None:
            setattr(day_plan, key, meal)
        else:
            print(f"{BLUE}[DEBUG] Duplicate slot on day {day} for {key}; keeping first, adding to extras (rid={rid}){RESET}")
            day_plan.extras.append(meal)

        # Track IDs in order, unique
        if rid not in seen_ids:
            seen_ids.add(rid)
            ordered_ids.append(rid)

    # Build ordered list 1..7
    week_lite = [days_map[d] for d in range(1, 8)]
    return week_lite, ordered_ids
