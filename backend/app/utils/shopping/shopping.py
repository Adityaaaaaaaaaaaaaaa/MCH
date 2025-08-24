# app/utils/shopping.py
from __future__ import annotations
from typing import Dict, List, Any
from app.utils.shopping.shopping_normalize import normalize_name, is_pantry

BLUE = "\x1B[34m"; RESET = "\x1B[0m"
def _blue(msg: str) -> None: print(f"{BLUE}{msg}{RESET}")

def _index_inventory(inv: List[Dict[str, Any]]) -> Dict[str, Dict[str, float]]:
    idx: Dict[str, Dict[str, float]] = {}
    for item in inv:
        name = normalize_name(str(item.get("name", "")))
        if not name:
            continue
        unit = str(item.get("unit", "count") or "count").strip().lower()
        qty  = float(item.get("quantity", 0.0) or 0.0)
        idx.setdefault(name, {})
        idx[name][unit] = idx[name].get(unit, 0.0) + qty
    return idx

def _compute_missing_for_recipe(required: List[Dict[str, Any]], inv_idx: Dict[str, Dict[str, float]]) -> List[Dict[str, Any]]:
    shopping: List[Dict[str, Any]] = []
    for reqItem in required:
        raw_name = str(reqItem.get("name", "")).strip()
        if not raw_name:
            continue
        name = normalize_name(raw_name)
        unit = str(reqItem.get("unit", "count") or "count").strip().lower()
        need = float(reqItem.get("quantity", 0.0) or 0.0)

        # pantry skip
        if is_pantry(name):
            _blue(f"[Shopping] (skip pantry) {raw_name} — normalized '{name}'")
            continue

        have_units = inv_idx.get(name, {})
        have = float(have_units.get(unit, 0.0))
        missing = max(0.0, need - have)
        if missing > 0:
            tag = "buy" if have <= 0 else "missing"
            shopping.append({"name": raw_name, "need": need, "unit": unit, "have": have, "tag": tag})
    return shopping

def attach_shopping_to_candidates(*, candidates: List[Dict[str, Any]], inventory: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    inv_idx = _index_inventory(inventory)
    _blue(f"[Shopping] Inventory indexed: {len(inv_idx)} names")

    enriched: List[Dict[str, Any]] = []
    for c in candidates:
        req = c.get("required_ingredients", [])
        shopping = _compute_missing_for_recipe(req, inv_idx)
        _blue(f"[Shopping] {c.get('title')}:{' ' if shopping else ' 0 '} {len(shopping)} items to buy/missing")
        enriched.append({**c, "shopping": shopping})
    return enriched
