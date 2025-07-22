import os
import requests

BLUE = "\033[94m"
RESET = "\033[0m"

class SpoonacularRecipeDetailsProvider:
    """Provider to fetch bulk recipe details from Spoonacular API."""

    def __init__(self, api_key: str = None):
        self.api_key = api_key or os.getenv("SPOONACULAR_API_KEY")
        if not self.api_key:
            print(f"{BLUE}[DEBUG] Spoonacular API key missing!{RESET}")
            raise ValueError("SPOONACULAR_API_KEY not set")
        self.base_url = "https://api.spoonacular.com/recipes/informationBulk"

    def get_bulk_recipe_details(self, ids, include_nutrition=True):
        """
        Fetch full recipe details for a batch of IDs.

        Args:
            ids (List[int]): List of recipe IDs (max 10 per request on free tier)
            include_nutrition (bool): Whether to include nutrition info

        Returns:
            List[dict]: Recipe details as returned by Spoonacular
        """
        params = {
            "ids": ",".join(str(i) for i in ids),
            "includeNutrition": str(include_nutrition).lower(),
            "apiKey": self.api_key,
        }
        print(f"{BLUE}[DEBUG] Fetching bulk recipe info for IDs: {ids}{RESET}")
        response = requests.get(self.base_url, params=params)
        print(f"{BLUE}[DEBUG] Spoonacular bulk info Response: {response.status_code}{RESET}")
        if response.status_code != 200:
            print(f"{BLUE}[DEBUG] Spoonacular bulk error: {response.text}{RESET}")
            response.raise_for_status()
        data = response.json()
        print(f"{BLUE}[DEBUG] Returned {len(data)} full recipes in bulk{RESET}")
        # Optionally print the first recipe for debug
        if data:
            print(f"{BLUE}[DEBUG] Sample full recipe: {data[0]}{RESET}")
        return data
