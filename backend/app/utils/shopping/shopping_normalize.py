# app/utils/shopping/shopping_normalize.py
from __future__ import annotations
import os, json, re
from pathlib import Path
from typing import Iterable


# -----------------------------
# Pantry: skip-by-default items
# -----------------------------
PANTRY_SKIP: set[str] = {
    # — water & ice —
    "water", "ice",

    # — salts & peppers —
    "salt", "table salt", "kosher salt", "sea salt", "himalayan salt",
    "black pepper", "white pepper", "pepper", "peppercorns",
    "ground black pepper", "ground white pepper",

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
    "balsamic vinegar", "lemon juice", "lime juice", "vinegar",

    # — very common sauces/condiments —
    "soy sauce", "light soy sauce", "dark soy sauce",
    "fish sauce", "oyster sauce", "worcestershire sauce",
    "hot sauce", "sriracha", "ketchup", "mustard", "mayonnaise",
    "chili sauce", "chilli sauce",

    # — stocks/broths/bases —
    "chicken stock", "vegetable stock", "beef stock",
    "chicken broth", "vegetable broth", "beef broth",
    "stock", "broth",

    # — basic dried spices & blends —
    "turmeric", "turmeric powder",
    "cumin", "ground cumin", "cumin powder",
    "coriander", "ground coriander", "coriander powder",
    "paprika", "smoked paprika", "red chili powder", "chili powder",
    "kashmiri chili powder", "garam masala", "curry powder",

    # — baking basics —
    "all-purpose flour", "plain flour", "maida", "self rising flour", "self-raising flour",
    "baking powder", "baking soda", "bicarbonate of soda",
    "cornstarch", "cornflour", "corn starch",
    "yeast", "active dry yeast", "instant yeast",
    "vanilla extract", "cocoa powder",

    # — staple carbs —
    "white rice", "rice", "basmati rice", "jasmine rice",
    "pasta", "spaghetti", "penne", "macaroni", "noodles",

    # — common aromatics (optional skip) —
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
DESCRIPTOR_STOPWORDS: set[str] = {
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

    # container-ish / vague qty
    "can", "tin", "jar", "bottle", "pack", "packet",
    "about", "approx", "approximately", "around", "roughly",

    # unit-ish nouns we want to drop in names
    "clove", "cloves",
    "piece", "pieces",
    "slice", "slices",
}

# ------------------------------------
# Synonyms / Normalization map
# ------------------------------------
SYNONYM_MAP: dict[str, str] = {
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

    # tomato / potato / eggs
    "tomatoes": "tomato",
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
    "cream cheese": "cream cheese",

    # flours/starches
    "plain flour": "all-purpose flour",
    "maida": "all-purpose flour",
    "atta": "whole wheat flour",
    "self raising flour": "self-raising flour",
    "self-rising flour": "self-raising flour",
    "cornflour": "cornstarch",
    "corn starch": "cornstarch",

    # sugars
    "castor sugar": "caster sugar",

    # coconut milk variants
    "full fat coconut milk": "coconut milk",
    "full-fat coconut milk": "coconut milk",

    # chicken cut variants (collapse to 'chicken')
    "chicken breast": "chicken",
    "chicken breasts": "chicken",
    "chicken thigh": "chicken",
    "chicken thighs": "chicken",

    # helpful recent hits
    "garlic clove": "garlic",
    "garlic cloves": "garlic",
    "broccoli florets": "broccoli",
    "button mushrooms": "mushroom",

    # your extra fruit entries
    "apples": "apple",
    "granny smith apples": "apple",
    "fuji apples": "apple",
}

# ----------------------
# Core functions
# ----------------------
_whitespace_re = re.compile(r"\s+")

def _strip_descriptors(tokens: Iterable[str]) -> list[str]:
    return [t for t in tokens if t and t not in DESCRIPTOR_STOPWORDS]

def normalize_name(raw: str) -> str:
    """
    Normalize an ingredient name to improve matching:
      - lowercase
      - remove punctuation except hyphens/apostrophes inside words
      - collapse spaces
      - drop descriptor stopwords
      - apply synonym map
    """
    s = raw.strip().lower()
    # keep letters, digits, spaces, hyphen and apostrophe
    s = re.sub(r"[^a-z0-9\s\-\']", " ", s)
    s = _whitespace_re.sub(" ", s).strip()

    # token-strip descriptors
    tokens = _strip_descriptors(s.split(" "))
    s = " ".join(tokens)

    # collapse multiple spaces again
    s = _whitespace_re.sub(" ", s).strip()

    # synonym map pass (exact match)
    if s in SYNONYM_MAP:
        s = SYNONYM_MAP[s]

    return s

def is_pantry(name_normalized: str) -> bool:
    """Return True if the normalized ingredient is in the skip list."""
    return name_normalized in PANTRY_SKIP

def extend_pantry(extra: Iterable[str]) -> None:
    """Optionally extend pantry list at runtime (e.g., per user)."""
    for x in extra:
        if not x:
            continue
        PANTRY_SKIP.add(normalize_name(x))

def add_synonyms(pairs: dict[str, str]) -> None:
    """Optionally extend synonym map at runtime."""
    for k, v in pairs.items():
        if not k or not v:
            continue
        SYNONYM_MAP[normalize_name(k)] = normalize_name(v)
        

BLUE = "\x1B[34m"; RESET = "\x1B[0m"
def _blue(x: str) -> None: print(f"{BLUE}{x}{RESET}")

_whitespace_re = re.compile(r"\s+")

def _strip_descriptors(tokens: Iterable[str]) -> list[str]:
    return [t for t in tokens if t and t not in DESCRIPTOR_STOPWORDS]

def normalize_name(raw: str) -> str:
    s = raw.strip().lower()
    s = re.sub(r"[^a-z0-9\s\-\']", " ", s)
    s = _whitespace_re.sub(" ", s).strip()
    tokens = _strip_descriptors(s.split(" "))
    s = " ".join(tokens)
    s = _whitespace_re.sub(" ", s).strip()
    if s in SYNONYM_MAP:
        s = SYNONYM_MAP[s]
    return s

def is_pantry(name_normalized: str) -> bool:
    return name_normalized in PANTRY_SKIP

def extend_pantry(extra: Iterable[str]) -> None:
    for x in extra:
        if not x:
            continue
        PANTRY_SKIP.add(normalize_name(x))

def add_synonyms(pairs: dict[str, str]) -> None:
    for k, v in pairs.items():
        if not k or not v:
            continue
        SYNONYM_MAP[normalize_name(k)] = normalize_name(v)

# --------------------------------------------------------------------
# OFF alias loader (auto-merge large map without overriding your own)
# --------------------------------------------------------------------
_OFF_LOADED = False

def _default_off_path() -> Path:
    # this file lives at app/utils/shopping/shopping_normalize.py
    # we want app/data/off_ingredients_alias_map.en.json
    return Path(__file__).resolve().parents[2] / "data" / "off_ingredients_alias_map.en.json"

def ensure_off_aliases_loaded(path: str | os.PathLike | None = None) -> None:
    """
    One-time merge of OFF alias map into SYNONYM_MAP.
    - Skips if OFF_ALIASES_DISABLE=1
    - Uses OFF_ALIASES_PATH if set, otherwise app/data/off_ingredients_alias_map.en.json
    - Manual SYNONYM_MAP entries take precedence; OFF only fills gaps.
    """
    global _OFF_LOADED
    if _OFF_LOADED:
        return
    if os.getenv("OFF_ALIASES_DISABLE", "").strip() in {"1", "true", "True"}:
        _blue("[OFF] alias loading disabled via OFF_ALIASES_DISABLE")
        _OFF_LOADED = True
        return

    p = Path(os.getenv("OFF_ALIASES_PATH") or path or _default_off_path())
    try:
        with p.open("r", encoding="utf-8") as f:
            off_map: dict[str, str] = json.load(f)
    except FileNotFoundError:
        _blue(f"[OFF] alias file not found, skipping: {p}")
        _OFF_LOADED = True
        return
    except Exception as e:
        _blue(f"[OFF] error reading alias file ({p}): {e}; continuing without it")
        _OFF_LOADED = True
        return

    # Merge (manual synonyms win)
    added = 0
    for k, v in off_map.items():
        kk = (k or "").strip().lower()
        vv = (v or "").strip().lower()
        if not kk or not vv:
            continue
        if kk not in SYNONYM_MAP:
            SYNONYM_MAP[kk] = vv
            added += 1

    _blue(f"[OFF] alias map merged: +{added} entries (manual kept: {len(SYNONYM_MAP)}) from {p}")
    _OFF_LOADED = True

# auto-load at import (safe & idempotent)
ensure_off_aliases_loaded()
