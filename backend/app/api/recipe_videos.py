from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.providers.youtube_video import YouTubeVideoProvider

router = APIRouter()
video_provider = YouTubeVideoProvider()

class RecipeVideoRequest(BaseModel):
    title: str

@router.post("/searchVideos")
async def search_videos_endpoint(payload: RecipeVideoRequest):
    try:
        videos = video_provider.search_videos(
            query=payload.title,
            max_results=10
        )
        return {"videos": videos}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
