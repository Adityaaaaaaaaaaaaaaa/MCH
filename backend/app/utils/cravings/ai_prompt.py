from typing import List, Optional
from textwrap import dedent

BLUE = "\x1B[34m"; RESET = "\x1B[0m"
def _blue(msg: str) -> None:
    print(f"{BLUE}{msg}{RESET}")

def build_gemini_recipe_prompt(
    *,
    query: str,
    max_time: int,
    spice_level: int,
    allergies: List[str],
    cuisines: List[str],
    diets: List[str],
    allowed_canonicals: Optional[List[str]] = None,
) -> str:
    _blue("[Gemini][prompt] building prompt …")

    spice_scale = (
        "Spice scale (0-4): 0=No spice, 1=Mild, 2=Medium, 3=Spicy, 4=Very spicy (no extreme hazards)."
    )
    allergies_text = ", ".join(allergies) if allergies else "None"
    cuisines_text  = ", ".join(cuisines) if cuisines else "Any"
    diets_text     = ", ".join(diets)    if diets    else "Any"
    query_text     = query.strip() or "(No free-text preference provided)"

    canon_vocab = ""
    if allowed_canonicals:
        unique = sorted(set(x.strip().lower() for x in allowed_canonicals if x.strip()))
        canon_vocab = (
            "\n    CANONICAL VOCABULARY (prefer these if applicable):\n"
            "    - " + ", ".join(unique)
        )

    return dedent(f"""
    You are a careful culinary assistant. Produce EXACTLY THREE distinct, home-cookable recipes **as a raw JSON ARRAY**.
    Return ONLY a JSON array and nothing else. Do NOT use markdown, backticks, or any prose before/after.

    PRIORITY & BEHAVIOR RULES
    - The USER QUERY has TOP PRIORITY. Never substitute a different dish type.
      • If the query asks for a dessert/baked sweet (e.g., cake, cookies, pie, brownies, tart, pastry, ice cream),
        treat spice level as 0 and DO NOT add chilies/heat.
      • If the query specifies a cuisine or style (e.g., "Mauritian fried rice"), obey it even if not in prefs.
    - Preferences (cuisines, diets, spice) are GUIDANCE ONLY when they don't conflict with the query.
    - Never violate allergies or diets.
    - The three recipes must be meaningfully different (not small variations).
    
    QUERY VALIDATION
    - First, decide if the user query clearly refers to a food, drink, dish, or cooking method/ingredient.
    - If the query is NOT food-related (e.g., vehicles, devices, places, people, colors with no food nouns):
        • Ignore cuisine/spice intent from the query.
        • Generate 3 varied, approachable recipes that respect allergies/diets and time limit.
        • In reasons[0] include EXACTLY this message:
            "[invalid-non-food] Query wasn’t food-related; showing 3 varied recipes instead."
    - If the query IS food-related, proceed normally and DO NOT include that message.
    - If the query is ambiguous (e.g., "apple" could be fruit or tech brand):
        • Assume it's food-related unless it clearly isn't.
        • If you think it might be non-food, include in reasons[0]:
            "[ambiguous] Query might not be food-related; assuming it is."
    - If the query is very generic (e.g., "dinner", "lunch", "snack", "breakfast", "food", "recipe"):
        • Include in reasons[0]: "[generic] Query was very generic; showing 3 varied recipes."
        • Generate 3 varied, approachable recipes that respect allergies/diets and time limit.
        

    HARD CONSTRAINTS
    - Total time (readyInMinutes) <= {max_time}
    - Target spiceLevel (0..4) = {spice_level}, EXCEPT desserts/sweets => force 0
    - Use realistic ingredients and home techniques; no brands.

    CONTEXT
    {spice_scale}
    Allergies to AVOID: {allergies_text}
    User diets: {diets_text}
    Preferred cuisines: {cuisines_text}
    User free-text query: {query_text}
    {canon_vocab}

    INGREDIENT NORMALIZATION (VERY IMPORTANT)
    - For each ingredient object, add:
        "canonical": a short, lowercase canonical name for inventory matching.
          • Singular nouns; no brands; collapse varieties to a base item.
          • Examples:
              "Granny Smith apples" → "apple"
              "red bell pepper"/"bell peppers" → "bell pepper"
              "green onions"/"spring onions"/"scallions" → "scallion"
              "yoghurt" → "yogurt"
              "red chili powder" → "chilli powder"
          • If uncertain, repeat the original name in lowercase.
        "pantryLikely": true if most households keep it as a staple (salt, sugar, oil, soy sauce, stock, etc.); false otherwise.
    - Units must be normalized: "g" for solids, "ml" for liquids, "count" for whole items.
      • Liquids examples: water, milk, oil, vinegar, soy/oyster/fish sauce → "ml"
      • Solids examples: flour, cheese, rice, butter → "g"
      • Whole items examples: eggs, lemons, onions → "count"

    OUTPUT RULES (STRICT) // always try to add all fields if possible
    - Top-level: an ARRAY with exactly 3 objects.
    - Each object MUST have:
        "id": string,  // format DDMMYY_HHMM in UTC+4 (Mauritius), e.g. "230825_2012"
        "title": string,
        "readyInMinutes": integer > 0 (<= {max_time}),
        "reasons": array<string>,  // why it matches query/time/prefs, stricly is an array of plaintext strings
        "required_ingredients": array<object> with keys {{
            "name": string,
            "quantity": number,
            "unit": "g"|"ml"|"count",
            "canonical": string,
            "pantryLikely": boolean
        }},
        "optional_ingredients": array<object> with the same keys (can be empty),
        "instructions": array<string>, // clear, step-by-step cooking steps
        "cuisines": array<string>, // from user prefs if possible
        "diets": array<string>, // add if applicable
        "vegetarian": boolean,
        "vegan": boolean,
        "glutenFree": boolean,
        "dairyFree": boolean,
        "summary": optional string, // descriptive plain-text, no markup summary of the dish
        "nutrition": optional object {{ "calories": number, "protein_g": number, "fat_g": number, "carbs_g": number }}, // add if possible estimation but keep it realistic
        "servings": optional integer > 0 // add if known
    - Do NOT invent extra keys beyond the above. If you don't know a value, omit that optional key entirely.
    - Keep instructions concise and safe. No URLs, images, or markdown.
    - Output MUST be valid JSON. Do NOT wrap in markdown fences. Do NOT output a quoted string.
    - Absolutely NO text before or after the array.
    - If the query was not food-related, reasons[0] MUST be:
        "[invalid-non-food] Query wasn't food-related; showing 3 varied recipes instead."
        Otherwise, do not use that tag.
    - Reasons should be concise, relevant, and unique per recipe.


    COMMON FAILURE MODES TO AVOID
    - Do NOT output prose or explanations.
    - Do NOT output JSON5 (comments, trailing commas).
    - Do NOT output markdown fences or triple backticks.

    """).strip()


def recipe_image_prompt(title: str) -> str:
    return dedent(f"""
    Create a single, high-resolution, photorealistic hero image of a freshly prepared dish titled:
    "{title}"

    Guidelines:
    - Output: exactly 1 PNG image
    - Aspect ratio: 4:3 (landscape)
    - Size: 1280x960 px (approx); no borders or frames
    - Composition: overhead or 45° angle; tightly focused on the dish
    - Presentation: clean, neutral plate or bowl; elegant, appetizing plating
    - Lighting: soft, natural or studio lighting; gentle shadows; subtle depth of field
    - Background: minimal, neutral surface (e.g., wood, stone, linen); no clutter or distracting props
    - Food styling: highlight fresh, realistic ingredients; vibrant, natural colors; avoid artificial shine or cartoon effects
    - Exclude: people, hands, utensils, logos, watermarks, text overlays, excessive garnishes
    - Atmosphere: inviting, warm, and authentic; evoke the dish's cuisine and character

    Return only the image.
    """).strip()
