import filetype

def detect_mime_type(file_bytes: bytes):
    kind = filetype.guess(file_bytes)
    if kind is not None:
        return kind.mime
    return "application/octet-stream"

def build_food_ingredient_prompt():
    return (
        "You are a food ingredient detection expert. "
        "Analyse the provided image and extract ONLY the names of food ingredients visible—such as fruits, vegetables, meats, fish, grains, legumes, dairy products, or grocery items that are typically used to prepare meals. "
        "Exclude all prepared foods, cooked dishes, drinks, non-edible items, packaging, and brand names. "
        "For each ingredient, count each ingrendient if visible. "
        "Provide your response strictly as: itemName: count, itemName: count (comma-separated). "
        "If a count cannot be determined, omit the count but still list the item name. "
        "Do not provide any explanations, context, or commentary—respond only with the specified format."
    )


def build_receipt_ingredient_prompt():
    return (
        "You are an expert in extracting food ingredients from grocery receipts. "
        "From the given receipt image, extract ONLY the items that are raw food ingredients or cooking staples (e.g., fruits, vegetables, meats, fish, grains, dairy, pantry staples). "
        "Note that all receipts have different receipt formats and layouts, so focus on identifying valid food items and its count "
        "Exclude any non-food items, prepared meals, snacks, beverages, cleaning products, packaging, or brand names. "
        "For each valid item, extract the name and quantity purchased, if available, in the following format: itemName: count, itemName: count (comma-separated). "
        "If quantity is not listed, just provide the item name. "
        "Do not add any extra explanation, notes, or commentary—only return the result in the specified format."
    )


# Gemini API endpoint root and model here
GEMINI_API_ROOT = "https://generativelanguage.googleapis.com/v1beta/models"
DEFAULT_GEMINI_MODEL = "gemini-2.0-flash-001"

def gemini_model_url(model=DEFAULT_GEMINI_MODEL, method="generateContent", api_key=None):
    url = f"{GEMINI_API_ROOT}/{model}:{method}"
    if api_key:
        url += f"?key={api_key}"
    return url
