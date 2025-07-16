from fastapi import APIRouter, HTTPException, Request
from app.models.recipe import Recipe, RecipeSearchRequest, RecipeSearchResponse, Ingredient
from app.utils.utils import build_recipe_agent_prompt
from app.utils.ai_image import generate_recipe_image
from app.providers.edamam import Edamam
from app.providers.spoonacular import Spoonacular
from app.providers.mealdb import MealDB
from app.utils.linkChecker import LinkChecker
from typing import List, Optional, Any, Dict
from pydantic import BaseModel, Field
import os
import pprint
from dataclasses import dataclass, field, asdict, is_dataclass
import json
import asyncio
from google import genai
from google.genai import types

router = APIRouter()
BLUE = "\033[94m"
RESET = "\033[0m"

def to_dict(obj):
    """Safely convert dataclass, Pydantic model, or dict to plain dict."""
    if obj is None:
        return {}
    if isinstance(obj, dict):
        return obj
    if is_dataclass(obj):
        return asdict(obj)
    if hasattr(obj, "dict"):  # For Pydantic models
        return obj.dict()
    raise TypeError(f"Cannot convert object of type {type(obj)} to dict")

# --- Gemini Structured Output Schema ---

@dataclass
class GeminiIngredient:
    name: str
    quantity: str

@dataclass
class GeminiRecipe:
    title: str
    summary: Optional[str] = ""
    imageUrl: Optional[str] = ""
    totalTime: Optional[int] = 0
    ingredients: List[GeminiIngredient] = field(default_factory=list)
    instructions: List[str] = field(default_factory=list)
    equipment: List[str] = field(default_factory=list)
    substitutions: List[str] = field(default_factory=list)
    website: Optional[str] = ""
    videos: List[str] = field(default_factory=list)
    aiGenerated: bool = False

# Updated Pydantic model to accept raw debug fields
class RecipeSearchResponse(BaseModel):
    recipes: List[Recipe]
    raw_gemini: Optional[Any] = None
    raw_gemini_str: Optional[str] = None

@router.post("/searchByIngredients", response_model=RecipeSearchResponse)
async def search_by_ingredients(payload: RecipeSearchRequest, request: Request):
    try:
        print(f"{BLUE}[DEBUG] Starting recipe search with payload: {payload}{RESET}")

        # 1. Initialize providers and link checker
        edamam = Edamam()
        spoonacular = Spoonacular()
        mealdb = MealDB()
        link_checker = LinkChecker()
        providers = [edamam, spoonacular, mealdb]

        # 2. Search for recipes from all providers
        tasks = [provider.search(
            ingredients=payload.ingredients,
            max_time=payload.maxTime,
            cuisines=payload.cuisines,
            diets=payload.diets,
            allergies=payload.allergies
        ) for provider in providers]
        results = await asyncio.gather(*tasks)
        all_recipes = [recipe for provider_recipes in results for recipe in provider_recipes]
        print(f"{BLUE}[DEBUG] Found {len(all_recipes)} recipes from all providers.{RESET}")

        # 3. Filter out recipes with invalid URLs and remove duplicates
        valid_recipes = await link_checker.filter_valid_recipes(all_recipes)
        print(f"{BLUE}[DEBUG] Found {len(valid_recipes)} recipes with valid URLs.{RESET}")

        unique_recipes = []
        seen_titles = set()
        for recipe in valid_recipes:
            if recipe["title"].lower() not in seen_titles:
                unique_recipes.append(recipe)
                seen_titles.add(recipe["title"].lower())
        print(f"{BLUE}[DEBUG] Found {len(unique_recipes)} unique recipes.{RESET}")


        # 4. If not enough recipes, fall back to Gemini
        if len(unique_recipes) < 10:
            print(f"{BLUE}[DEBUG] Not enough recipes found, falling back to Gemini.{RESET}")
            # Relax constraints (e.g., remove rarest ingredient)
            if len(payload.ingredients) > 1:
                ingredients = payload.ingredients[:-1]
            else:
                ingredients = payload.ingredients

            # Call providers again with relaxed constraints
            tasks = [provider.search(
                ingredients=ingredients,
                max_time=payload.maxTime,
                cuisines=payload.cuisines,
                diets=payload.diets,
                allergies=payload.allergies
            ) for provider in providers]
            results = await asyncio.gather(*tasks)
            all_recipes = [recipe for provider_recipes in results for recipe in provider_recipes]
            valid_recipes = await link_checker.filter_valid_recipes(all_recipes)
            for recipe in valid_recipes:
                if recipe["title"].lower() not in seen_titles:
                    unique_recipes.append(recipe)
                    seen_titles.add(recipe["title"].lower())

            # If still not enough, generate a recipe with Gemini
            if not unique_recipes:
                print(f"{BLUE}[DEBUG] Still no recipes found, generating a recipe with Gemini.{RESET}")
                gemini_recipe = await generate_gemini_recipe(payload)
                unique_recipes.append(gemini_recipe)

        # 5. Enhance recipes with Gemini
        enhanced_recipes = await enhance_recipes_with_gemini(unique_recipes[:10], payload)
        print(f"{BLUE}[DEBUG] Enhanced {len(enhanced_recipes)} recipes with Gemini.{RESET}")

        # 6. Format and return response
        result_recipes = []
        for recipe_dict in enhanced_recipes:
            ingredient_objs = [Ingredient(**ing) for ing in recipe_dict.get('ingredients', [])]
            result_recipes.append(
                Recipe(
                    title=recipe_dict.get('title', ''),
                    summary=recipe_dict.get('summary', ''),
                    imageUrl=recipe_dict.get('imageUrl', ''),
                    totalTime=recipe_dict.get('totalTime', 0),
                    ingredients=ingredient_objs,
                    instructions=recipe_dict.get('instructions', []),
                    equipment=recipe_dict.get('equipment', []),
                    substitutions=recipe_dict.get('substitutions', []),
                    website=recipe_dict.get('website', ''),
                    videos=recipe_dict.get('videos', []),
                    aiGenerated=recipe_dict.get('aiGenerated', False),
                )
            )

        print(f"{BLUE}[DEBUG] Returning {len(result_recipes)} recipes.{RESET}")
        return RecipeSearchResponse(recipes=result_recipes)

    except Exception as e:
        print(f"{BLUE}[DEBUG] Exception occurred:{RESET} {e}")
        raise HTTPException(status_code=500, detail=str(e))


