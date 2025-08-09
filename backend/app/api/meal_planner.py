# app/api/meal_planner.py

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List, Optional
import os

from app.providers.week_plan_generate import generate_week_plan

router = APIRouter(tags=["Meal Planner"])

BLUE = "\x1B[34m"
RESET = "\x1B[0m"

class WeekPlannerRequest(BaseModel):
    # From Flutter you currently send only timeFrame: "week".
    # We keep these optional so you can add them later without breaking the contract.
    timeFrame: str = Field(default="week", pattern="^(week)$")  # for this endpoint we constrain to "week"
    diet: Optional[str] = None
    exclude: Optional[str] = None   # comma-separated string (Flutter service already joins)
    targetCalories: Optional[int] = None


@router.post("/weekPlanner")
def week_planner(req: WeekPlannerRequest):
    """
    Orchestrates a weekly meal plan generation via Spoonacular.
    - Accepts optional diet / exclude / targetCalories
    - Calls provider
    - Returns raw payload for exploration (no persistence yet)
    """
    # Basic env guard (explicit error if key missing)
    rapid_key = os.getenv("RAPIDAPI_KEY")
    if not rapid_key:
        print(f"{BLUE}[DEBUG] RAPIDAPI_KEY not configured on server{RESET}")
        raise HTTPException(status_code=500, detail="Server not configured with RAPIDAPI_KEY")

    # Sanitize optional inputs: treat empty strings as None
    diet = (req.diet or "").strip()
    if not diet:
        diet = None

    exclude_csv = (req.exclude or "").strip()
    if not exclude_csv:
        exclude_csv = None

    print(f"{BLUE}[DEBUG] /mealPlanner/weekPlanner payload -> timeFrame={req.timeFrame}, diet={diet}, exclude={exclude_csv}, targetCalories={req.targetCalories}{RESET}")

    result = generate_week_plan(
        time_frame=req.timeFrame,
        diet=diet,
        exclude_csv=exclude_csv,
        target_calories=req.targetCalories,  # may be None; provider omits when None
    )

    if not result.get("ok"):
        status = int(result.get("status", 502))
        error = result.get("error", "Upstream error")
        body = result.get("body", "")
        raise HTTPException(status_code=status, detail={"error": error, "upstream": body[:800]})

    # Return a thin wrapper so you can inspect shape on the client.
    data = result["data"]
    return {
        "timeFrame": req.timeFrame,
        "source": "spoonacular",
        "weekPlan": data,  # contains "week"->{ monday:{meals:[]}, ... }
        "meta": {
            "diet": diet,
            "exclude": exclude_csv,
            "targetCalories": req.targetCalories,
        }
    }
