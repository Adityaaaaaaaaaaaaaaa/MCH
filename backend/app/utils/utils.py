import filetype
from typing import List, Optional
from app.models.recipe import Recipe

def detect_mime_type(file_bytes: bytes):
    kind = filetype.guess(file_bytes)
    if kind is not None:
        return kind.mime
    return "application/octet-stream"


def build_food_ingredient_prompt() -> str:
    return (
        "You are an advanced food ingredient recognition system. "
        "Given a single photo, identify only RAW food ingredients visibly present (fruits, vegetables, grains, dairy, protein: meat, fish, eggs, legumes, nuts). "
        "Exclude cooked/prepared foods, beverages, packaging, brand names, and non-food items. "
        "For each detected ingredient, produce STRICT structured JSON with this exact Python type: "
        "list[IngredientItem] where IngredientItem = {"
        " itemName: str, quantity: float, unit: 'g'|'ml'|'count', "
        " category: 'Fruits'|'Vegetables'|'Grains'|'Dairy'|'Protein'|'Uncategorized'"
        "}. "
        "Rules: "
        "- Choose exactly ONE category for a recognised food ingredient from the list (use exact capitalization). "
        "- Use 'Uncategorized' only if uncertain. "
        "- Units: only 'g' for grams (solids), 'ml' for millilitres (liquids), or 'count' for whole items. No other units. "
        "- If unit=='count', quantity MUST be an integer >=1 (e.g., 1, 2, 3). "
        "- If a quantity cannot be inferred reliably, use quantity=1 with unit='count'. "
        "- Use the most common English item name (singular). "
        "Output requirements: Respond ONLY with JSON conforming to the schema (no extra text, no markdown)."
    )


def build_receipt_ingredient_prompt() -> str:
    return (
        "You are an advanced grocery receipt parser. The input is a PHOTO of a printed receipt. "
        "Receipts vary widely (layout, fonts, abbreviations, languages). They may be torn, stained, crumpled, blurry, or partially occluded. "
        "Your task: extract ONLY raw food ingredients or cooking staples (e.g., fruits, vegetables, grains, dairy, meat, fish, eggs, legumes, nuts). "
        "EXCLUDE: snacks, prepared/ready meals, beverages (unless a cooking staple like broth), brand names, prices, SKUs, discounts, totals, VAT/tax lines, barcodes, and all non-food items. "
        "Normalize brand SKUs to generic ingredient names (e.g., 'Brand X Brown Sugar' → 'Brown Sugar'). "
        "If line items specify multiple packs or a per-pack weight/volume (e.g., '2 x 500g Chicken'), compute the TOTAL quantity (here 1000 g). "
        "Map units to this STRICT set only: 'g' for grams (solids), 'ml' for millilitres (liquids), 'count' for whole items. No other units are allowed. "
        "Examples of mapping: kg→g (x1000), g→g, L→ml (x1000), ml→ml, pcs/each/pack/dozen→count. "
        "If the quantity is unclear or absent, use quantity=1 and unit='count'. "
        "Categorize each item into EXACTLY ONE of: 'Fruits','Vegetables','Grains','Dairy','Protein','Uncategorized'. "
        "Use 'Uncategorized' only if the category is not confidently determined. "
        "Return output as STRICT JSON ONLY with this exact Python type: list[IngredientItem] where "
        "IngredientItem = {itemName: str, quantity: float, unit: 'g'|'ml'|'count', "
        "category: 'Fruits'|'Vegetables'|'Grains'|'Dairy'|'Protein'|'Uncategorized'}. "
        "Do not add any text or keys outside this schema. Do not wrap in markdown. "
        "If nothing valid can be extracted, return an empty JSON list []."
    )


# For blue debug prints
BLUE = "\033[94m"
RESET = "\033[0m"

