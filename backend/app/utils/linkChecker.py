import httpx
import asyncio

class LinkChecker:
    async def validate_url(self, url: str) -> bool:
        if not url:
            return False
        try:
            async with httpx.AsyncClient(follow_redirects=True) as client:
                print(f"\x1B[34m[DEBUG] Validating URL: {url}\x1B[0m")
                response = await client.head(url, timeout=10)
                print(f"\x1B[34m[DEBUG] URL: {url}, Status Code: {response.status_code}\x1B[0m")
                return response.status_code == 200
        except httpx.RequestError as e:
            print(f"\x1B[31m[ERROR] URL validation failed for {url}: {e}\x1B[0m")
            return False
        except Exception as e:
            print(f"\x1B[31m[ERROR] An unexpected error occurred during URL validation for {url}: {e}\x1B[0m")
            return False

    async def filter_valid_recipes(self, recipes):
        valid_recipes = []
        tasks = [self.validate_url(recipe.get("website")) for recipe in recipes]
        results = await asyncio.gather(*tasks)
        for i, is_valid in enumerate(results):
            if is_valid:
                valid_recipes.append(recipes[i])
        return valid_recipes
