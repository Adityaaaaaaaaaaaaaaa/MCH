import os
import requests

BLUE = "\033[94m"
YELLOW = "\033[93m"
RESET = "\033[0m"

class SpoonacularProvider:
    """Provider class to interact with Spoonacular API via RapidAPI."""

    def __init__(self, rapidapi_key: str = None):
        self.rapidapi_key = rapidapi_key or os.getenv("RAPIDAPI_KEY")
        if not self.rapidapi_key:
            print(f"{BLUE}[DEBUG] RapidAPI key is missing!{RESET}")
            raise ValueError("RAPIDAPI_KEY not set in environment or passed to SpoonacularProvider")
        self.base_url = "https://spoonacular-recipe-food-nutrition-v1.p.rapidapi.com/recipes/findByIngredients"
        self.headers = {
            "x-rapidapi-key": self.rapidapi_key,
            "x-rapidapi-host": "spoonacular-recipe-food-nutrition-v1.p.rapidapi.com",
        }
        self.last_response_headers = {}

    def _print_rate_limits(self, headers):
        """Print RapidAPI rate limit headers in yellow."""
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

    def find_by_ingredients(self, ingredients, number=10, ranking=2, ignore_pantry=True):
        params = {
            "ingredients": ",".join(ingredients),
            "number": number,
            "ranking": ranking,
            "ignorePantry": str(ignore_pantry).lower(),
        }
        print(f"{BLUE}[DEBUG] Sending request to RapidAPI Spoonacular endpoint...{RESET}")
        print(f"{BLUE}[DEBUG] Parameters: {params}{RESET}")

        try:
            response = requests.get(self.base_url, headers=self.headers, params=params)
            self.last_response_headers = response.headers
            
            print(f"{BLUE}[DEBUG] RapidAPI Response Code: {response.status_code}{RESET}")

            # Print RapidAPI rate limits in yellow
            self._print_rate_limits(response.headers)

            if response.status_code != 200:
                print(f"{BLUE}[DEBUG] RapidAPI Error Response: {response.text}{RESET}")
                response.raise_for_status()

            data = response.json()
            print(f"{BLUE}[DEBUG] RapidAPI returned {len(data)} recipes{RESET}")
            if data:
                print(f"{BLUE}[DEBUG] Sample Recipe: {data[0]}{RESET}")
            return data

        except Exception as e:
            print(f"{BLUE}[DEBUG] Exception occurred in SpoonacularProvider: {e}{RESET}")
            raise
