# app/utils/ai_prompt.py
# app/utils/ai_prompt.py
from typing import List
from textwrap import dedent

BLUE = "\x1B[34m"; RESET = "\x1B[0m"
def _blue(msg: str) -> None:
    print(f"{BLUE}{msg}{RESET}")

def build_gemini_recipe_prompt(
    *,
    query: str,
    max_time: int,
    spice_level: int,               # 0..4 (resolved)
    allergies: List[str],
    cuisines: List[str],
    diets: List[str],
) -> str:
    """
    Prompt for EXACTLY 3 distinct recipes as a JSON ARRAY (no extra text).
    Emphasizes: query has top priority; prefs are guidance only; desserts ignore spice.
    """
    _blue("[Gemini][prompt] building prompt …")

    spice_scale = (
        "Spice scale (0–4): 0=No spice, 1=Mild, 2=Medium, 3=Spicy, 4=Very spicy (no extreme hazards)."
    )
    allergies_text = ", ".join(allergies) if allergies else "None"
    cuisines_text  = ", ".join(cuisines) if cuisines else "Any"
    diets_text     = ", ".join(diets)    if diets    else "Any"
    query_text     = query.strip() or "(No free‑text preference provided)"

    # Top-level MUST be a JSON array of 3 recipe objects, nothing else.
    # Field names are fixed to match our response_schema in code.
    return dedent(f"""
    You are a careful culinary assistant. Produce EXACTLY THREE distinct, home-cookable recipes as a JSON ARRAY.
    Return ONLY JSON (no prose) that strictly follows the schema specified below.

    PRIORITY & BEHAVIOR RULES
    - The USER QUERY has TOP PRIORITY. Never substitute a different dish type.
      • If the query asks for a dessert/baked sweet (e.g., cake, cookies, pie, brownies, tart, pastry, ice cream),
        treat spice level as 0 and DO NOT add chilies/heat.
      • If the query specifies a cuisine or style (e.g., "Mauritian fried rice"), obey it even if not in prefs.
    - Preferences (cuisines, diets, spice) are GUIDANCE ONLY. Apply them when they do not conflict with the query.
    - Never violate allergies or diets.
    - Recipes must be distinct (no minor variations).

    HARD CONSTRAINTS
    - Total time (readyInMinutes) <= {max_time}
    - Target spiceLevel (0..4) = {spice_level}, EXCEPT desserts/sweets => force 0
    - Use realistic, widely available ingredients and home-cook techniques.

    CONTEXT
    {spice_scale}
    Allergies to AVOID: {allergies_text}
    User diets: {diets_text}
    Preferred cuisines: {cuisines_text}
    User free-text query: {query_text}

    OUTPUT RULES (STRICT)
    - Top-level: an ARRAY with exactly 3 objects.
    - Each object MUST have the following fields:
        "id": string  // format: DDMMYY_HHMM (24h) in UTC+4 (Mauritius), e.g., "230825_2012"
        "title": string,
        "readyInMinutes": integer > 0 (<= {max_time}),
        "reasons": array of short strings (why it matches query/time/prefs),
        "required_ingredients": array of objects {{ "name": string, "quantity": number, "unit": "g"|"ml"|"count" }},
        "optional_ingredients": array of the same object schema (can be empty),
        "instructions": array of clear, safe, step-by-step strings (no numbering needed),
        "cuisines": array of strings,
        "diets": array of strings,
        "vegetarian": boolean,
        "vegan": boolean,
        "glutenFree": boolean,
        "dairyFree": boolean,
        "summary": optional string,
        "nutrition": optional object {{ "calories": number, "protein_g": number, "fat_g": number, "carbs_g": number }}
    - UNITS: use only "g" (solids), "ml" (liquids), or "count" (whole items).
      • Prefer "ml" for liquids like water, milk, oil, vinegar, soy/oyster/fish sauce, etc.
      • Prefer "g" for solids.
    - Keep instructions concise and safe. No URLs, no markdown, no images.
    - Ensure the three recipes are meaningfully different.
    - Output MUST be a raw JSON ARRAY, not a quoted string. Do NOT escape quotes.
    - Do NOT wrap in markdown fences or add any text before/after.

    OUTPUT: Return ONLY the JSON array. No extra text.
    """).strip()


def recipe_image_prompt(title: str) -> str:
    return dedent(f"""
    Generate one high-quality, photorealistic hero image for a cooked dish titled:
    "{title}".

    Art direction:
    - appetizing overhead or 45° angle
    - clean plate, soft lighting, subtle depth of field
    - neutral, minimal background / props
    - no people, no text, no watermarks, no logos
    - realistic ingredients; avoid fantasy elements
    - color-accurate food tones
    - avoid cartoon/anime/illustration styles; avoid overly dark or moody styles

    Output only one image.
    """).strip()
