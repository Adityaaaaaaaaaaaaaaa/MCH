import os
import requests

BLUE = "\033[94m"
YELLOW = "\033[93m"
RESET = "\033[0m"

class SpoonacularRecipeDetailsProvider:
    """Provider to fetch bulk recipe details from Spoonacular API via RapidAPI."""

    def __init__(self, rapidapi_key: str = None):
        self.rapidapi_key = rapidapi_key or os.getenv("RAPIDAPI_KEY")
        if not self.rapidapi_key:
            print(f"{BLUE}[DEBUG] RapidAPI key missing!{RESET}")
            raise ValueError("RAPIDAPI_KEY not set")
        self.base_url = "https://spoonacular-recipe-food-nutrition-v1.p.rapidapi.com/recipes/informationBulk"
        self.headers = {
            "x-rapidapi-key": self.rapidapi_key,
            "x-rapidapi-host": "spoonacular-recipe-food-nutrition-v1.p.rapidapi.com",
        }
        self.last_response_headers = {}

    def _print_rate_limits(self, headers):
        keys = [
            "X-Ratelimit-Classifications-Limit",
            "X-Ratelimit-Classifications-Remaining",
            "X-Ratelimit-Requests-Limit",
            "X-Ratelimit-Requests-Remaining",
            "X-Ratelimit-Tinyrequests-Limit",
            "X-Ratelimit-Tinyrequests-Remaining"
        ]
        print(f"{YELLOW}[RAPIDAPI RATE LIMITS]{RESET}")
        for key in keys:
            if key in headers:
                print(f"{YELLOW}{key}: {headers[key]}{RESET}")

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
        }
        print(f"{BLUE}[DEBUG] Fetching bulk recipe info for IDs: {ids}{RESET}")
        response = requests.get(self.base_url, headers=self.headers, params=params)
        self.last_response_headers = response.headers
        
        print(f"{BLUE}[DEBUG] RapidAPI bulk info Response: {response.status_code}{RESET}")

        # Print rate limit info
        self._print_rate_limits(response.headers)

        if response.status_code != 200:
            print(f"{BLUE}[DEBUG] RapidAPI bulk error: {response.text}{RESET}")
            response.raise_for_status()
        data = response.json()
        print(f"{BLUE}[DEBUG] Returned {len(data)} full recipes in bulk{RESET}")
        if data:
            print(f"{BLUE}[DEBUG] Sample full recipe: {data[0]}{RESET}")
        return data
