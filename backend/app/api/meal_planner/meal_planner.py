from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
import os
from datetime import datetime, timezone, timedelta
from app.providers.spoonacular.week_plan_generate import generate_week_plan
from app.providers.spoonacular.spoonacular_recipe_details import SpoonacularRecipeDetailsProvider
from app.models.meal_plan import (
    build_week_lite_from_items,  # parses Spoonacular "items" into 7×3 lite meals + ids
    DayPlanLite,                 # lite day (ids only)
    MealPlanDay,                 # final day with full Recipe
    WeeklyPlanResponse,          # final response model
)
from app.models.recipe import Recipe
from app.core.firestore_client import get_firestore_client

router = APIRouter(tags=["Meal Planner"])

db = get_firestore_client()

BLUE = "\x1B[34m"
RESET = "\x1B[0m"

_DAY_NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

def _monday_of_week(dt_utc: datetime) -> datetime:
    """
    Compute the Monday (00:00 UTC) of the ISO week containing dt_utc.
    We use this as a stable planId so a week is uniquely identified.
    """
    d = dt_utc.date()
    monday = d - timedelta(days=d.weekday())
    return datetime(monday.year, monday.month, monday.day, tzinfo=timezone.utc)


def _default_plan_id(now_utc: datetime) -> str:
    """
    Plan ID format: YYYY-MM-DD (ISO Monday of that week).
    Examples: 2025-08-11, 2025-01-06
    """
    return _monday_of_week(now_utc).strftime("%Y-%m-%d")


def _chunk(seq: List[int], size: int) -> List[List[int]]:
    """Chunk a list into sublists of length <= size (stable order)."""
    return [seq[i:i + size] for i in range(0, len(seq), size)]


#  Request model 

class WeekPlannerRequest(BaseModel):
    """
    Request contract for generating a weekly meal plan for a given user.
    - userId: required Firebase UID.
    - timeFrame: fixed to 'week' for this endpoint (future-proof if you add 'day').
    - diet/exclude/targetCalories: optional filters forwarded to Spoonacular.
    - planId: optional override (if you want to regenerate a specific week explicitly).
    """
    userId: str
    timeFrame: str = Field(default="week", pattern="^(week)$")
    diet: Optional[str] = None
    exclude: Optional[str] = None            # allergens/ingredients
    targetCalories: Optional[int] = None
    planId: Optional[str] = None             # if absent, we compute ISO-Monday ID


#  Endpoint 

