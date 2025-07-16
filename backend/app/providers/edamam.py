import os
import httpx
from typing import List, Dict, Any, Optional

class Edamam:
    def __init__(self):
        self.api_id = os.getenv("EDAMAM_API_ID")
        self.api_key = os.getenv("EDAMAM_API_KEY")
        self.base_url = "https.api.edamam.com/api/recipes/v2"

    async def search(self, ingredients: List[str], max_time: Optional[int] = None, cuisines: Optional[List[str]] = None, diets: Optional[List[str]] = None, allergies: Optional[List[str]] = None) -> List[Dict[str, Any]]:
        if not self.api_id or not self.api_key:
            print("\x1B[34m[DEBUG] Edamam API credentials not found.\x1B[0m")
            return []

        params = {
            "type": "public",
            "q": ", ".join(ingredients),
            "app_id": self.api_id,
            "app_key": self.api_key,
        }
        if max_time:
            params["time"] = f"1-{max_time}"
        if cuisines:
            params["cuisineType"] = cuisines
        if diets:
            params["diet"] = diets
        if allergies:
            params["health"] = allergies

        async with httpx.AsyncClient() as client:
            try:
                print(f"\x1B[34m[DEBUG] Calling Edamam API with params: {params}\x1B[0m")
                response = await client.get(self.base_url, params=params)
                response.raise_for_status()
                data = response.json()
                print(f"\x1B[34m[DEBUG] Edamam API response: {data}\x1B[0m")
                return [self._format_recipe(hit["recipe"]) for hit in data.get("hits", [])]
            except httpx.HTTPStatusError as e:
                print(f"\x1B[31m[ERROR] Edamam API request failed: {e}\x1B[0m")
                return []
            except Exception as e:
                print(f"\x1B[31m[ERROR] An error occurred while calling Edamam API: {e}\x1B[0m")
                return []

    def _format_recipe(self, recipe: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "title": recipe.get("label"),
            "imageUrl": recipe.get("image"),
            "totalTime": recipe.get("totalTime"),
            "ingredients": [{"name": ing.get("food"), "quantity": f"{ing.get('quantity')} {ing.get('measure')}"} for ing in recipe.get("ingredients", [])],
            "instructions": [],  # Edamam does not provide instructions
            "equipment": [],
            "website": recipe.get("url"),
            "videos": [],
            "source": "Edamam",
        }
