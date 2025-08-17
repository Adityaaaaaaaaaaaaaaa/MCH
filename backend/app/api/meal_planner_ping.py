# app/api/meal_planner_heartbeat.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from datetime import datetime, timezone, timedelta
from typing import Optional

from app.core.firestore_client import get_firestore_client
from app.api.meal_planner import _default_plan_id  # reuse helper for ISO Monday
from app.providers.week_plan_generate import generate_week_plan
from app.providers.spoonacular_recipe_details import SpoonacularRecipeDetailsProvider
from app.models.meal_plan import (
    build_week_lite_from_items, DayPlanLite, MealPlanDay,
)
from app.models.recipe import Recipe

router = APIRouter(tags=["Meal Planner"])
db = get_firestore_client()

BLUE = "\x1B[34m"; RESET = "\x1B[0m"

class HeartbeatReq(BaseModel):
    userId: str
    # optional overrides; usually omitted
    diet: Optional[str] = None
    exclude: Optional[str] = None
    targetCalories: Optional[int] = None

def _plan_doc_exists(user_id: str, plan_id: str) -> bool:
    if db is None:
        return False
    doc = (
        db.collection("users").document(user_id)
        .collection("mealPlans").document(plan_id)
        .get()
    )
    return doc.exists

def _chunk(seq, size):
    return [seq[i:i+size] for i in range(0, len(seq), size)]

@router.post("/ping")
def heartbeat(req: HeartbeatReq):
    """
    Idempotent: if the current week's plan doesn't exist for this user,
    generate it silently and store to Firestore. Otherwise do nothing.
    """
    now_utc = datetime.now(timezone.utc)

    # "New Monday" target = ISO Monday of 'now'
    plan_id = _default_plan_id(now_utc)  # YYYY-MM-DD (Monday)
    print(f"{BLUE}[HB] user={req.userId} check planId={plan_id}{RESET}")

    # If already exists: quick exit (no-op)
    if _plan_doc_exists(req.userId, plan_id):
        return {"ok": True, "created": False, "planId": plan_id}

    # 1) Generate day×7 from Spoonacular (week)
    upstream = generate_week_plan(
        time_frame="week",
        diet=(req.diet or None),
        exclude_csv=(req.exclude or None),
        target_calories=req.targetCalories,
    )
    if not upstream.get("ok"):
        status = int(upstream.get("status", 502))
        raise HTTPException(status_code=status, detail=upstream)

    raw = upstream["data"]
    items = raw.get("items", [])

    # 2) Normalize → collect IDs
    week_lite, unique_ids = build_week_lite_from_items(items)

    # 3) Bulk fetch details
    provider = SpoonacularRecipeDetailsProvider()
    recipes_full = []
    for batch in _chunk(unique_ids, 7):
        try:
            res = provider.get_bulk_recipe_details(batch, include_nutrition=True)
            if isinstance(res, list):
                recipes_full.extend(res)
        except Exception as ex:
            print(f"{BLUE}[HB] bulk fetch error: {ex}{RESET}")

    recipes_by_id = {}
    for r in recipes_full:
        rid = r.get("id")
        if rid is None: 
            continue
        try:
            recipes_by_id[str(rid)] = Recipe(**r)
        except Exception as ex:
            print(f"{BLUE}[HB] parse fail id={rid}: {ex}{RESET}")

    # 4) Build full week (embed Recipe objects)
    day_names = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
    full_week = []
    for d in range(1, 8):
        lite: DayPlanLite = week_lite[d - 1]
        full_week.append(
            MealPlanDay(
                dayIndex=d,
                dayName=day_names[d - 1],
                breakfast=recipes_by_id.get(str(lite.breakfast.id)) if lite.breakfast else None,
                lunch=recipes_by_id.get(str(lite.lunch.id)) if lite.lunch else None,
                dinner=recipes_by_id.get(str(lite.dinner.id)) if lite.dinner else None,
            )
        )

    # 5) Save to Firestore
    if db is not None:
        plan_ref = (
            db.collection("users").document(req.userId)
              .collection("mealPlans").document(plan_id)
        )
        plan_ref.set({
            "planId": plan_id,
            "timeFrame": "week",
            "createdAt": now_utc.isoformat(),
            "daysCount": len(full_week),
            "meta": {
                "diet": (req.diet or None),
                "exclude": (req.exclude or None),
                "targetCalories": req.targetCalories,
                "generatedBy": "heartbeat",
                "generatedAt": now_utc.isoformat(),
            },
        }, merge=True)

        days_ref = plan_ref.collection("days")
        for day in full_week:
            doc_id = day.dayName.lower()
            payload = day.model_dump() if hasattr(day, "model_dump") else day.dict()
            days_ref.document(doc_id).set(payload, merge=True)

        print(f"{BLUE}[HB] created users/{req.userId}/mealPlans/{plan_id}{RESET}")

    return {"ok": True, "created": True, "planId": plan_id}
