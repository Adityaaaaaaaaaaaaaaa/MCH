from fastapi import APIRouter, HTTPException, Request
from typing import List, Optional, Any
from app.models.recipe import Recipe, RecipeSearchRequest, RecipeSearchResponse
# from app.utils.ai_image import generate_recipe_image
from app.providers.spoonacular import SpoonacularProvider
from app.providers.spoonacular_recipe_details import SpoonacularRecipeDetailsProvider
from app.utils.utils import filter_recipes  # <-- Import your utility
import os
# import pprint
# from dataclasses import dataclass, field, asdict, is_dataclass
# import json
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
            number=100
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
            #print(f"{BLUE}[DEBUG] Fetching bulk details for IDs: {batch_ids}{RESET}")
            details = details_provider.get_bulk_recipe_details(batch_ids)
            full_details.extend(details)
            #print(f"{BLUE}[DEBUG] Accumulated full recipes: {len(full_details)}{RESET}")
            if i + BATCH_SIZE < len(ids):
                #print(f"{BLUE}[DEBUG] Waiting for 1.1s to respect Spoonacular API rate limit{RESET}")
                time.sleep(1.1)  # Respect free plan limit

        # Step 3: Map the full_details dicts to Recipe Pydantic models
        #print(f"{BLUE}[DEBUG] Mapping raw recipe dicts to Recipe models...{RESET}")

        recipes_obj = []
        for r in full_details:
            try:
                recipe_obj = Recipe(**r)
                recipes_obj.append(recipe_obj)
            except Exception as map_err:
                print(f"{BLUE}[DEBUG] Error mapping recipe ID {r.get('id')} to model: {map_err}{RESET}")
                # Optionally skip or handle bad entries

        # Step 4: Filter based on maxTime, cuisines, diets
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
            for rec in filtered_recipes:
                print(
                    f"{BLUE}[DEBUG] Recipe ID: {rec.id}, Title: {rec.title}, "
                    f"Cuisines: {rec.cuisines}, Diets: {rec.diets}, Time: {rec.readyInMinutes} min{RESET}"
                )
        else:
            print(f"{BLUE}[DEBUG] No recipes selected to send to frontend after filtering.{RESET}")

        # Return both the strongly-typed models and raw data for debugging
        return RecipeSearchResponse(
            recipes=filtered_recipes,
            raw_gemini={"full_recipes": full_details},
            raw_gemini_str=str(full_details)
        )

    except Exception as e:
        print(f"{BLUE}[DEBUG] Exception occurred in search_by_ingredients: {e}{RESET}")
        raise HTTPException(status_code=500, detail=str(e))
