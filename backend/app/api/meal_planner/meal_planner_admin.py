from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.core.firestore_client import get_firestore_client

router = APIRouter(tags=["Meal Planner - Admin"])
db = get_firestore_client()

class DeletePlanBody(BaseModel):
    userId: str
    planId: str

@router.delete("/deletePlan")
def delete_plan(body: DeletePlanBody):
    if db is None:
        raise HTTPException(status_code=500, detail="Firestore not configured")
    plan_ref = (
        db.collection("users").document(body.userId)
          .collection("mealPlans").document(body.planId)
    )
    # delete days subcollection
    for d in plan_ref.collection("days").stream():
        d.reference.delete()
    # delete plan doc
    plan_ref.delete()
    return {"ok": True}
