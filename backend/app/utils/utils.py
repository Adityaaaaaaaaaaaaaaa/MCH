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


""" # --- Spice Level Mapping ---
SPICE_LEVEL_MAP = {
    "No Spice (Plain Jane)":      "No spice (not spicy at all, suitable for children and sensitive palates)",
    "Gentle Warmth (Mild)":       "Mild (very gentle heat, just a little warmth)",
    "Balanced Kick (Medium)":     "Medium (noticeable kick, balanced for most adults)",
    "Bring the Heat (Spicy)":     "Spicy (spicy but not super hot)",
    "RIP (Super Spicy!)":         "Spicy (for chili-lovers)",
    "Mystery Heat (Surprise me!)": "Any (surprise, any level of heat may be included)",
    "Spice? I'm Open!":           "Any (no preference, all levels welcome)",
}
 """
""" def build_recipe_agent_prompt(
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
        f"\nMaximum cooking time per recipe: {max_time} minutes. The total time should includes both preparation and cooking time."
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
 """ 

""" def build_recipe_links_prompt(
    ingredients, max_time, allergies, diets, cuisines, spice_level_label, num_links=15
):
    # Using the Tier 1 list of most popular and trusted domains
    ALLOWED_DOMAINS = [
        "allrecipes.com",
        "bbcgoodfood.com", "bonappetit.com", "budgetbytes.com", "chefkoch.de", "cookieandkate.com",
        "cooking.nytimes.com",
        "damndelicious.net", "delish.com",
        "epicurious.com", 
        "food.com", "food52.com", "foodnetwork.com",
        "gimmesomeoven.com",
        "halfbakedharvest.com", 
        "inspiredtaste.net", 
        "jamieoliver.com", 
        "kingarthurbaking.com",
        "maangchi.com", "marmiton.org", "minimalistbaker.com", "myrecipes.com", 
        "onceuponachef.com", "pinchofyum.com",
        "recipetineats.com", "ricette.giallozafferano.it",
        "sallysbakingaddiction.com", "seriouseats.com", "simplyrecipes.com", "skinnytaste.com",
        "taste.com.au", "tasteofhome.com", "tasty.co", "thekitchn.com", "thepioneerwoman.com", "thespruceeats.com", "thewoksoflife.com",
    ]
    domain_str = ", ".join(ALLOWED_DOMAINS)
    ingredient_str = ", ".join(ingredients)
    allergies_str = ", ".join(allergies or [])
    diets_str = ", ".join(diets or [])
    cuisines_str = ", ".join(cuisines or [])
    spice_description = SPICE_LEVEL_MAP.get(spice_level_label, "Any (no preference, all levels welcome)")

    # Add specific focus for Mauritian if present in cuisine selection
    cuisine_focus = ""
    if "Mauritian" in [c.lower() for c in cuisines]:
        cuisine_focus = (
            "Focus on Mauritian, Indian Ocean, Indo-French Creole, and fusion Mauritian recipes. "
            "Find recipe links to typical Mauritian dishes. "
            "Use local Mauritian ingredients and cooking styles where possible. "
            "If not available, provide the best closest alternative to the recipe. else focus on other cuisines asked by the user"
            "but try to get Mauritian cuisines if available"
            "If available, provide the link to the recipe, Link must be a valid and real url accessible"
        )
        
    return (
        "You are an AI recipe search assistant for home cooks. "
        f"Given the following user constraints, return ONLY a JSON object with a single key 'links', containing an array of working, real, accessible recipe URLs from these trusted sites: {domain_str}. "
        f"Recipes links outside allowed trusted sites are allowed but carefully choosen so as they match the criteria of the search request. "
        f"{cuisine_focus}"
        "The recipes must closely fit the requirements below. Never invent URLs. Never add commentary, markdown, or explanation. No extra text, only valid JSON:\n"
        f"- Allowed ( Do not use other ingredients outside ot the allowed ingredients list ) ingredients: {ingredient_str}\n"
        f"- Common pantry ingredient that are found commonly but not on this list, except water, salt, pepper, and common pantry basics. Assume the user already has these pantry basics available\n"
        f"- Maximum total cooking ( Preparation + Cooking time ) time: {max_time} minutes\n"
        f"- Allergies (avoid): {allergies_str or 'none'}\n"
        f"- Diets: {diets_str or 'none'}\n"
        f"- Cuisines: {cuisines_str or 'any'}\n"
        f"- Spice level: {spice_description}\n"
        f"Each recipe may use any subset of the listed allowed ingredients, but does not need to use them all. Never add extra ingredients not on the list (except pantry basics)\n"
        f"Return exactly {num_links} unique, non-duplicate links. All links must be to real, public recipe pages, not category or search result pages.\n"
        "Do not invent websites, URLs, or recipes. Do not use private blogs or subscription-only sites. The response must be a single, valid JSON object like:\n"
        '{\n  "links": [\n    "https://allrecipes.com/recipe/12345/example",\n    "https://mauritianfood.com/recipe/rougaille", ...\n  ]\n}\n'
        "Respond ONLY in this JSON format, with no markdown, no explanation, and no extra fields."
    )
 """

