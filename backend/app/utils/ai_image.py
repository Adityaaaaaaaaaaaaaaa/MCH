import os
import requests

def generate_recipe_image(recipe_title: str, api_key: str) -> str:
    """
    Calls image generation API to create a photo for the recipe title.
    Returns a base64 string or direct image URL.
    """
    prompt = (
        f"A delicious, vibrant, professional food photography shot of \"{recipe_title}\". "
        "The dish should be well-lit, appetizing, and styled on a clean, modern background."
    )
    url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-preview-image-generation:generateImage"
    payload = {
        "prompt": prompt,
        "config": {
            "numberOfImages": 1,
            "outputMimeType": "image/jpeg"
        }
    }
    headers = {"Content-Type": "application/json"}
    if api_key:
        url += f"?key={api_key}"
    response = requests.post(url, headers=headers, json=payload)
    try:
        if response.status_code == 200:
            data = response.json()
            images = data.get("generatedImages", [])
            if images and "image" in images[0] and "imageBytes" in images[0]["image"]:
                return "data:image/jpeg;base64," + images[0]["image"]["imageBytes"]
    except Exception as e:
        print(f"[DEBUG] Image generation failed for '{recipe_title}': {e}")
    # Optionally return None to signal "no image"
    return None
