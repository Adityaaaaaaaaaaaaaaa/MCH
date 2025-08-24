# app/utils/shopping/shopping.py
from __future__ import annotations
from typing import Dict, List, Any, Optional, Tuple

from app.utils.shopping.shopping_normalize import normalize_name, is_pantry

BLUE = "\x1B[34m"; YELLOW = "\x1B[33m"; RESET = "\x1B[0m"
def _blue(msg: str) -> None:  print(f"{BLUE}{msg}{RESET}")
def _yell(msg: str) -> None:  print(f"{YELLOW}{msg}{RESET}")

# normalize a few frequent unit aliases into your canonical set
# (no cross-unit conversions are attempted)
_UNIT_MAP = {
    "g": "g", "gram": "g", "grams": "g",
    "ml": "ml", "milliliter": "ml", "milliliters": "ml",
    "l": "ml", "liter": "ml", "liters": "ml",  # NOTE: still "ml" bucket; no qty conversion here
    "count": "count", "pc": "count", "pcs": "count", "piece": "count", "pieces": "count",
    "unit": "count",
}

def _norm_unit(u: Optional[str]) -> str:
    u = (u or "count").strip().lower()
    return _UNIT_MAP.get(u, u)  # leave unknown as-is (safe fallback)

def _pick_best_name(ing: Dict[str, Any]) -> Tuple[str, str]:
    """
    Choose the most 'canonical' name available from the ingredient dict.
    Preference order:
      canonical / normalized / canonical_name / normalized_name / name
    Returns a tuple: (raw_display_name, normalized_key_for_matching)
    """
    # raw display name for UI/debug
    raw = str(
        ing.get("name")
        or ing.get("canonical")
        or ing.get("normalized")
        or ing.get("canonical_name")
        or ing.get("normalized_name")
        or ""
    ).strip()

    # matching key (normalized)
    preferred = (
        ing.get("canonical")
        or ing.get("normalized")
        or ing.get("canonical_name")
        or ing.get("normalized_name")
        or ing.get("name")
        or ""
    )
    norm = normalize_name(str(preferred))

    if raw and norm:
        _blue(f"[Shopping][normalize] req '{raw}' → '{norm}'")
    elif raw:
        _blue(f"[Shopping][normalize] req '{raw}' → '' (no normalized key)")
    return raw, norm

def _index_inventory(inv: List[Dict[str, Any]]) -> Dict[str, Dict[str, float]]:
    """
    Build: { normalized_name: { unit: total_qty_in_unit, ... }, ... }
    """
    idx: Dict[str, Dict[str, float]] = {}
    for item in inv:
        raw_name = str(item.get("name", "")).strip()
        if not raw_name:
            continue
        nname = normalize_name(raw_name)
        unit  = _norm_unit(item.get("unit", "count"))
        qty   = float(item.get("quantity", 0.0) or 0.0)

        if not nname:
            continue

        # debug: show normalization for inventory once per name
        if nname not in idx:
            _blue(f"[Shopping][normalize] inv '{raw_name}' → '{nname}'")

        idx.setdefault(nname, {})
        idx[nname][unit] = idx[nname].get(unit, 0.0) + qty
    return idx

def _compute_missing_for_recipe(
    required: List[Dict[str, Any]],
    inv_idx: Dict[str, Dict[str, float]]
) -> List[Dict[str, Any]]:
    shopping: List[Dict[str, Any]] = []

    for req in required or []:
        raw_name, norm_name = _pick_best_name(req)
        if not raw_name:
            continue

        unit = _norm_unit(req.get("unit", "count"))
        need = float(req.get("quantity", 0.0) or 0.0)

        # pantry skip
        if norm_name and is_pantry(norm_name):
            _blue(f"[Shopping] (skip pantry) {raw_name} — normalized '{norm_name}'")
            continue

        # lookup
        have_units = inv_idx.get(norm_name, {})
        have = float(have_units.get(unit, 0.0))

        # warn if we *do* have the ingredient but only in other units
        if have <= 0 and have_units and unit not in have_units:
            # example: inventory has 'egg' in 'count' but recipe asked 'g'
            other_units = ", ".join(f"{u}:{q}" for u, q in have_units.items())
            _yell(f"[Shopping][unit-mismatch] '{raw_name}' needs '{unit}', "
                  f"but inventory has: {other_units}")

        missing = max(0.0, need - have)
        if missing > 0:
            tag = "buy" if have <= 0 else "missing"
            shopping.append({
                "name": raw_name,    # keep nice display name
                "need": need,
                "unit": unit,
                "have": have,
                "tag": tag,
            })
    return shopping

def attach_shopping_to_candidates(
    *,
    candidates: List[Dict[str, Any]],
    inventory: List[Dict[str, Any]],
) -> List[Dict[str, Any]]:
    inv_idx = _index_inventory(inventory)
    _blue(f"[Shopping] Inventory indexed: {len(inv_idx)} names")

    enriched: List[Dict[str, Any]] = []
    for c in candidates:
        req = c.get("required_ingredients", []) or []
        shopping = _compute_missing_for_recipe(req, inv_idx)
        _blue(f"[Shopping] {c.get('title')}:{' ' if shopping else ' 0 '} {len(shopping)} items to buy/missing")
        enriched.append({**c, "shopping": shopping})
    return enriched
