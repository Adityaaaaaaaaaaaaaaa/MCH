from __future__ import annotations
from typing import List, Dict, Any
from datetime import datetime, timezone

from app.core.firestore_client import get_firestore_client

BLUE = "\x1B[34m"; YELLOW = "\x1B[33m"; RED = "\x1B[31m"; RESET = "\x1B[0m"
def _blue(m: str):  print(f"{BLUE}{m}{RESET}")
def _err(m: str):   print(f"{RED}{m}{RESET}")

def save_ai_cravings_session(
    *,
    user_id: str,
    session_id: str,                 # e.g. "240825_1616"
    recipes: List[Dict[str, Any]],   # already has shopping etc.
    query: str,
    constraints: Dict[str, Any],
    preferences: Dict[str, Any],
    store_image_data_url: bool = False,  # kept for API compatibility, but ignored
) -> bool:
    """
    Firestore layout:
      users/{uid}/aiCravings/{session_id}                 (meta)
      users/{uid}/aiCravings/{session_id}/recipes/{rid}   (3 docs)

    SAFETY: we DO NOT store base64 images to avoid Firestore 1 MiB doc limits.
            We store only hasImage=true/false.
    """
    db = get_firestore_client()
    if db is None:
        _err("[Cravings][FS] No Firestore client; skipping save")
        return False

    try:
        parent = (
            db.collection("users")
              .document(user_id)
              .collection("aiCravings")
              .document(session_id)
        )

        meta = {
            "createdAt": datetime.now(timezone.utc).isoformat(),
            "query": query,
            "constraints": constraints,
            "preferences": preferences,
            "recipeCount": len(recipes),
        }

        _blue(f"[Cravings][FS] Writing session meta → users/{user_id}/aiCravings/{session_id}")
        parent.set(meta, merge=True)

        batch = db.batch()
        coll = parent.collection("recipes")

        for r in recipes:
            rid = r.get("id") or "recipe"
            # Only keep a boolean so UI knows it can show a cached/regenerated image
            has_image = bool(r.get("image"))

            # inside the loop in save_ai_cravings_session(...)
            body = {
                "id": r.get("id"),
                "title": r.get("title"),
                "readyInMinutes": r.get("readyInMinutes"),
                "reasons": r.get("reasons", []),
                "shopping": r.get("shopping", []),
                "hasImage": bool(has_image),
            }

            # pass-through important fields if present
            for k in [
                "required_ingredients",
                "optional_ingredients",
                "instructions",
                "cuisines",
                "diets",
                "vegetarian",
                "vegan",
                "glutenFree",
                "dairyFree",
                "summary",
                "nutrition",
            ]:
                if k in r:
                    body[k] = r[k]

            batch.set(coll.document(rid), body)

        batch.commit()
        _blue(f"[Cravings][FS] Saved {len(recipes)} recipe docs under session {session_id}")
        return True

    except Exception as e:
        _err(f"[Cravings][FS] ERROR saving cravings session: {e}")
        return False
