# app/utils/shopping.py
from typing import List, Dict, Any, Tuple
import re

BLUE = "\x1B[34m"; RESET = "\x1B[0m"
def _blue(msg: str) -> None:
    print(f"{BLUE}{msg}{RESET}")

# app/utils/shopping.py (replace just these constant blocks)

# -----------------------------
# Pantry: skip-by-default items
# -----------------------------
# NOTE: Keep this conservative. If you *do* want these to appear in shopping,
# remove from this set. Everything here is something most kitchens keep around.
PANTRY_SKIP = {
    # — water & ice —
    "water", "ice",

    # — salts & peppers —
    "salt", "table salt", "kosher salt", "sea salt", "himalayan salt",
    "black pepper", "white pepper", "pepper", "peppercorns",

    # — common oils & fats —
    "vegetable oil", "olive oil", "extra virgin olive oil", "canola oil",
    "sunflower oil", "peanut oil", "corn oil", "rapeseed oil",
    "ghee", "butter", "unsalted butter", "salted butter",
    "cooking spray", "sesame oil",

    # — common sweeteners —
    "sugar", "granulated sugar", "caster sugar", "superfine sugar",
    "brown sugar", "light brown sugar", "dark brown sugar",
    "powdered sugar", "confectioners sugar", "icing sugar",
    "palm sugar", "jaggery", "honey", "maple syrup",

    # — vinegars & acids —
    "white vinegar", "distilled vinegar", "apple cider vinegar",
    "rice vinegar", "red wine vinegar", "white wine vinegar",
    "balsamic vinegar", "lemon juice", "lime juice",

    # — very common sauces/condiments —
    "soy sauce", "light soy sauce", "dark soy sauce",
    "fish sauce", "oyster sauce", "worcestershire sauce",
    "hot sauce", "sriracha", "ketchup", "mustard", "mayonnaise",
    "vinegar", "chili sauce", "chilli sauce",

    # — stocks/broths/bases —
    "chicken stock", "vegetable stock", "beef stock",
    "chicken broth", "vegetable broth", "beef broth",
    "stock", "broth",

    # — basic dried spices & blends (ubiquitous pantry) —
    "turmeric", "turmeric powder",
    "cumin", "ground cumin", "cumin powder",
    "coriander", "ground coriander", "coriander powder",
    "paprika", "smoked paprika", "red chili powder", "chili powder",
    "kashmiri chili powder", "garam masala", "curry powder",
    "ground black pepper", "ground white pepper",

    # — baking basics —
    "all-purpose flour", "plain flour", "maida", "self rising flour", "self-raising flour",
    "baking powder", "baking soda", "bicarbonate of soda",
    "cornstarch", "cornflour", "corn starch",
    "yeast", "active dry yeast", "instant yeast",
    "vanilla extract", "cocoa powder",

    # — staple carbs (often present; tweak if you want them to show) —
    "white rice", "rice", "basmati rice", "jasmine rice",
    "pasta", "spaghetti", "penne", "macaroni", "noodles",

    # — common aromatics (optional skip; comment out if you want them listed) —
    "garlic", "ginger",
    "onion", "red onion", "white onion", "yellow onion",
    "green onion", "spring onion", "scallion",

    # — common canned basics (optional) —
    "tomato paste", "tomato puree", "passata", "crushed tomatoes",
    "canned tomatoes",
}

# --------------------------------
# Descriptors: strip from names
# --------------------------------
# Words that describe cut, state, quality, or serving notes but not the *thing*.
DESCRIPTOR_STOPWORDS = {
    # cut/prep
    "finely", "roughly", "thinly", "thickly", "chopped", "minced", "sliced",
    "diced", "grated", "julienned", "crushed", "ground", "paste",
    "wedges", "chunks", "matchsticks", "ribbons",

    # state/freshness/size
    "fresh", "frozen", "canned", "tinned", "jarred", "dried", "dry", "ripe",
    "boneless", "skinless", "bone-in", "skin-on",
    "large", "small", "medium", "extra-large",
    "seeded", "de-seeded", "deseeded", "peeled", "trimmed",
    "room-temperature", "room", "temperature", "roomtemp", "cool", "warm", "cold",

    # quality/fat/salt descriptors
    "full-fat", "low-fat", "reduced-fat", "light", "unsalted", "salted",
    "extra", "virgin", "extra-virgin", "evoo", "melted", "softened",

    # serving/garnish verbiage
    "optional", "for", "garnish", "garnishing", "to", "taste", "to-taste",
    "for-serving", "for serving", "for garnish",

    # container-ish
    "canned", "can", "tin", "jar", "bottle", "pack", "packet",

    # vague quantity qualifiers
    "about", "approx", "approximately", "around", "roughly",
    
    "clove", "cloves",
    "piece", "pieces",
    "slice", "slices",
}