@router.post("/weekPlanner")
def week_planner(req: WeekPlannerRequest):
    """
    Generate → Enrich → Persist a 7-day meal plan:
    1) Call Spoonacular to generate a weekly plan (21 meals, 3/day).
    2) Normalize items into 7×(breakfast|lunch|dinner) with Meal IDs.
    3) Bulk fetch full Recipe details (3×7 batches).
    4) Construct final MealPlanDay objects (full Recipe embedded).
    5) Save to Firestore under users/{uid}/mealPlans/{planId}/days/{monday..sunday}.
    6) Return the saved plan (useful for immediate rendering on the client).
    """
    # --- Guard: RapidAPI key must be present ---
    if not os.getenv("RAPIDAPI_KEY"):
        print(f"{BLUE}[DEBUG] RAPIDAPI_KEY not configured on server{RESET}")
        raise HTTPException(status_code=500, detail="Server not configured with RAPIDAPI_KEY")

    # --- Normalise optional inputs (empty → None) ---
    diet = (req.diet or "").strip() or None
    exclude = (req.exclude or "").strip() or None

    print(
        f"{BLUE}[DEBUG] /mealPlanner/weekPlanner payload -> "
        f"userId={req.userId}, timeFrame={req.timeFrame}, diet={diet}, "
        f"exclude={exclude}, targetCalories={req.targetCalories}{RESET}"
    )

    # --- Step 1: Generate raw week from Spoonacular ---
    upstream = generate_week_plan(
        time_frame=req.timeFrame,
        diet=diet,
        exclude=exclude,
        target_calories=req.targetCalories,
    )
    if not upstream.get("ok"):
        status = int(upstream.get("status", 502))
        error = upstream.get("error", "Upstream error")
        body = upstream.get("body", "")
        raise HTTPException(status_code=status, detail={"error": error, "upstream": body[:800]})

    raw = upstream["data"]             # { name, publishAsPublic, items: [...] }
    items = raw.get("items", [])
    source_name = raw.get("name")

    # --- Step 2: Normalize into 7×3 lite structure + collect unique IDs ---
    week_lite, unique_ids = build_week_lite_from_items(items)
    print(f"{BLUE}[DEBUG] Normalized week -> days={len(week_lite)}, ids={len(unique_ids)}{RESET}")

    # --- Step 3: Bulk fetch full Recipe details (3 batches × 7 IDs) ---
    provider = SpoonacularRecipeDetailsProvider()
    recipes_full: List[Dict[str, Any]] = []
    for batch in _chunk(unique_ids, 7):
        try:
            res = provider.get_bulk_recipe_details(batch, include_nutrition=True)
            if isinstance(res, list):
                recipes_full.extend(res)
        except Exception as ex:
            print(f"{BLUE}[DEBUG] Bulk fetch error for batch {batch}: {ex}{RESET}")

    # Map fetched dicts → strongly-typed Recipe model (skip any malformed)
    recipes_by_id: Dict[str, Recipe] = {}
    for r in recipes_full:
        rid = r.get("id")
        if rid is not None:
            try:
                recipes_by_id[str(rid)] = Recipe(**r)
            except Exception as ex:
                print(f"{BLUE}[DEBUG] Failed to parse recipe id={rid}: {ex}{RESET}")

    # --- Step 4: Build final full week with embedded Recipe objects ---
    full_week: List[MealPlanDay] = []
    for d in range(1, 8):
        lite: DayPlanLite = week_lite[d - 1]
        full_week.append(
            MealPlanDay(
                dayIndex=d,
                dayName=_DAY_NAMES[d - 1],
                breakfast=recipes_by_id.get(str(lite.breakfast.id)) if lite.breakfast else None,
                lunch=recipes_by_id.get(str(lite.lunch.id)) if lite.lunch else None,
                dinner=recipes_by_id.get(str(lite.dinner.id)) if lite.dinner else None,
            )
        )

    # --- Step 5: Persist to Firestore (plan doc + 7 day subdocs) ---
    now_utc = datetime.now(timezone.utc)
    plan_id = (req.planId or _default_plan_id(now_utc)).strip()
    meta = {
        "diet": diet,
        "exclude": exclude,
        "targetCalories": req.targetCalories,
        "sourceName": source_name,
        "generatedAt": now_utc.isoformat(),
    }

    if db is not None:
        plan_ref = (
            db.collection("users").document(req.userId)
            .collection("mealPlans").document(plan_id)
        )

        plan_ref.set(
            {
                "planId": plan_id,
                "timeFrame": req.timeFrame,
                "createdAt": now_utc.isoformat(),
                "meta": meta,
                "daysCount": len(full_week),
            },
            merge=True,
        )

        days_ref = plan_ref.collection("days")
        for day in full_week:
            doc_id = day.dayName.lower()  # "monday" .. "sunday"
            payload = day.model_dump() if hasattr(day, "model_dump") else day.dict()
            days_ref.document(doc_id).set(payload, merge=True)

        print(f"{BLUE}[DEBUG] Saved meal plan: users/{req.userId}/mealPlans/{plan_id} (7 day docs){RESET}")
    else:
        print(f"{BLUE}[DEBUG] Firestore not configured (no ADC / env). Skipping persistence for planId={plan_id}.{RESET}")

    # --- Step 6: Return the saved plan (handy for immediate UI render) ---
    resp = WeeklyPlanResponse(
        timeFrame=req.timeFrame,
        meta=meta,
        week=full_week,
    )
    return {
        "planId": plan_id,
        "path": f"users/{req.userId}/mealPlans/{plan_id}",
        "data": resp.model_dump() if hasattr(resp, "model_dump") else resp.dict(),
    }
