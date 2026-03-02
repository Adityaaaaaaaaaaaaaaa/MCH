import os
import requests

RAPIDAPI_HOST = "spoonacular-recipe-food-nutrition-v1.p.rapidapi.com"
MEALPLANNER_URL = f"https://{RAPIDAPI_HOST}/recipes/mealplans/generate"

def generate_day_plan(*, diet=None, exclude_csv=None, target_calories=None):
    """
    Call Spoonacular to generate a **single day** (3 meals).
    Returns: { ok: True, data: {...} } OR { ok: False, status, error, body }
    """
    api_key = os.getenv("RAPIDAPI_KEY")
    if not api_key:
        return {"ok": False, "status": 500, "error": "RAPIDAPI_KEY not configured"}

    params = {"timeFrame": "day"}
    if diet:
        params["diet"] = diet
    if exclude_csv:
        params["exclude"] = exclude_csv
    if target_calories:
        params["targetCalories"] = target_calories

    headers = {
        "x-rapidapi-key": api_key,
        "x-rapidapi-host": RAPIDAPI_HOST,
    }

    try:
        r = requests.get(MEALPLANNER_URL, headers=headers, params=params, timeout=30)
        if r.status_code != 200:
            return {"ok": False, "status": r.status_code, "error": "Upstream error", "body": r.text}
        data = r.json()
        # Expect: { name, publishAsPublic?, items: [ {slot, value(json-string), ...} ] }
        return {"ok": True, "data": data}
    except Exception as ex:
        return {"ok": False, "status": 502, "error": f"Request failed: {ex}"}