async def generate_gemini_recipe(payload: RecipeSearchRequest) -> Dict[str, Any]:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY not set")

    genai.configure(api_key=api_key)
    model = genai.GenerativeModel('gemini-1.5-flash')

    prompt = f"Generate a creative recipe using the following ingredients: {', '.join(payload.ingredients)}. The recipe should be suitable for someone with the following preferences: diets: {payload.diets}, allergies: {payload.allergies}, cuisines: {payload.cuisines}. The total cooking time should be less than {payload.maxTime} minutes."

    response = await model.generate_content_async(prompt)

    # This is a simplified example. In a real application, you would need to parse the response
    # and format it into the GeminiRecipe structure.
    return {
        "title": "AI-Generated Recipe",
        "summary": response.text,
        "imageUrl": "",
        "totalTime": payload.maxTime,
        "ingredients": [{"name": ing, "quantity": ""} for ing in payload.ingredients],
        "instructions": response.text.split('\n'),
        "equipment": [],
        "substitutions": [],
        "website": None,
        "videos": [],
        "aiGenerated": True,
    }


async def enhance_recipes_with_gemini(recipes: List[Dict[str, Any]], payload: RecipeSearchRequest) -> List[Dict[str, Any]]:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY not set")

    genai.configure(api_key=api_key)
    model = genai.GenerativeModel('gemini-1.5-flash')

    enhanced_recipes = []
    for recipe in recipes:
        prompt = f"""
        Given the following recipe:
        Title: {recipe['title']}
        Ingredients: {recipe['ingredients']}
        Instructions: {recipe['instructions']}

        Please perform the following tasks:
        1. Summarize the recipe in one sentence.
        2. Shorten the instructions to at most 5 numbered steps.
        3. Suggest safe substitutions that respect the following diet: {payload.diets}.
        4. Translate units to metric if the locale requires it (assume US locale for now).

        Return the response in a structured JSON format with the following keys: "summary", "instructions", "substitutions".
        """

        try:
            response = await model.generate_content_async(prompt)
            enhancements = json.loads(response.text)

            recipe['summary'] = enhancements.get('summary', '')
            recipe['instructions'] = enhancements.get('instructions', recipe['instructions'])
            recipe['substitutions'] = enhancements.get('substitutions', [])

            enhanced_recipes.append(recipe)
        except Exception as e:
            print(f"{BLUE}[DEBUG] Failed to enhance recipe {recipe['title']} with Gemini: {e}{RESET}")
            # Add the original recipe if enhancement fails
            enhanced_recipes.append(recipe)

    return enhanced_recipes