# ------------------------------------
# Synonyms / Normalization map
# ------------------------------------
# Keep these specific and *safe*. Goal: bridge common naming differences,
# not collapse distinct ingredients.
SYNONYM_MAP = {
    # peppers / capsicum
    "capsicum": "bell pepper",
    "bell peppers": "bell pepper",
    "red bell pepper": "bell pepper",
    "green bell pepper": "bell pepper",
    "yellow bell pepper": "bell pepper",

    # onions / scallions
    "spring onion": "scallion",
    "spring onions": "scallion",
    "green onion": "scallion",
    "green onions": "scallion",
    "scallions": "scallion",

    # herbs
    "coriander leaves": "cilantro",
    "fresh coriander": "cilantro",
    "cilantro leaves": "cilantro",
    "dhaniya leaves": "cilantro",

    # chillies spellings
    "chili": "chilli",
    "chile": "chilli",
    "chilies": "chilli",
    "chilis": "chilli",
    "green chilies": "chilli",
    "red chilies": "chilli",

    # tomato
    "tomatoes": "tomato",

    # potatoes / eggs
    "potatoes": "potato",
    "eggs": "egg",
    "egg whites": "egg white",
    "egg yolks": "egg yolk",

    # eggplant / zucchini
    "aubergine": "eggplant",
    "aubergines": "eggplant",
    "courgette": "zucchini",
    "courgettes": "zucchini",

    # greens
    "rocket": "arugula",

    # corn
    "sweet corn": "corn",
    "corn kernels": "corn",

    # beans/legumes (safe pairs)
    "garbanzo beans": "chickpeas",
    "garbanzo": "chickpeas",
    "kabuli chana": "chickpeas",

    # dairy
    "yoghurt": "yogurt",
    "curd": "yogurt",
    "cream cheese": "cream cheese",  # identity, for completeness

    # flours/starches
    "plain flour": "all-purpose flour",
    "maida": "all-purpose flour",
    "atta": "whole wheat flour",
    "self raising flour": "self-raising flour",
    "self-rising flour": "self-raising flour",
    "cornflour": "cornstarch",       # UK -> US
    "corn starch": "cornstarch",

    # sugars
    "castor sugar": "caster sugar",

    # coconut milk variants
    "full fat coconut milk": "coconut milk",
    "full-fat coconut milk": "coconut milk",

    # chicken cut variants (collapse to 'chicken' so inventory 'chicken' matches)
    "chicken breast": "chicken",
    "chicken breasts": "chicken",
    "chicken thigh": "chicken",
    "chicken thighs": "chicken",
    
    "garlic clove": "garlic",
    "garlic cloves": "garlic",
    "broccoli florets": "broccoli",
    "button mushrooms": "mushroom",
}


_WORD_RE = re.compile(r"[A-Za-z]+(?:'[A-Za-z]+)?")

def _singularize(word: str) -> str:
    """
    very light, dependency-free singularization to catch common cases.
    """
    w = word
    if w.endswith("ies") and len(w) > 3:
        return w[:-3] + "y"        # tomatoes -> tomatoy (no), but 'berries'->'berry'. We'll special-case tomatoes below.
    if w.endswith("oes") and len(w) > 3:
        return w[:-2]              # tomatoes -> tomato
    if w.endswith("ses") and len(w) > 3:
        return w[:-2]              # sauces -> sauce
    if w.endswith("s") and len(w) > 3 and not w.endswith("ss"):
        return w[:-1]              # onions -> onion
    return w

