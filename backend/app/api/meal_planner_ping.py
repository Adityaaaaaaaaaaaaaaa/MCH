# app/api/meal_planner_ping.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from datetime import datetime, timezone, timedelta
from typing import Optional
from app.core.firestore_client import get_firestore_client
from app.providers.week_plan_generate import generate_week_plan
from app.providers.spoonacular_recipe_details import SpoonacularRecipeDetailsProvider
from app.models.meal_plan import (
    build_week_lite_from_items, DayPlanLite, MealPlanDay
)
from app.models.recipe import Recipe

router = APIRouter(tags=["Meal Planner - Ping"])

db = get_firestore_client()

class PingBody(BaseModel):
    userId: str
    # Optional: override when testing
    nowIso: Optional[str] = None

def _monday_of_week(dt_utc: datetime) -> datetime:
    d = dt_utc.date()
    monday = d - timedelta(days=d.weekday())
    return datetime(monday.year, monday.month, monday.day, tzinfo=timezone.utc)

@router.post("/ping")
def mealplanner_ping(body: PingBody):
    """
    Idempotent: If it's a *new* Monday and there is no plan for that week,
    auto-generate and save it (same flow you use for weekPlanner).
    Otherwise do nothing. Always returns {ok: True, planId?: str}.
    """
    now_utc = (
        datetime.fromisoformat(body.nowIso).astimezone(timezone.utc)
        if body.nowIso else datetime.now(timezone.utc)
    )
    plan_id = _monday_of_week(now_utc).strftime("%Y-%m-%d")

    if db is None:
        # Not fatal; just say “ok” so mobile heartbeat doesn’t fail
        return {"ok": True, "skipped": "firestore_not_configured"}

    user_ref = db.collection("users").document(body.userId)
    plan_ref = user_ref.collection("mealPlans").document(plan_id)

    # If the plan doc already exists, nothing to do.
    if plan_ref.get().exists:
        return {"ok": True, "alreadyExists": True, "planId": plan_id}

    # Otherwise generate a fresh week (your normal pipeline)
    upstream = generate_week_plan(time_frame="week")
    if not upstream.get("ok"):
        raise HTTPException(status_code=int(upstream.get("status", 502)), detail=upstream)

    items = upstream["data"].get("items", [])
    week_lite, unique_ids = build_week_lite_from_items(items)

    provider = SpoonacularRecipeDetailsProvider()
    # Fetch full recipe details in batches of 7 (same as your weekly endpoint)
    recipes_full = []
    for i in range(0, len(unique_ids), 7):
        batch = unique_ids[i:i+7]
        recipes_full.extend(provider.get_bulk_recipe_details(batch, include_nutrition=True) or [])

    recipes_by_id = {}
    for r in recipes_full:
        rid = r.get("id")
        if rid is not None:
            try:
                recipes_by_id[str(rid)] = Recipe(**r)
            except Exception:
                pass

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

    # Persist plan + 7 day docs
    plan_ref.set({"planId": plan_id, "timeFrame": "week", "createdAt": now_utc.isoformat()}, merge=True)
    days_ref = plan_ref.collection("days")
    for day in full_week:
        doc_id = day.dayName.lower()
        days_ref.document(doc_id).set(day.model_dump() if hasattr(day, "model_dump") else day.dict(), merge=True)

    return {"ok": True, "created": True, "planId": plan_id}
