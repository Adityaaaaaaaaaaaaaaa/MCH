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


# --- Spice Level Mapping ---
SPICE_LEVEL_MAP = {
    "No Spice (Plain Jane)":      "No spice (not spicy at all, suitable for children and sensitive palates)",
    "Gentle Warmth (Mild)":       "Mild (very gentle heat, just a little warmth)",
    "Balanced Kick (Medium)":     "Medium (noticeable kick, balanced for most adults)",
    "Bring the Heat (Spicy)":     "Spicy (hot for most people, may cause sweating)",
    "RIP (Super Spicy!)":         "Super Spicy (extremely hot, for chili-lovers only, ghost pepper level)",
    "Mystery Heat (Surprise me!)": "Any (surprise, any level of heat may be included)",
    "Spice? I'm Open!":           "Any (no preference, all levels welcome)",
}

def build_recipe_agent_prompt(
    ingredients, max_time, allergies, diets, cuisines, spice_level_label, num_recipes=15
):
    ingredient_str = ", ".join(ingredients)
    allergies_str = ", ".join(allergies or [])
    diets_str = ", ".join(diets or [])
    cuisines_str = ", ".join(cuisines or [])
    spice_description = SPICE_LEVEL_MAP.get(spice_level_label, "Any (no preference, all levels welcome)")

    return (
        "You are an expert AI recipe agent for home cooking."
        "\nSpice Level Guide:"
        "\n- No spice: Not spicy at all, suitable for children and sensitive palates"
        "\n- Mild: Very gentle heat, just a little warmth"
        "\n- Medium: Noticeable kick, balanced for most adults"
        "\n- Spicy: Hot for most people, may cause sweating"
        "\n- Super Spicy: Extremely hot, for chili-lovers only (ghost pepper, extra-hot chilies)"
        "\n- Any: No preference, any level of spice"
        "\nInterpret 'spice level' strictly according to this guide only and do not rename the Recipe title with spice level in its name"
        f"\nStrictly use ONLY these ingredients: {ingredient_str} for every recipe."
        " Common pantry ingredient that are found commonly but not on this list, except water, salt, pepper, and common pantry basics. Assume the user already has these pantry basics available."
        "\nEach recipe may use any subset of the listed ingredients, but does not need to use them all. Recipes should be practical and reflect real cooking. Never add extra ingredients not on the list (except pantry basics)."
        f"\nThe user cannot consume (allergies): {allergies_str if allergies_str else 'none'}, so avoid recipes with these."
        f"\nThe user prefers these diets: {diets_str if diets_str else 'none'}."
        f"\nRequested cuisines: {cuisines_str if cuisines_str else 'any'}."
        f"\nSpice level: {spice_description}."
        f"\nMaximum cooking time per recipe: {max_time} minutes."
        f"\nReturn exactly {num_recipes} unique recipes. DO NOT invent or repeat recipes."
        "\nFORBIDDEN: hallucinating, inventing fake websites, using restricted or unavailable ingredients, or providing incomplete/ambiguous information."
        "\nFor each recipe, strictly output as a valid JSON object, with these fields only:"
        "\n- title (string, the name of the recipe as on the website/recipe guide, do not invent names for recipes titles, use orginal name of recipe as available)"
        "\n- imageUrl (string, use a real link if available, else empty string)"
        "\n- totalTime (integer, total cooking+prep time in minutes or hours and minutes)"
        "\n- ingredients (list of objects: name [string], quantity [string, e.g. '2 cups'])"
        "\n- instructions (list of detailed step-by-step strings)"
        "\n- equipment (list of strings, eqipment used to prepare the recipe e.g. ['pan', 'oven'])"
        "\n- website (string, MUST be a real recipe websites accessible URL from a public cooking or food guides, vlogs, websites, recipe recognised sources)"
        "\n- videos (list of strings, optional, URLs to relevant recipe video available online or on youtube, if available, else empty list)"
        "\nAggregate these in a single JSON object with key 'recipes', e.g.:"
        '\n{"recipes": [ {...}, {...}, ... ]}'
        "\nDo not add any explanation, commentary, or other text. Your entire reply must be a single valid JSON object as described above, and nothing else."
    )
