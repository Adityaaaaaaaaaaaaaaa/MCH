from __future__ import annotations

import base64
import json
import os
from typing import List, Literal, Tuple, Dict, Any

from google import genai
from google.genai import types
from pydantic import BaseModel, ValidationError

BLUE = "\033[94m"
RESET = "\033[0m"
def _blue(msg: str): print(f"{BLUE}{msg}{RESET}")

class IngredientItem(BaseModel):
    itemName: str
    quantity: float          
    unit: Literal["g", "ml", "count"]
    category: Literal["Fruits", "Vegetables", "Grains", "Dairy", "Protein", "Uncategorized"]

ALLOWED_UNITS = {"g", "ml", "count"}
ALLOWED_CATEGORIES = {"Fruits", "Vegetables", "Grains", "Dairy", "Protein", "Uncategorized"}

def _normalize_items(items: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    norm: List[Dict[str, Any]] = []
    for it in items:
        name = (it.get("itemName") or "").strip()
        qty = it.get("quantity", 1)
        unit = (it.get("unit") or "").lower().strip()
        cat  = (it.get("category") or "Uncategorized").strip()

        if not name:
            continue
        if unit not in ALLOWED_UNITS:
            unit = "count"
        if cat not in ALLOWED_CATEGORIES:
            cat = "Uncategorized"

        # Enforce integer for 'count'
        try:
            qf = float(qty)
        except Exception:
            qf = 1.0
        if unit == "count":
            qf = max(1, int(round(qf)))

        norm.append({
            "itemName": name[:80],  # trim noisy long strings
            "quantity": float(qf),
            "unit": unit,
            "category": cat,
        })
    return norm

def _repair_with_model(broken_json: str, client: genai.Client) -> List[Dict[str, Any]]:
    """
    Ask Gemini to repair malformed JSON to the exact schema.
    One, short retry; safest for production latency.
    """
    _blue("[Gemini][scanFood] Attempting JSON repair with schema")
    resp = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=[
            "You will be given possibly broken JSON.\n"
            "Return ONLY valid JSON that matches this Python type exactly: list[IngredientItem]."
            "Do not include any extra text or comments."
        ],
        tools=[],
        config={
            "response_mime_type": "application/json",
            "response_schema": list[IngredientItem],  # schema control
        },
    )
    resp = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=[
            "Repair the JSON below to strictly match list[IngredientItem] "
            "(fields: itemName:str, quantity:float, unit in ['g','ml','count'], "
            "category in ['Fruits','Vegetables','Grains','Dairy','Protein','Uncategorized']). "
            "Return ONLY valid JSON, no narration.",
            broken_json
        ],
        config={
            "response_mime_type": "application/json",
            "response_schema": list[IngredientItem],
        },
    )
    try:
        if getattr(resp, "parsed", None):
            return [ii.model_dump() for ii in resp.parsed]  # list[IngredientItem]
        return json.loads(resp.text or "[]")
    except Exception:
        return []

def analyze_food_image_bytes(
    file_bytes: bytes,
    mime_type: str,
    prompt_text: str,
    *,
    gemini_api_key: str | None = None
) -> Tuple[List[Dict[str, Any]], Dict[str, Any] | None]:
    """
    Returns (items, error). On success, error is None.
    """
    if not gemini_api_key:
        gemini_api_key = os.getenv("GEMINI_API_KEY")
    if not gemini_api_key:
        _blue("[Gemini][scanFood] WARNING: GEMINI_API_KEY not set in environment")

    client = genai.Client(api_key=gemini_api_key)
    image_part = types.Part.from_bytes(data=file_bytes, mime_type=mime_type)

    _blue("[Gemini][scanFood] Invoking gemini-2.5-flash with structured output")
    try:
        resp = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=[image_part, prompt_text],
            config={
                "response_mime_type": "application/json",
                "response_schema": list[IngredientItem],
            },
        )

        raw_items: List[Dict[str, Any]] = []
        if getattr(resp, "parsed", None):
            raw_items = [ii.model_dump() for ii in resp.parsed]  # type: ignore
        else:
            raw_items = json.loads(resp.text or "[]")

        items = _normalize_items(raw_items)

        _blue(f"[Gemini][scanFood] Received {len(items)} items")
        return items, None

    except ValidationError as ve:
        _blue(f"[Gemini][scanFood] ValidationError: {ve}. Trying JSON repair...")
        repaired = _repair_with_model(broken_json=str(ve), client=client)
        items = _normalize_items(repaired)
        return items, None if items else {"message": "Validation failed and repair returned no items.", "code": 422}

    except Exception as e:
        _blue(f"[Gemini][scanFood] Exception: {e}")
        return [], {"message": f"Gemini call failed: {e}", "code": 500}
