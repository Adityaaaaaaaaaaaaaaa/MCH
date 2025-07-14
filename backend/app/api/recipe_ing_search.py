from fastapi import APIRouter, HTTPException, Request
from app.models.recipe import Recipe, RecipeSearchRequest, RecipeSearchResponse, Ingredient
from app.utils.utils import build_recipe_agent_prompt
from app.utils.ai_image import generate_recipe_image
from typing import List, Optional, Any
from pydantic import BaseModel, Field
import os
import pprint
from dataclasses import dataclass, field, asdict, is_dataclass
import json

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
    imageUrl: Optional[str] = ""
    totalTime: Optional[int] = 0
    ingredients: List[GeminiIngredient] = field(default_factory=list)
    instructions: List[str] = field(default_factory=list)
    equipment: List[str] = field(default_factory=list)
    website: Optional[str] = ""
    videos: List[str] = field(default_factory=list)

# Updated Pydantic model to accept raw debug fields
class RecipeSearchResponse(BaseModel):
    recipes: List[Recipe]
    raw_gemini: Optional[Any] = None
    raw_gemini_str: Optional[str] = None

@router.post("/searchByIngredients", response_model=RecipeSearchResponse)
async def search_by_ingredients(payload: RecipeSearchRequest, request: Request):
    try:
        print(f"{BLUE}[DEBUG] Building recipe agent prompt...{RESET}")
        prompt = build_recipe_agent_prompt(
            ingredients=payload.ingredients,
            max_time=payload.maxTime,
            allergies=payload.allergies,
            diets=payload.diets,
            cuisines=payload.cuisines,
            spice_level_label=payload.spiceLevel,
            num_recipes=15
        ) + (
            "\nIMPORTANT: Only provide recipes that are real and accessible from the web. "
            "Each recipe MUST have a valid public website link from trusted food/recipe domains. "
            "Do not invent links. Do not use subscription/paywalled content. "
            "Ignore any recipes that cannot be found online. "
            "Return only recipes you can verify exist with a real, accessible website URL."
        )
        print(f"{BLUE}[DEBUG] Gemini Prompt Sent:{RESET}\n{prompt}\n")

        # 1. API Key & Client
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            print(f"{BLUE}[DEBUG] Gemini API key missing!{RESET}")
            raise HTTPException(status_code=500, detail="GEMINI_API_KEY not set")
        print(f"{BLUE}[DEBUG] Creating genai.Client instance...{RESET}")
        client = genai.Client(api_key=api_key)

        # 2. Grounding (Google Search) Tool
        #print(f"{BLUE}[DEBUG] Setting up Google Search grounding tool...{RESET}")
        #grounding_tool = types.Tool(google_search=types.GoogleSearch())

        # 3. Generation config with grounding and structured output
        generation_config = types.GenerateContentConfig(
            #tools=[grounding_tool],
            response_mime_type="application/json",
            response_schema=list[GeminiRecipe]
        )

        print(f"{BLUE}[DEBUG] Generation config prepared:{RESET} {generation_config}")

        # 4. Make Gemini API Call (use 'models.generate_content' not 'model.generate_content')
        print(f"{BLUE}[DEBUG] Sending request to Gemini model...{RESET}")
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config=generation_config
        )

         # --- Print Gemini Response ---
        raw_str = response.text
        print(f"{BLUE}[DEBUG] Gemini raw response.text:{RESET}\n{raw_str}...\n")  


        # Defensive: Always parse Gemini's text output to Python, fallback if parsing fails
        raw_str = response.text
        try:
            raw_data = json.loads(raw_str)
        except Exception:
            raw_data = None

        # Defensive: Convert any GeminiRecipe-like object to dict before mapping
        result_recipes = []
        print(f"{BLUE}[DEBUG] Mapping Gemini output to Recipe objects...{RESET}")

        for recipe in response.parsed:
            # Defensive: Accept both dataclass and dict responses
            recipe_dict = to_dict(recipe)
            image_url = recipe_dict.get('imageUrl') or generate_recipe_image(recipe_dict.get('title', ''), api_key)
            # Defensive: ensure ingredients is always a list of dicts
            ingredient_objs = []
            for ing in recipe_dict.get('ingredients', []):
                ing_dict = to_dict(ing)
                ingredient_objs.append(Ingredient(**ing_dict))
            result_recipes.append(
                Recipe(
                    title=recipe_dict.get('title', ''),
                    imageUrl=image_url,
                    totalTime=recipe_dict.get('totalTime', 0),
                    ingredients=ingredient_objs,
                    instructions=recipe_dict.get('instructions', []),
                    equipment=recipe_dict.get('equipment', []),
                    website=recipe_dict.get('website', ''),
                    videos=recipe_dict.get('videos', []),
                )
            )

        print(f"{BLUE}[DEBUG] {len(result_recipes)} recipes mapped successfully.{RESET}")
        if not result_recipes:
            print(f"{BLUE}[DEBUG] No recipes found, raising 404.{RESET}")
            raise HTTPException(status_code=404, detail="No recipes found.")

        print(f"{BLUE}[DEBUG] Returning RecipeSearchResponse with results...{RESET}")
        return RecipeSearchResponse(
            recipes=result_recipes,
            raw_gemini=raw_data,       # parsed as Python object (dict/list/None)
            raw_gemini_str=raw_str     # raw JSON string (always safe)
        )

    except Exception as e:
        print(f"{BLUE}[DEBUG] Exception occurred:{RESET} {e}")
        raise HTTPException(status_code=500, detail=str(e))
