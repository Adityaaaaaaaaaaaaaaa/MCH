# app/providers/gemini_image_generator.py
import os
import base64
from typing import Optional
from io import BytesIO
from PIL import Image  # <-- make sure pillow is installed
from google import genai
from google.genai import types
from app.utils.cravings.ai_prompt import recipe_image_prompt

BLUE = "\x1B[34m"; RESET = "\x1B[0m"
def _blue(msg: str) -> None:
    print(f"{BLUE}{msg}{RESET}")

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    _blue("[Gemini][recipes] WARNING: GEMINI_API_KEY not set in environment")
client = genai.Client(api_key=GEMINI_API_KEY)

def _to_png_data_url(raw_bytes: bytes) -> str:
    """
    Robustly convert arbitrary image bytes (webp/jpeg/png/…) to PNG,
    then return a data URL: data:image/png;base64,....
    """
    with Image.open(BytesIO(raw_bytes)) as im:
        # convert to RGB to avoid palette/alpha edge cases
        if im.mode not in ("RGB", "RGBA"):
            im = im.convert("RGB")
        buf = BytesIO()
        im.save(buf, format="PNG", optimize=True)
        out = buf.getvalue()
    b64 = base64.b64encode(out).decode("utf-8")
    return f"data:image/png;base64,{b64}"

async def generate_image_for_title(*, title: str) -> Optional[str]:
    """
    Returns a data URL (PNG) or None on failure.
    """
    try:
        prompt = recipe_image_prompt(title)
        _blue(f"[Gemini][images] generating → {title}")

        resp = client.models.generate_content(
            model="gemini-2.0-flash-preview-image-generation",
            contents=prompt,
            config=types.GenerateContentConfig(
                response_modalities=["TEXT", "IMAGE"]
            )
        )

        # Scan for first inline image, normalize to PNG
        for cand in getattr(resp, "candidates", []) or []:
            for part in getattr(cand.content, "parts", []) or []:
                inline = getattr(part, "inline_data", None)
                if inline and getattr(inline, "data", None):
                    try:
                        # Normalize format -> PNG data URL
                        data_url = _to_png_data_url(inline.data)
                        _blue(f"[Gemini][images] got image bytes={len(inline.data)} → png")
                        return data_url
                    except Exception as conv_err:
                        _blue(f"[Gemini][images] PNG convert error: {conv_err}")
                        # Fallback: send raw bytes as-is if conversion failed
                        b64 = base64.b64encode(inline.data).decode("utf-8")
                        mime = getattr(inline, "mime_type", None) or "image/png"
                        return f"data:{mime};base64,{b64}"

        # sometimes the model only returns text; fall through
        _blue("[Gemini][images] no inline image returned (text-only)")
        return None

    except Exception as e:
        _blue(f"[Gemini][images] ERROR: {e}")
        return None