def filter_recipes(
    recipes: List[Recipe],
    max_time: Optional[int] = None,
    cuisines: Optional[List[str]] = None,
    diets: Optional[List[str]] = None
) -> List[Recipe]:
    """
    # Define values to ignore for filters
    IGNORED_DIET_VALUES = {"none", "other"}
    IGNORED_CUISINE_VALUES = {"none", "other", "mauritian"}

    # Clean the input filters
    filtered_diets = [d for d in (diets or []) if d and d.strip().lower() not in IGNORED_DIET_VALUES]
    filtered_cuisines = [c for c in (cuisines or []) if c and c.strip().lower() not in IGNORED_CUISINE_VALUES]
    """

    filtered = []
    for recipe in recipes:
        # Filter by max_time
        if max_time is not None and recipe.readyInMinutes is not None:
            if recipe.readyInMinutes > max_time:
                print(f"{BLUE}[DEBUG] Recipe {recipe.id} skipped: readyInMinutes={recipe.readyInMinutes} > max_time={max_time}{RESET}")
                continue

        # Filter by cuisines ONLY if there are valid values
        """
        if filtered_cuisines:
            recipe_cuisines_lower = [c.lower() for c in (recipe.cuisines or [])]
            if not any(c.lower() in recipe_cuisines_lower for c in filtered_cuisines):
                print(f"{BLUE}[DEBUG] Recipe {recipe.id} skipped: cuisines {recipe.cuisines} do not match any of {filtered_cuisines}{RESET}")
                continue

        # Filter by diets ONLY if there are valid values
        if filtered_diets:
            recipe_diets_lower = [d.lower() for d in (recipe.diets or [])]
            if not any(d.lower() in recipe_diets_lower for d in filtered_diets):
                print(f"{BLUE}[DEBUG] Recipe {recipe.id} skipped: diets {recipe.diets} do not match any of {filtered_diets}{RESET}")
                continue
        """

        # Passed all filters
        filtered.append(recipe)

    print(f"{BLUE}[DEBUG] Recipes after filtering: {len(filtered)}{RESET}")
    return filtered

YELLOW = "\033[93m"
RESET = "\033[0m"

def print_rate_limits(headers):
    keys = [
        "X-Ratelimit-Classifications-Limit",
        "X-Ratelimit-Classifications-Remaining",
        "X-Ratelimit-Requests-Limit",
        "X-Ratelimit-Requests-Remaining",
        "X-Ratelimit-Tinyrequests-Limit",
        "X-Ratelimit-Tinyrequests-Remaining"
    ]
    print(f"{YELLOW}[RAPIDAPI RATE LIMITS]{RESET}")
    for key in keys:
        if key in headers:
            print(f"{YELLOW}{key}: {headers[key]}{RESET}")

RECIPE_SUMMARY_PROMPT = (
    "You are a helpful cooking assistant. Summarize the following HTML recipe summary for end users in a cooking app.\n"
    "Focus ONLY on these core details and ignore anything else:\n"
    "• The main purpose or highlight of the recipe (e.g. unique style, health aspect, or target audience).\n"
    "• Key nutrition information if available (e.g. calories, protein, fat, etc.).\n"
    "• Number of servings.\n"
    "• Preparation or cooking time, only if it is concise and clear.\n"
    "• Up to 3-5 main highlights, e.g. if the dish is vegetarian, gluten-free, quick, high protein, etc.\n"
    "\n"
    "STRICTLY EXCLUDE the following from your summary:\n"
    "• Cost, price, or any financial details.\n"
    "• Spoonacular score, likes, popularity metrics, or other ratings.\n"
    "• External website links or references to other recipes.\n"
    "• Generic marketing phrases or irrelevant filler text.\n"
    "\n"
    "The summary should be concise (max 5 sentences), objective, and well-formatted for display in a recipe app UI.\n"
    "Do not include any HTML tags in your output; return only clean text.\n"
    "\n"
    "Here is the recipe HTML summary to process:\n"
    "{html_summary}\n"
)
