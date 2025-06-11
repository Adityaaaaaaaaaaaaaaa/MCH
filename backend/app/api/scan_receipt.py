from fastapi import APIRouter, File, UploadFile
from fastapi.responses import JSONResponse
import os
import base64
import requests
import filetype
import re
from app.utils.utils import detect_mime_type, build_receipt_ingredient_prompt, gemini_model_url

router = APIRouter()

def parse_gemini_receipt_response(response_json):
    try:
        text = response_json["candidates"][0]["content"]["parts"][0]["text"]
        items = []
        # Handles both newlines and comma-separated
        lines = text.splitlines()
        for line in lines:
            for pair in line.split(','):
                pair = pair.strip()
                if not pair:
                    continue
                if ":" in pair:
                    label, count = pair.split(":", 1)
                    label = label.strip()
                    count_str = count.strip()
                    # Try to extract number (float or int)
                    num_match = re.match(r"^([0-9]+(?:\.[0-9]+)?)", count_str)
                    if num_match:
                        count_value = float(num_match.group(1))
                        items.append({"item": label, "count": count_value})
                    else:
                        items.append({"item": label, "count": None})
                else:
                    label = pair.strip()
                    items.append({"item": label, "count": None})
        print(f"[DEBUG] Parsed receipt items: {items}")
        return items
    except Exception as e:
        print(f"[ERROR] Failed to parse Gemini receipt response: {e}")
        return []

@router.post("/scanReceipt")
async def analyze_receipt_image(file: UploadFile = File(...)):
    print("[DEBUG] Received file for receipt analysis.")
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
    if not GEMINI_API_KEY:
        print("[ERROR] Gemini API key not set.")
        return JSONResponse(status_code=500, content={"error": "Gemini API key not set"})

    prompt = build_receipt_ingredient_prompt()
    url = gemini_model_url(api_key=GEMINI_API_KEY)

    
    img_bytes = await file.read()
    mime_type = detect_mime_type(img_bytes)
    print(f"[DEBUG] Detected MIME type: {mime_type}")

    base64_img = base64.b64encode(img_bytes).decode('utf-8')
    print(f"[DEBUG] Using receipt prompt: {prompt}")

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
            detected_items = parse_gemini_receipt_response(resp.json())
            return JSONResponse(status_code=200, content={"detected_items": detected_items})
        else:
            return JSONResponse(status_code=resp.status_code, content={"error": resp.text})
    except Exception as e:
        print(f"[ERROR] Gemini API call failed: {e}")
        return JSONResponse(status_code=500, content={"error": "Failed to process Gemini API response."})
