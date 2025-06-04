from fastapi import APIRouter, File, UploadFile
from fastapi.responses import JSONResponse
import os
import base64
import requests

router = APIRouter()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

@router.post("/analyze")
async def analyze_food_image(file: UploadFile = File(...)):
    if not GEMINI_API_KEY:
        return JSONResponse(status_code=500, content={"error": "Gemini API key not set"})
    img_bytes = await file.read()
    base64_img = base64.b64encode(img_bytes).decode('utf-8')
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={GEMINI_API_KEY}"
    payload = {
        "contents": [
            {
                "parts": [
                    {
                        "inlineData": {
                            "mimeType": "image/jpeg",
                            "data": base64_img,
                        }
                    },
                    {
                        "text": (
                            "Identify and count the food items in this image. Respond with a comma-separated list "
                            "of the items and total count and detect all of the prominent food items in the image. "
                            "The box_2d should be [ymin, xmin, ymax, xmax] normalized to 0-1000."
                        )
                    }
                ]
            }
        ]
    }
    headers = {"Content-Type": "application/json"}
    resp = requests.post(url, headers=headers, json=payload)
    try:
        return JSONResponse(status_code=resp.status_code, content=resp.json())
    except Exception:
        return JSONResponse(status_code=500, content={"error": "Failed to parse Gemini API response."})
