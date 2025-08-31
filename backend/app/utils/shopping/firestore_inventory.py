# app/utils/shopping/firestore_inventory.py
from __future__ import annotations
from typing import List, Dict, Any

from app.core.firestore_client import get_firestore_client

BLUE = "\x1B[34m"; YELLOW = "\x1B[33m"; RED = "\x1B[31m"; RESET = "\x1B[0m"
def _blue(m: str):  print(f"{BLUE}{m}{RESET}")
def _yell(m: str):  print(f"{YELLOW}{m}{RESET}")
def _err(m: str):   print(f"{RED}{m}{RESET}")

def fetch_inventory_once(user_id: str) -> List[Dict[str, Any]]:
    """
    Reads users/{uid}/inventory/* and returns a normalized list:
      [{ name: str, quantity: float, unit: "g"|"ml"|"count" }, ...]
    Falls back safely if credentials or fields are missing.
    """
    db = get_firestore_client()
    if db is None:
        _err("[Firestore] No credentials; returning empty inventory")
        return []

    try:
        coll = db.collection("users").document(user_id).collection("inventory")
        docs = list(coll.stream())
        items: List[Dict[str, Any]] = []

        for d in docs:
            data = d.to_dict() or {}
            # Your schema (from screenshot): itemName, quantity, unit
            name = (data.get("itemName") or d.id or "").strip()
            if not name:
                continue
            try:
                qty = float(data.get("quantity") or 0.0)
            except Exception:
                qty = 0.0
            unit = str(data.get("unit") or "count").strip().lower()
            if unit not in {"g", "ml", "count"}:
                # keep it permissive; shopping.py can normalize further
                unit = "count"

            items.append({"name": name, "quantity": qty, "unit": unit})

        _blue(f"[Firestore] Loaded {len(items)} inventory items for {user_id}")
        return items

    except Exception as e:
        _err(f"[Firestore] ERROR reading inventory for {user_id}: {e}")
        return []
