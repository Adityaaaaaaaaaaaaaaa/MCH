from fastapi import APIRouter, File, UploadFile
from fastapi.responses import JSONResponse
import base64

from app.utils.utils import detect_mime_type, build_food_ingredient_prompt
from app.providers.gemini.gemini_scanFood import analyze_food_image_bytes, _blue

router = APIRouter()

@router.post("/scanFood")
async def analyze_food_image(file: UploadFile = File(...)):
    _blue("[API][scanFood] Received file for analysis")
    img_bytes = await file.read()
    mime_type = detect_mime_type(img_bytes)
    _blue(f"[API][scanFood] Detected MIME type: {mime_type}")

    prompt = build_food_ingredient_prompt()
    items, error = analyze_food_image_bytes(
        file_bytes=img_bytes,
        mime_type=mime_type,
        prompt_text=prompt,
    )

    if error:
        _blue(f"[API][scanFood] Error: {error}")
        return JSONResponse(status_code=error.get("code", 500), content={
            "error": error.get("message", "Unknown error"),
            "error_code": error.get("code", 500)
        })

    _blue(f"[API][scanFood] Parsed items: {items}")
    return JSONResponse(status_code=200, content={"detected_items": items})
