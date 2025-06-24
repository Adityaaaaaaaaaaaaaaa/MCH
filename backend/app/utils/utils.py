import filetype

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


# Gemini API endpoint root and model here
GEMINI_API_ROOT = "https://generativelanguage.googleapis.com/v1beta/models"
DEFAULT_STABLE_GEMINI_MODEL = "gemini-2.0-flash-001"

def gemini_model_url(model=DEFAULT_STABLE_GEMINI_MODEL, method="generateContent", api_key=None):
    url = f"{GEMINI_API_ROOT}/{model}:{method}"
    if api_key:
        url += f"?key={api_key}"
    return url
