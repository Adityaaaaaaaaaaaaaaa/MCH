# app/api/debug.py
from fastapi import APIRouter
from google.cloud import firestore
from datetime import datetime, timezone

router = APIRouter(tags=["Debug"])

@router.get("/debug/firestore")
def debug_firestore():
    db = firestore.Client()
    doc = db.collection("debug").document("ping")
    payload = {"ok": True, "ts": datetime.now(timezone.utc).isoformat()}
    doc.set(payload, merge=True)
    return {"wrote": payload, "read": doc.get().to_dict()}
