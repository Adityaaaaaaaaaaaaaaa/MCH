from fastapi import APIRouter, HTTPException, Request
from typing import List, Optional, Any
from app.models.recipe import Recipe, RecipeSearchRequest, RecipeSearchResponse
from app.providers.spoonacular.spoonacular import SpoonacularProvider
from app.providers.spoonacular.spoonacular_recipe_details import SpoonacularRecipeDetailsProvider
from app.utils.utils import filter_recipes, print_rate_limits
import time

# For blue debug prints
BLUE = "\033[94m"
RESET = "\033[0m"

router = APIRouter()

@router.post("/searchByIngredients", response_model=RecipeSearchResponse)
async def search_by_ingredients(payload: RecipeSearchRequest, request: Request):
    try:
        print(f"{BLUE}[DEBUG] Request received for Spoonacular ingredient search{RESET}")
        print(f"{BLUE}[DEBUG] Payload: {payload}{RESET}")

        provider = SpoonacularProvider()
        details_provider = SpoonacularRecipeDetailsProvider()

        # Step 1: Find by ingredients (partial recipes)
        print(f"{BLUE}[DEBUG] Calling SpoonacularProvider.find_by_ingredients(){RESET}")
        recipes_data = provider.find_by_ingredients(
            ingredients=payload.ingredients,
            number=99
        )

        print(f"{BLUE}[DEBUG] Partial recipes received: {len(recipes_data)}{RESET}")
        if recipes_data:
            print(f"{BLUE}[DEBUG] Sample partial recipe: {recipes_data[0]}{RESET}")

        # Step 2: Fetch full details for these recipes using bulk endpoint (10 per call)
        ids = [r["id"] for r in recipes_data]
        BATCH_SIZE = 10
        full_details = []
        for i in range(0, len(ids), BATCH_SIZE):
            batch_ids = ids[i:i+BATCH_SIZE]
            details = details_provider.get_bulk_recipe_details(batch_ids)
            full_details.extend(details)
            if i + BATCH_SIZE < len(ids):
                time.sleep(1.1)  # Respect free plan limit

        # Step 3: Map the full_details dicts to Recipe Pydantic models
        recipes_obj = []
        for r in full_details:
            try:
                recipe_obj = Recipe(**r)
                recipes_obj.append(recipe_obj)
            except Exception as map_err:
                print(f"{BLUE}[DEBUG] Error mapping recipe ID {r.get('id')} to model: {map_err}{RESET}")

        # Step 4: ENABLE FILTERING
        print(f"{BLUE}[DEBUG] Filtering recipes by time/cuisine/diet...{RESET}")
        filtered_recipes = filter_recipes(
            recipes_obj,
            max_time=payload.maxTime,
            cuisines=payload.cuisines,
            diets=payload.diets
        )

        print(f"{BLUE}[DEBUG] Returning {len(filtered_recipes)} filtered Recipe objects in recipes{RESET}")

        if filtered_recipes:
            print(f"{BLUE}[DEBUG] Filtered recipes selected to send to frontend:{RESET}")
            for rec in filtered_recipes[:5]:  # print only a sample of first 5 for brevity
                print(
                    f"{BLUE}[DEBUG] Recipe ID: {rec.id}, Title: {rec.title}, "
                    f"Cuisines: {rec.cuisines}, Diets: {rec.diets}, Time: {rec.readyInMinutes} min{RESET}"
                )
        else:
            print(f"{BLUE}[DEBUG] No recipes selected to send to frontend after filtering.{RESET}")

        print(f"{BLUE}[DEBUG] Sending {len(filtered_recipes)} recipes back to frontend (via HTTP response).{RESET}")
        if filtered_recipes:
            print(f"{BLUE}[DEBUG] Sample recipe being sent: {filtered_recipes[0].dict() if hasattr(filtered_recipes[0],'dict') else filtered_recipes[0]}{RESET}")

        print(f"{BLUE}[DEBUG] Final rate limit status before responding to frontend:{RESET}")
        if hasattr(provider, 'last_response_headers'):
            print(f"{BLUE}[DEBUG] Ingredient search provider limits:{RESET}")
            print_rate_limits(provider.last_response_headers)
        if hasattr(details_provider, 'last_response_headers'):
            print(f"{BLUE}[DEBUG] Recipe details provider limits:{RESET}")
            print_rate_limits(details_provider.last_response_headers)

        return RecipeSearchResponse(
            recipes=filtered_recipes,
            raw_gemini={"full_recipes": full_details},
            raw_gemini_str=str(full_details)
        )
    
    except Exception as e:
        print(f"{BLUE}[DEBUG] Exception occurred in search_by_ingredients: {e}{RESET}")
        raise HTTPException(status_code=500, detail=str(e))
