import os
import httpx
from typing import List, Dict, Any, Optional

class Spoonacular:
    def __init__(self):
        self.api_key = os.getenv("SPOONACULAR_API_KEY")
        self.base_url = "https://api.spoonacular.com/recipes/complexSearch"
        self.recipe_info_url = "https://api.spoonacular.com/recipes/{id}/information"

    async def search(self, ingredients: List[str], max_time: Optional[int] = None, cuisines: Optional[List[str]] = None, diets: Optional[List[str]] = None, allergies: Optional[List[str]] = None) -> List[Dict[str, Any]]:
        if not self.api_key:
            print("\x1B[34m[DEBUG] Spoonacular API key not found.\x1B[0m")
            return []

        params = {
            "apiKey": self.api_key,
            "includeIngredients": ", ".join(ingredients),
            "number": 10,
            "addRecipeInformation": True,
            "fillIngredients": True,
        }
        if max_time:
            params["maxReadyTime"] = max_time
        if cuisines:
            params["cuisine"] = ", ".join(cuisines)
        if diets:
            params["diet"] = ", ".join(diets)
        if allergies:
            params["intolerances"] = ", ".join(allergies)

        async with httpx.AsyncClient() as client:
            try:
                print(f"\x1B[34m[DEBUG] Calling Spoonacular API with params: {params}\x1B[0m")
                response = await client.get(self.base_url, params=params)
                response.raise_for_status()
                data = response.json()
                print(f"\x1B[34m[DEBUG] Spoonacular API response: {data}\x1B[0m")
                return [self._format_recipe(recipe) for recipe in data.get("results", [])]
            except httpx.HTTPStatusError as e:
                print(f"\x1B[31m[ERROR] Spoonacular API request failed: {e}\x1B[0m")
                return []
            except Exception as e:
                print(f"\x1B[31m[ERROR] An error occurred while calling Spoonacular API: {e}\x1B[0m")
                return []

    def _format_recipe(self, recipe: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "title": recipe.get("title"),
            "imageUrl": recipe.get("image"),
            "totalTime": recipe.get("readyInMinutes"),
            "ingredients": [{"name": ing.get("name"), "quantity": f"{ing.get('amount')} {ing.get('unit')}"} for ing in recipe.get("extendedIngredients", [])],
            "instructions": [step["step"] for step in recipe.get("analyzedInstructions", [])[0].get("steps", [])] if recipe.get("analyzedInstructions") else [],
            "equipment": list(set(item["name"] for step in recipe.get("analyzedInstructions", [])[0].get("steps", []) for item in step.get("equipment", []))) if recipe.get("analyzedInstructions") else [],
            "website": recipe.get("sourceUrl"),
            "videos": [],
            "source": "Spoonacular",
        }
