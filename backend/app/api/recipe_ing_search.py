from fastapi import APIRouter, HTTPException, Request
from app.models.recipe import Recipe, RecipeSearchRequest, RecipeSearchResponse
from app.utils.utils import build_recipe_agent_prompt
from app.utils.gemini_api import gemini_flash_2_5_url
from app.utils.ai_image import generate_recipe_image
import os
import requests
import json
import pprint
import re

router = APIRouter()

@router.post("/searchByIngredients", response_model=RecipeSearchResponse)
async def search_by_ingredients(payload: RecipeSearchRequest, request: Request):
    try:
        prompt = build_recipe_agent_prompt(
            ingredients=payload.ingredients,
            max_time=payload.maxTime,
            allergies=payload.allergies,
            diets=payload.diets,
            cuisines=payload.cuisines,
            spice_level_label=payload.spiceLevel
        )
        api_key = os.getenv("GEMINI_API_KEY")
        url = gemini_flash_2_5_url(api_key=api_key)

        gemini_payload = {
            "contents": [
                {
                    "parts": [
                        {"text": prompt}
                    ]
                }
            ]
        }
        headers = {"Content-Type": "application/json"}
        response = requests.post(url, headers=headers, json=gemini_payload)
        if response.status_code != 200:
            raise HTTPException(status_code=500, detail=response.text)
        
        # ---- 1. Extract Gemini's response ----
        gemini_result = response.json()
        # Example: gemini_result['candidates'][0]['content']['parts'][0]['text']
        # The text is a string containing your JSON array or object

        print("[DEBUG] RAW Gemini response:")
        pprint.pprint(gemini_result, depth=6, compact=False, width=120)

        
        try:
            text = gemini_result['candidates'][0]['content']['parts'][0]['text']
            # Try to extract JSON inside Markdown code fences
            codeblock_match = re.search(r"```(?:json)?\n(.*?)```", text, re.DOTALL)
            if codeblock_match:
                text = codeblock_match.group(1).strip()
            else:
                # Fallback: strip possible leading/trailing whitespace or markdown
                text = text.strip()
                # Optionally: Remove single-line ```json ... ``` fences
                if text.startswith("```") and text.endswith("```"):
                    text = text[3:-3].strip()
            # Now parse JSON
            recipes_json = json.loads(text)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Gemini output parse error: {e}")
        
        # Handle if the recipes are nested
        recipes_list = recipes_json.get("recipes", recipes_json if isinstance(recipes_json, list) else [])

        # ---- 2. Image generation step ----
        result_recipes = []
        for recipe_dict in recipes_list:
            # If imageUrl is empty or missing, generate one
            image_url = recipe_dict.get("imageUrl", "")
            if not image_url:
                # Defensive: use title, fall back if missing
                title = recipe_dict.get("title", "Dish")
                image_url = generate_recipe_image(title, api_key)
                recipe_dict["imageUrl"] = image_url
            # Build Recipe object (assuming your model validates, otherwise just append dict)
            result_recipes.append(Recipe(**recipe_dict))
        
        # ---- 3. Return structured result ----
        return {"recipes": [r.dict() for r in result_recipes]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
