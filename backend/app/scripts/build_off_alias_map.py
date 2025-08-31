from __future__ import annotations
import json, sys
from pathlib import Path
from app.utils.shopping.shopping_normalize import normalize_name

BLUE = "\x1B[34m"; RESET = "\x1B[0m"
def _blue(x): print(f"{BLUE}{x}{RESET}")

def build_alias_map(off_json: dict, langs=("en",)) -> dict[str, str]:
    alias_map: dict[str, str] = {}
    nodes: dict = off_json  # OFF taxo: { "en:apple": {...}, ... }

    for key, node in nodes.items():
        if not any(key.startswith(f"{lc}:") for lc in langs):
            continue

        names = node.get("name") or {}
        canonical_raw = None
        for lc in langs:
            if lc in names:
                canonical_raw = names[lc]
                break
        if not canonical_raw:
            continue

        canonical = normalize_name(canonical_raw)
        if not canonical:
            continue

        # Collect aliases (primary name + synonyms) for our languages
        aliases = set()
        for lc in langs:
            n = names.get(lc)
            if isinstance(n, str):
                aliases.add(n)
            syns = node.get("synonyms", {}).get(lc, [])
            if isinstance(syns, list):
                aliases.update(syns)

        for a in aliases:
            na = normalize_name(a)
            if not na or na == canonical:
                continue
            # keep your curated synonyms dominant: don't overwrite if present later
            alias_map.setdefault(na, canonical)

    return alias_map

def main(path_in: str, path_out: str):
    p_in = Path(path_in); p_out = Path(path_out)
    off = json.loads(p_in.read_text(encoding="utf-8"))
    alias_map = build_alias_map(off, langs=("en",))
    p_out.parent.mkdir(parents=True, exist_ok=True)
    p_out.write_text(json.dumps(alias_map, ensure_ascii=False, indent=2), encoding="utf-8")
    _blue(f"[OFF] alias map built: {len(alias_map):,} entries → {p_out}")

if __name__ == "__main__":
    # Usage:
    # python scripts/build_off_alias_map.py app/data/ingredients.full.json app/data/off_ingredients_alias_map.en.json
    main(sys.argv[1], sys.argv[2])
