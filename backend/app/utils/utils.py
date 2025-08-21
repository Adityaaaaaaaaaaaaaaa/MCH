import filetype
from typing import List, Optional
from app.models.recipe import Recipe

def detect_mime_type(file_bytes: bytes):
    kind = filetype.guess(file_bytes)
    if kind is not None:
        return kind.mime
    return "application/octet-stream"


def build_food_ingredient_prompt():
    return (
        "You are an advanced food ingredient recognition system. "
        "Given an input image, identify only raw food ingredients visibly present from the image (such as fruits, vegetables, grains, dairy, or protein sources: meat, fish, eggs, legumes, or nuts). "
        "Exclude all forms of cooked or prepared foods, beverages, packaging, brand names, or non-food items. "
        "Categorize each detected ingredient into ONE of these categories (use exact spelling and capitalization): Fruits, Vegetables, Grains, Dairy, Protein, or Uncategorized. "
        "Assign 'Uncategorized' only if the category cannot be confidently determined. "
        "For each food ingredient detected, return the result in the following format and no other:\n"
        "{itemName, count, category},{itemName, count, category},...\n"
        "- itemName and category are Strings. Use the most precise and common English name for the ingredient. "
        "- count is an integer representing the number of items detected; only include count if it is clear and unambiguous, otherwise use 1. Do not use decimals. "
        "If no food ingredient can be detected, reply with { No ingredients detected } and nothing else. "
        "Respond ONLY in the format specified above—do not include any other information, commentary, or formatting."
    )


def build_receipt_ingredient_prompt():
    return (
        "You are an advanced grocery receipt parser. "
        "Given an image of a grocery receipt, extract only raw food ingredients and cooking staples from the image (such as fruits, vegetables, grains, dairy, or protein sources: meat, fish, eggs, legumes, or nuts). "
        "Exclude snacks, prepared meals, beverages, non-food items, packaging, and brand names. "
        "Receipts may vary in layout and language; focus only on extracting relevant food ingredients. "
        "Categorize each item into ONE of the following categories (use exact spelling and capitalization): Fruits, Vegetables, Grains, Dairy, Protein, or Uncategorized. "
        "Assign 'Uncategorized' only if the category cannot be confidently determined. "
        "For each ingredient detected, return the result in the following format and no other:\n"
        "{itemName, count, category},{itemName, count, category},...\n"
        "- itemName and category are Strings. Use the most precise and common English name for the ingredient. "
        "- count is an integer representing the quantity purchased; only include count if it is clear and unambiguous, otherwise use 1. Do not use decimals. "
        "If no valid ingredient can be extracted, reply with { No ingredients detected } and nothing else. "
        "Respond ONLY in the format specified above, do not include any other information, commentary, or formatting."
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
