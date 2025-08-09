# app/providers/week_plan_generate.py

import os
import requests
from typing import Dict, Any, Optional

BLUE = "\x1B[34m"
RESET = "\x1B[0m"

RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY")

# RapidAPI host must be the host ONLY (no scheme, no path)
RAPIDAPI_HOST = "spoonacular-recipe-food-nutrition-v1.p.rapidapi.com"
BASE_URL = f"https://{RAPIDAPI_HOST}"

# RapidAPI console snippet uses this path:
MEALPLAN_PATH = "/recipes/mealplans/generate"
# If needed, you can try the alternative path below (some accounts prefer this):
# MEALPLAN_PATH = "/mealplanner/generate"

def _headers() -> Dict[str, str]:
    if not RAPIDAPI_KEY:
        print(f"{BLUE}[DEBUG] RAPIDAPI_KEY missing in environment{RESET}")
    return {
        "x-rapidapi-key": RAPIDAPI_KEY or "",
        "x-rapidapi-host": RAPIDAPI_HOST,
    }

def _print_rate_limits(resp: requests.Response) -> None:
    h = resp.headers or {}
    limit = h.get("x-ratelimit-requests-limit")
    remaining = h.get("x-ratelimit-requests-remaining")
    reset = h.get("x-ratelimit-requests-reset")
    credits = h.get("x-ratelimit-credits-remaining") or h.get("x-ratelimit-credits-limit")
    print(f"{BLUE}[DEBUG] RapidAPI rate: remaining={remaining}/{limit}, reset={reset}, credits={credits}{RESET}")

def generate_week_plan(
    *,
    time_frame: str = "week",
    diet: Optional[str] = None,
    exclude_csv: Optional[str] = None,
    target_calories: Optional[int] = None,
    timeout: int = 30,
) -> Dict[str, Any]:
    """
    Calls Spoonacular via RapidAPI to generate a meal plan.
    Returns a dict: {ok: bool, status: int, data|error|body: ...}
    """
    url = f"{BASE_URL}{MEALPLAN_PATH}"
    params: Dict[str, Any] = {"timeFrame": time_frame}

    # Only include meaningful parameters
    if diet:
        params["diet"] = diet
    if exclude_csv:
        params["exclude"] = exclude_csv
    if target_calories is not None:
        params["targetCalories"] = target_calories

    print(f"{BLUE}[DEBUG] GET {url} params={params}{RESET}")

    resp = requests.get(url, headers=_headers(), params=params, timeout=timeout)
    _print_rate_limits(resp)
    
    print(f"{BLUE}[DEBUG] Raw response text:\n{resp.text[:1000]}...[trimmed]{RESET}")

    if resp.status_code != 200:
        print(f"{BLUE}[DEBUG] Spoonacular error {resp.status_code}: {resp.text[:400]}...[trimmed]{RESET}")
        return {
            "ok": False,
            "status": resp.status_code,
            "error": "Spoonacular generate failed",
            "body": resp.text,
        }

    try:
        data = resp.json()
        return {"ok": True, "status": 200, "data": data}
    except Exception as ex:
        print(f"{BLUE}[DEBUG] JSON parse error: {ex}{RESET}")
        return {"ok": False, "status": 502, "error": "Invalid JSON from Spoonacular", "body": resp.text}
