# app/api/cravings/image_proxy.py
from fastapi import APIRouter, HTTPException, Query, Response
from app.providers.gemini.gemini_image_generator import generate_image_for_title

router = APIRouter()

@router.get(
    "/image",
    summary="Return a data-URL for a recipe title",
    responses={200: {"content": {"text/plain": {}}}},  # we return raw text (data URL)
)
async def image_for_title(title: str = Query(..., min_length=2, max_length=160)):
    """
    Returns a data-URL string (text/plain). We don't store images in Firestore,
    so the client asks for them on demand by title.
    """
    try:
        data_url = await generate_image_for_title(title=title)
        if not data_url:
            raise HTTPException(status_code=404, detail="Image not available")
        # Keep body as text/plain (not JSON) to avoid base64 escaping overhead.
        return Response(content=data_url, media_type="text/plain")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