""" def build_recipe_agent_prompt(
    ingredients, max_time, allergies, diets, cuisines, spice_level_label, num_recipes=15
):
    ingredient_str = ", ".join(ingredients)
    allergies_str = ", ".join(allergies or [])
    diets_str = ", ".join(diets or [])
    cuisines_str = ", ".join(cuisines or [])
    spice_description = SPICE_LEVEL_MAP.get(spice_level_label, "Any (no preference, all levels welcome)")

    # Safety and robust fallback for spice
    if spice_level_label in {"RIP (Super Spicy!)", "Mystery Heat (Surprise me!)"}:
        spice_caution = (
            "For high or uncertain spice requests ('Super Spicy', 'Surprise me!'), return only recipes that are authentic and traditionally served at such heat levels. "
            "NEVER invent or escalate the spice artificially, and NEVER propose unsafe challenge dishes or novelty recipes. "
            "If no safe, authentic options are available, **reduce the result set and, if necessary, substitute with the closest authentic recipe matching other criteria.** "
            "Always avoid recipes where the heat level could present risk or be unsuitable for the general public."
        )
    else:
        spice_caution = (
            "For other spice levels, select only authentic dishes that naturally correspond to the requested heat."
        )

    prompt = (
        "You are an advanced, professional AI recipe expert for home cooking. "
        "Your task is to recommend only genuine, practical, and diverse recipes, strictly adhering to the user's constraints. "
        "Every result must be drawn from reputable, publicly accessible, and verifiable recipe sources online. "
        f"Use ONLY the following as main ingredients: {ingredient_str}. "
        "Do NOT introduce additional ingredients except universally available pantry basics (e.g., water, salt, pepper, oil). "
        f"Exclude any recipe containing these allergens: {allergies_str if allergies_str else 'None specified'}. "
        f"Respect the following dietary requirements: {diets_str if diets_str else 'None specified'}. "
        f"Focus on these cuisines if specified: {cuisines_str if cuisines_str else 'Any cuisine'}. "
        f"Strictly adhere to the requested spice level: {spice_description}. {spice_caution} "
        "Do NOT alter recipe names to reflect spice. Use only the real name of the recipe. "
        "Find recipes that are suitable for main course meals mostly as mandatory and other types as non mandatory. "
        f"Total preparation and cooking time per recipe must not exceed {max_time} minutes. "
        "Each returned recipe MUST be a unique, authentic, real-world dish, with a valid, accessible website link from a reputable culinary domain. "
        "Do not repeat, invent, or generalise. If the full number of recipes cannot be found that match ALL criteria, return only those that are fully compliant, ensuring maximal diversity and relevance. "
        f"Return up to {num_recipes} distinct, high-quality recipes that meet these standards."
        " If no suitable recipes exist for some criteria (e.g., too restrictive), gracefully provide the closest matches, explain the shortfall, and never invent or hallucinate results."
        " Do NOT include any explanation, commentary, or extra output—just the result."
    )
    return prompt """

# --- Spice Level Mappings ---
SPICE_LEVEL_DESCRIPTIONS = {
    "No Spice (Plain Jane)":      "No spice (not spicy at all, suitable for children and sensitive palates)",
    "Gentle Warmth (Mild)":       "Mild (very gentle heat, just a little warmth)",
    "Balanced Kick (Medium)":     "Medium (noticeable kick, balanced for most adults)",
    "Bring the Heat (Spicy)":     "Spicy (spicy but not super hot)",
    "RIP (Super Spicy!)":         "Super Spicy (for chili-lovers, ghost pepper level)",
    "Mystery Heat (Surprise me!)": "Any (surprise, any level of heat may be included)",
    "Spice? I'm Open!":           "Any (no preference, all levels welcome)",
}

SPICE_SCALE_MAP = {
    "No Spice (Plain Jane)":      "1",
    "Gentle Warmth (Mild)":       "2-3",
    "Balanced Kick (Medium)":     "4-5",
    "Bring the Heat (Spicy)":     "6-7",
    "RIP (Super Spicy!)":         "8-10",
    "Mystery Heat (Surprise me!)": "1-10",
    "Spice? I'm Open!":           "1-10",
}