def _strip_parens_and_punct(s: str) -> str:
    # remove text in parentheses
    s = re.sub(r"\([^)]*\)", " ", s)
    # replace non-letters with spaces, keep apostrophes inside words
    tokens = _WORD_RE.findall(s.lower())
    return " ".join(tokens)

def _remove_descriptors(tokens: List[str]) -> List[str]:
    return [t for t in tokens if t not in DESCRIPTOR_STOPWORDS]

def _apply_synonyms(normalized: str) -> str:
    # direct mapping first
    if normalized in SYNONYM_MAP:
        return SYNONYM_MAP[normalized]
    # also try word-wise mapping, then rebuild
    words = normalized.split()
    words = [SYNONYM_MAP.get(w, w) for w in words]
    return " ".join(words).strip()

def _normalize_name(raw: str) -> str:
    """
    Pipeline:
    - lowercase, strip parentheses & punctuation
    - remove descriptors
    - simple singularization for each token
    - collapse spaces
    - apply synonym map
    """
    s = _strip_parens_and_punct(raw)
    toks = s.split()
    toks = _remove_descriptors(toks)
    toks = [_singularize(t) for t in toks]
    s = " ".join(toks).strip()
    # special-case a few irregular plurals after token step
    s = s.replace("tomatoes", "tomato").replace("potatoes", "potato")
    s = _apply_synonyms(s)
    return s.strip()

def _index_inventory(inv: List[Dict[str, Any]]) -> Dict[Tuple[str, str], float]:
    """
    Build index keyed by (normalized_name, unit) -> total quantity.
    We keep units separate (no cross-unit math yet).
    """
    idx: Dict[Tuple[str, str], float] = {}
    for it in inv:
        raw_name = str(it.get("name", "")).strip()
        unit = str(it.get("unit", "count") or "count").strip().lower()
        qty  = float(it.get("quantity", 0.0) or 0.0)
        norm = _normalize_name(raw_name)
        if norm:
            key = (norm, unit)
            idx[key] = idx.get(key, 0.0) + qty
            if norm != raw_name.lower():
                _blue(f"[Shopping][normalize] inv '{raw_name}' -> '{norm}'")
    return idx

def _should_skip_pantry(name: str) -> bool:
    norm = _normalize_name(name)
    if norm in PANTRY_SKIP:
        _blue(f"[Shopping] (skip pantry) {name} — normalized '{norm}'")
        return True
    return False

def _compute_missing_for_recipe(required: List[Dict[str, Any]], inv_index: Dict[Tuple[str, str], float]) -> List[Dict[str, Any]]:
    """
    For each required ingredient: normalize name, skip pantry if configured,
    compare against inventory by (normalized_name, unit).
    """
    out: List[Dict[str, Any]] = []
    for req in required:
        raw_name = str(req.get("name", "")).strip()
        if not raw_name:
            continue
        unit = str(req.get("unit", "count") or "count").strip().lower()
        need = float(req.get("quantity", 0.0) or 0.0)

        # pantry gate
        if _should_skip_pantry(raw_name):
            continue

        norm_name = _normalize_name(raw_name)
        have = float(inv_index.get((norm_name, unit), 0.0))
        miss = max(0.0, need - have)
        tag  = "buy" if have == 0 else ("missing" if miss > 0 else "")

        if miss > 0:
            out.append({
                "name": raw_name,     # keep original for display
                "need": need,
                "unit": unit,
                "have": have,
                "tag": tag,           # "buy" | "missing"
                "normalized": norm_name,  # optional: useful for debugging/analytics
            })
    return out

def attach_shopping_to_candidates(*, candidates: List[Dict[str, Any]], inventory: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Returns a *new* list of candidates with a 'shopping' field added.
    Does not mutate the original list.
    """
    inv_index = _index_inventory(inventory)
    _blue(f"[Shopping] Inventory indexed: {len(inventory)} names")

    enriched: List[Dict[str, Any]] = []
    for c in candidates:
        req_ing = c.get("required_ingredients", []) or []
        shopping = _compute_missing_for_recipe(req_ing, inv_index)
        _blue(f"[Shopping] {c.get('title', 'Recipe')}: {len(shopping)} items to buy/missing")
        enriched.append({**c, "shopping": shopping})
    return enriched
