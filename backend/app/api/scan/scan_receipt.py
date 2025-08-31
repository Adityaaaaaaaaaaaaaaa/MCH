# app/api/scan/scan_receipt.py   (same filename)
from fastapi import APIRouter, File, UploadFile
from fastapi.responses import JSONResponse

from app.utils.utils import detect_mime_type, build_receipt_ingredient_prompt
from app.providers.gemini.gemini_scanReceipt import analyze_receipt_image_bytes, _blue

router = APIRouter()

@router.post("/scanReceipt")
async def analyze_receipt_image(file: UploadFile = File(...)):
    _blue("[API][scanReceipt] Received file for receipt analysis")
    img_bytes = await file.read()
    mime_type = detect_mime_type(img_bytes)
    _blue(f"[API][scanReceipt] Detected MIME type: {mime_type}")

    prompt = build_receipt_ingredient_prompt()
    items, error = analyze_receipt_image_bytes(
        file_bytes=img_bytes,
        mime_type=mime_type,
        prompt_text=prompt,
    )

    if error:
        _blue(f"[API][scanReceipt] Error: {error}")
        return JSONResponse(status_code=error.get("code", 500), content={
            "error": error.get("message", "Unknown error"),
            "error_code": error.get("code", 500),
        })

    _blue(f"[API][scanReceipt] Parsed items: {items}")
    return JSONResponse(status_code=200, content={"detected_items": items})
