import os
from typing import List, Tuple
from pydantic import BaseModel, Field
from google import genai
from google.genai import types as gtypes 

# Typed I/O
class RecipeIn(BaseModel):
    name: str
    amount: float
    unit: str

class InventoryIn(BaseModel):
    key: str           # Firestore docId
    name: str
    unit: str          # g | ml | count
    quantity: float

class DeductionDecision(BaseModel):
    inventory_key: str
    inventory_name: str
    unit: str          # g | ml | count
    starting_quantity: float
    deducted: float
    new_quantity: float
    recipe_name: str

class DeductionOut(BaseModel):
    patch: List[DeductionDecision]
    unmatched: List[str]

BLUE = "\x1B[34m"; END = "\x1B[0m"
def blog(msg: str): print(f"{BLUE}[DEBUG][gemini] {msg}{END}")

CONV_HINT = """
You must express all deductions in these canonical units used by our inventory:
- g  (grams)      -> weight
- ml (milliliters)-> volume
- count           -> whole items

Valid conversions FROM recipe units TO canonical units:
- kg  -> g      (x1000)
- g   -> g
- lb  -> g      (x453.592)
- oz  -> g      (x28.3495)          # weight ounce
- l   -> ml     (x1000)
- ml  -> ml
- cup -> ml     (x240)
- tbsp-> ml     (x15)
- tsp -> ml     (x5)
- fl oz -> ml   (x29.5735)          # fluid ounce
- piece|pcs|unit|whole -> count

Do NOT convert between ml and g (no density assumptions). If a mapping would require density (e.g., “butter 50 g” vs inventory in ml), mark the item as unmatched.

If the recipe unit is missing or unparseable:
- If the candidate inventory unit is count, treat the recipe amount as count.
- Otherwise, mark unmatched.

Round all numeric results to 1 decimal place.
"""

SYSTEM_RULES = """
ROLE & GOAL
You are a deterministic transformation engine. We have:
(1) An INVENTORY of current items with canonical units (g/ml/count).
(2) A RECIPE list with arbitrary names and units.
Your task: map each RECIPE line to one INVENTORY item by NAME ONLY, convert the RECIPE amount into the INVENTORY item's canonical unit (using the conversion hints), and compute the deduction and new quantity.

NAME MATCHING (STRICT)
- Match by NAME ONLY (case-insensitive). Do not use external knowledge.
- Ignore descriptors in recipe names (e.g., chopped, fresh, minced, sliced, large, small, ripe, peeled, crushed, ground, grated).
- Token-overlap is allowed (“red onion” ↔ “onion”).
- Choose AT MOST ONE inventory item per recipe line.
- If no reasonable name match exists, add the recipe name to unmatched.

UNIT RULES (STRICT)
- Use ONLY the allowed conversions in the hints.
- Never convert between ml and g. If unit families differ and no direct conversion exists, put the recipe name in unmatched.
- If multiple recipe lines map to the SAME inventory item, AGGREGATE them into a SINGLE decision for that inventory_key (sum the converted amounts).

OUTPUT RULES (STRICT)
- For each matched item, produce exactly one object with:
  inventory_key, inventory_name, unit (g/ml/count), starting_quantity, deducted, new_quantity, recipe_name.
- Compute: deducted = min(starting_quantity, converted_recipe_amount).
- Compute: new_quantity = max(0, starting_quantity - converted_recipe_amount).
- Never produce negative numbers; never invent items; never alter starting_quantity.
- Output ONLY valid JSON compliant with the response schema. No markdown, comments, or extra keys.
- Round numeric values to 1 decimal place.

QUALITY CHECKLIST (MUST PASS BEFORE OUTPUT)
- [ ] Every decision uses an inventory item from the provided list (no new items).
- [ ] No ml↔g conversions were performed.
- [ ] Duplicates for the same inventory_key were merged (single decision per key).
- [ ] deducted ≤ starting_quantity, new_quantity ≥ 0.
- [ ] Unmatched list includes every recipe line that could not be safely mapped/converted.

EXAMPLES (ILLUSTRATIVE, NOT PART OF OUTPUT)
- Inventory: Onion (unit=count, qty=5)
  Recipe: "chopped onions", 2 count
  → decision: unit=count, deducted=2.0, new_quantity=3.0
- Inventory: Olive Oil (unit=ml, qty=200)
  Recipe: "olive oil", 2 tbsp
  → 2x15=30 ml; deducted=30.0; new_quantity=170.0
- Inventory: Milk (unit=ml, qty=500)
  Recipe: "milk", 100 g  (unit family mismatch)
  → unmatched: ["milk"]
"""

def _make_prompt(decision_id: str, recipe: List[RecipeIn], inventory: List[InventoryIn]) -> str:
    # Compact text prompt (we rely on response_schema for structure)
    return (
        f"Decision ID: {decision_id}\n"
        f"{CONV_HINT}\n"
        f"{SYSTEM_RULES}\n"
        f"Recipe lines:\n" +
        "\n".join([f"- name: {r.name}; amount: {r.amount}; unit: {r.unit}" for r in recipe]) +
        "\nInventory (canonical units):\n" +
        "\n".join([f"- key: {i.key}; name: {i.name}; unit: {i.unit}; qty: {i.quantity}" for i in inventory])
    )

def compute_deduction(
    decision_id: str,
    recipe: List[RecipeIn],
    inventory: List[InventoryIn]
) -> Tuple[List[DeductionDecision], List[str]]:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY not set")

    client = genai.Client(api_key=api_key)
    prompt = _make_prompt(decision_id, recipe, inventory)
    blog(f"Prompt len={len(prompt)} chars; recipe={len(recipe)}; inv={len(inventory)}")

    try:
        resp = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config=gtypes.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=DeductionOut
            ),
        )

        raw_text = getattr(resp, "text", "")
        blog("Gemini raw JSON (as text):")
        blog(raw_text if raw_text else "<empty>")

        parsed: DeductionOut = resp.parsed  
        try:
            blog("Gemini parsed JSON (schema-conformant):")
            blog(parsed.model_dump_json(indent=2))
        except Exception:
            blog("Parsed object dump failed (non-fatal)")

        return parsed.patch, parsed.unmatched

    except Exception as e:
        blog(f"Schema parse failed: {e}; retrying without schema…")
        import json
        rtext = getattr(resp, "text", "{}") if "resp" in locals() else "{}"

        blog("Gemini fallback raw text:")
        blog(rtext)

        data = json.loads(rtext)

        try:
            blog("Gemini fallback parsed dict:")
            blog(json.dumps(data, indent=2))
        except Exception:
            pass

        patch = [DeductionDecision(**p) for p in data.get("patch", [])]
        unmatched = list(data.get("unmatched", []))
        return patch, unmatched
