import os
import requests

BLUE = "\033[94m"
RESET = "\033[0m"

class SpoonacularProvider:
    """Provider class to interact with Spoonacular API (findByIngredients endpoint)."""

    def __init__(self, api_key: str = None):
        self.api_key = api_key or os.getenv("SPOONACULAR_API_KEY")
        if not self.api_key:
            print(f"{BLUE}[DEBUG] Spoonacular API key is missing!{RESET}")
            raise ValueError("SPOONACULAR_API_KEY not set in environment or passed to SpoonacularProvider")
        self.base_url = "https://api.spoonacular.com/recipes/findByIngredients"

    def find_by_ingredients(self, ingredients, number=10, ranking=2, ignore_pantry=True):
        """
        Fetches recipes from Spoonacular based on a list of ingredients.

        Parameters:
            ingredients (list[str]): Ingredients to search for.
            number (int): Max number of results.
            ranking (int): 1 = maximize used ingredients; 2 = minimize missing.
            ignore_pantry (bool): Whether to ignore pantry items.

        Returns:
            list[dict]: List of recipes as returned by Spoonacular API.
        """
        # Prepare request parameters
        params = {
            "ingredients": ",".join(ingredients),
            "number": number,
            "ranking": ranking,
            "ignorePantry": str(ignore_pantry).lower(),
            "apiKey": self.api_key,
        }

        print(f"{BLUE}[DEBUG] Sending request to Spoonacular API...{RESET}")
        print(f"{BLUE}[DEBUG] Parameters: {params}{RESET}")

        try:
            response = requests.get(self.base_url, params=params)
            print(f"{BLUE}[DEBUG] Spoonacular API Response Code: {response.status_code}{RESET}")
            if response.status_code != 200:
                print(f"{BLUE}[DEBUG] Spoonacular API Error Response: {response.text}{RESET}")
                response.raise_for_status()

            data = response.json()
            print(f"{BLUE}[DEBUG] Spoonacular returned {len(data)} recipes{RESET}")
            # Debug print first recipe for inspection
            if data:
                print(f"{BLUE}[DEBUG] Sample Recipe: {data[0]}{RESET}")
            return data

        except Exception as e:
            print(f"{BLUE}[DEBUG] Exception occurred in SpoonacularProvider: {e}{RESET}")
            raise

