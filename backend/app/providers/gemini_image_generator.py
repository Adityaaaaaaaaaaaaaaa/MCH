# app/providers/gemini_image_generator.py
import os
import base64
from typing import Optional
from google import genai
from google.genai import types
from app.utils.ai_prompt import recipe_image_prompt

BLUE = "\x1B[34m"; RESET = "\x1B[0m"
def _blue(msg: str) -> None:
    print(f"{BLUE}{msg}{RESET}")

# init client once
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    _blue("[Gemini][recipes] WARNING: GEMINI_API_KEY not set in environment")
client = genai.Client(api_key=GEMINI_API_KEY)

async def generate_image_for_title(*, title: str) -> Optional[str]:
    """
    Returns a data URL (e.g., 'data:image/png;base64,...') or None on failure.
    Uses gemini-2.0-flash-preview-image-generation, asks for TEXT+IMAGE, then
    extracts the first inline image. One request per title (stay well under free quotas).
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

        # scan response for first inline image
        for cand in getattr(resp, "candidates", []) or []:
            for part in getattr(cand.content, "parts", []) or []:
                inline = getattr(part, "inline_data", None)
                if inline and getattr(inline, "data", None):
                    # prefer mime if provided; default to png
                    mime = getattr(inline, "mime_type", None) or "image/png"
                    b64 = base64.b64encode(inline.data).decode("utf-8")
                    return f"data:{mime};base64,{b64}"

        # sometimes the model only returns text; fall through
        _blue("[Gemini][images] no inline image returned (text-only)")
        return None

    except Exception as e:
        _blue(f"[Gemini][images] ERROR: {e}")
        return None