def build_recipe_agent_prompt(
    ingredients, max_time, allergies, diets, cuisines, spice_level_label, num_recipes=15
):
    ingredient_str = ", ".join(ingredients)
    allergies_str = ", ".join(allergies or [])
    diets_str = ", ".join(diets or [])
    cuisines_str = ", ".join(cuisines or [])
    spice_description = SPICE_LEVEL_DESCRIPTIONS.get(spice_level_label, "Any (no preference, all levels welcome)")
    spice_numeric = SPICE_SCALE_MAP.get(spice_level_label, "1-10")

    # Safety and robust fallback for spice
    if spice_level_label in {"RIP (Super Spicy!)", "Mystery Heat (Surprise me!)"}:
        spice_caution = (
            "For high or uncertain spice requests (such as 'Super Spicy' or 'Surprise me!'), recommend only authentic recipes that are traditionally served at such heat levels. "
            "NEVER invent or escalate the spice artificially. NEVER propose unsafe challenge dishes or novelty recipes. "
            "If no safe, authentic options are available, reduce the result set and, if necessary, substitute with the closest authentic recipe matching other criteria. "
            "Always avoid recipes where the heat level could present risk or be unsuitable for the general public."
        )
    else:
        spice_caution = (
            "For all other spice levels, select only authentic dishes that naturally correspond to the requested heat. "
            "NEVER assign a higher spice level than requested. Only select recipes that authentically match the user's heat preference using the numeric scale below."
        )

    prompt = (
        "You are a professional AI recipe agent for home cooking. "
        "When interpreting spice requests, use this numeric scale: "
        "1 = No spice at all; 2-3 = Mild; 4-5 = Medium; 6-7 = Spicy; 8-10 = Super Spicy (for chili-lovers); 1-10 = Any. "
        f"Requested spice level: {spice_description} (numeric scale: {spice_numeric}). "
        f"{spice_caution} "
        "Your task is to recommend only genuine, practical, and diverse recipes, strictly adhering to the user's constraints. "
        "Every result must be drawn from reputable, publicly accessible, and verifiable recipe sources online. "
        f"Use ONLY the following as main ingredients: {ingredient_str}. "
        "Do NOT introduce additional ingredients except universally available pantry basics (e.g., water, salt, pepper, oil). "
        f"Exclude any recipe containing these allergens: {allergies_str if allergies_str else 'None specified'}. "
        f"Respect the following dietary requirements: {diets_str if diets_str else 'None specified'}. "
        f"Focus on these cuisines if specified: {cuisines_str if cuisines_str else 'Any cuisine'}. "
        "Do NOT alter recipe names to reflect spice. Use only the real name of the recipe. "
        "Find recipes that are suitable for main course meals (mandatory) and other meal types (optional). "
        f"Total preparation and cooking time per recipe must not exceed {max_time} minutes. "
        "Each returned recipe MUST be a unique, authentic, real-world dish, with a valid, accessible website link from a reputable culinary domain. "
        "Do not repeat, invent, or generalise. If the full number of recipes cannot be found that match ALL criteria, return only those that are fully compliant, ensuring maximal diversity and relevance. "
        f"Return up to {num_recipes} distinct, high-quality recipes that meet these standards. "
        "If no suitable recipes exist for some criteria (e.g., too restrictive), gracefully provide the closest matches, explain the shortfall, and never invent or hallucinate results. "
        "Do NOT include any explanation, commentary, or extra output—just the result."
    )
    return prompt

# For blue debug prints
BLUE = "\033[94m"
RESET = "\033[0m"

def filter_recipes(
    recipes: List[Recipe],
    max_time: Optional[int] = None,
    cuisines: Optional[List[str]] = None,
    diets: Optional[List[str]] = None
) -> List[Recipe]:
    # Define values to ignore for filters
    IGNORED_DIET_VALUES = {"none", "other"}
    IGNORED_CUISINE_VALUES = {"none", "other", "mauritian"}

    # Clean the input filters
    filtered_diets = [d for d in (diets or []) if d and d.strip().lower() not in IGNORED_DIET_VALUES]
    filtered_cuisines = [c for c in (cuisines or []) if c and c.strip().lower() not in IGNORED_CUISINE_VALUES]

    filtered = []
    for recipe in recipes:
        # Filter by max_time
        if max_time is not None and recipe.readyInMinutes is not None:
            if recipe.readyInMinutes > max_time:
                print(f"{BLUE}[DEBUG] Recipe {recipe.id} skipped: readyInMinutes={recipe.readyInMinutes} > max_time={max_time}{RESET}")
                continue

        # Filter by cuisines ONLY if there are valid values
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

        # Passed all filters
        filtered.append(recipe)

    print(f"{BLUE}[DEBUG] Recipes after filtering: {len(filtered)}{RESET}")
    return filtered
