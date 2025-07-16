import httpx
from typing import List, Dict, Any, Optional

class MealDB:
    def __init__(self):
        self.base_url = "https://www.themealdb.com/api/json/v1/1/filter.php"
        self.lookup_url = "https://www.themealdb.com/api/json/v1/1/lookup.php"

    async def search(self, ingredients: List[str], **kwargs) -> List[Dict[str, Any]]:
        all_recipes = []
        async with httpx.AsyncClient() as client:
            for ingredient in ingredients:
                try:
                    print(f"\x1B[34m[DEBUG] Calling MealDB API with ingredient: {ingredient}\x1B[0m")
                    response = await client.get(self.base_url, params={"i": ingredient})
                    response.raise_for_status()
                    data = response.json()
                    print(f"\x1B[34m[DEBUG] MealDB API response for {ingredient}: {data}\x1B[0m")
                    if data.get("meals"):
                        for meal in data["meals"]:
                            recipe_detail = await self._get_recipe_details(client, meal["idMeal"])
                            if recipe_detail:
                                all_recipes.append(self._format_recipe(recipe_detail))
                except httpx.HTTPStatusError as e:
                    print(f"\x1B[31m[ERROR] MealDB API request failed: {e}\x1B[0m")
                except Exception as e:
                    print(f"\x1B[31m[ERROR] An error occurred while calling MealDB API: {e}\x1B[0m")
        return all_recipes

    async def _get_recipe_details(self, client: httpx.AsyncClient, meal_id: str) -> Optional[Dict[str, Any]]:
        try:
            response = await client.get(self.lookup_url, params={"i": meal_id})
            response.raise_for_status()
            data = response.json()
            return data["meals"][0] if data.get("meals") else None
        except httpx.HTTPStatusError as e:
            print(f"\x1B[31m[ERROR] MealDB API lookup request failed: {e}\x1B[0m")
            return None
        except Exception as e:
            print(f"\x1B[31m[ERROR] An error occurred while calling MealDB API lookup: {e}\x1B[0m")
            return None

    def _format_recipe(self, recipe: Dict[str, Any]) -> Dict[str, Any]:
        ingredients = []
        for i in range(1, 21):
            ing = recipe.get(f"strIngredient{i}")
            measure = recipe.get(f"strMeasure{i}")
            if ing and ing.strip():
                ingredients.append({"name": ing, "quantity": measure})

        return {
            "title": recipe.get("strMeal"),
            "imageUrl": recipe.get("strMealThumb"),
            "totalTime": None,  # MealDB does not provide total time
            "ingredients": ingredients,
            "instructions": recipe.get("strInstructions", "").split("\r\n"),
            "equipment": [],
            "website": recipe.get("strSource"),
            "videos": [recipe.get("strYoutube")],
            "source": "MealDB",
        }
