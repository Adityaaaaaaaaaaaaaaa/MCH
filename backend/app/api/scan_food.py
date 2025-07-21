from fastapi import APIRouter, File, UploadFile
from fastapi.responses import JSONResponse
import os
import base64
import requests
import filetype
import re
from app.utils.utils import detect_mime_type, build_food_ingredient_prompt
from app.utils.gemini_api import gemini_model_url

router = APIRouter()

def parse_gemini_ingredient_response(response_json):
    try:
        text = response_json["candidates"][0]["content"]["parts"][0]["text"].strip()

        # Error check
        if text.strip().lower() in ["{ no ingredients detected }", "{ errormessage }"]:
            return []


        # Remove leading/trailing spaces and split by top-level curly-brace groups
        # Example: {Apple, 2, Fruits},{Egg, 1, Protein}
        pattern = r"\{([^}]+)\}"
        matches = re.findall(pattern, text)

        items = []
        for match in matches:
            # Each match is 'itemName, count, category'
            fields = [x.strip() for x in match.split(",")]
            if len(fields) == 3:
                item_name, count_str, category = fields
                try:
                    count_value = int(count_str)
                except Exception:
                    count_value = 1
                items.append({
                    "itemName": item_name,
                    "count": count_value,
                    "category": category
                })
            elif len(fields) == 2:
                # If count is missing, assign count as 1
                item_name, category = fields
                items.append({
                    "itemName": item_name,
                    "count": 1,
                    "category": category
                })
            elif len(fields) == 1:
                # Should not happen, but handle just in case
                item_name = fields[0]
                items.append({
                    "itemName": item_name,
                    "count": 1,
                    "category": "uncategorized"
                })
        print(f"[DEBUG] Parsed items: {items}")
        return items
    except Exception as e:
        print(f"[ERROR] Failed to parse Gemini response: {e}")
        return []


@router.post("/scanFood")
async def analyze_food_image(file: UploadFile = File(...)):
    print("[DEBUG] Received file for analysis.")
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY") 

    if not GEMINI_API_KEY:
        print("[ERROR] Gemini API key not set.")
        return JSONResponse(status_code=500, content={
            "error": "Gemini API key not set",
            "error_code": 500
        })

    prompt = build_food_ingredient_prompt()
    url = gemini_model_url(api_key=GEMINI_API_KEY)
    
    img_bytes = await file.read()
    mime_type = detect_mime_type(img_bytes)
    print(f"[DEBUG] Detected MIME type: {mime_type}")

    base64_img = base64.b64encode(img_bytes).decode('utf-8')
    print(f"[DEBUG] Using prompt: {prompt}")

    payload = {
        "contents": [
            {
                "parts": [
                    {
                        "inlineData": {
                            "mimeType": mime_type,
                            "data": base64_img,
                        }
                    },
                    {
                        "text": prompt
                    }
                ]
            }
        ]
    }
    
    headers = {"Content-Type": "application/json"}
    try:
        resp = requests.post(url, headers=headers, json=payload)
        print(f"[DEBUG] Gemini API status: {resp.status_code}")
        print(f"[DEBUG] Gemini API raw response: {resp.text}")
        if resp.status_code == 200:
            detected_items = parse_gemini_ingredient_response(resp.json())
            return JSONResponse(status_code=200, content={"detected_items": detected_items})
        else:
            # Try to extract a meaningful error message from Gemini's response
            try:
                err_json = resp.json()
                err_message = err_json.get("error", {}).get("message", resp.text)
                err_code = err_json.get("error", {}).get("code", resp.status_code)
            except Exception:
                err_message = resp.text
                err_code = resp.status_code
            return JSONResponse(
                status_code=resp.status_code,
                content={
                    "error": err_message,
                    "error_code": err_code
                }
            )
    except Exception as e:
        print(f"[ERROR] Gemini API call failed: {e}")
        return JSONResponse(
            status_code=500,
            content={
                "error": "Failed to process Gemini API response.",
                "error_code": 500
            }
        )