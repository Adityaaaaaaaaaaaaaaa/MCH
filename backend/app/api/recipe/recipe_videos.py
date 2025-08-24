from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.providers.youtube.youtube_video import YouTubeVideoProvider
from app.providers.gemini.gemini_summary import RecipeSummary, summarize_with_gemini

router = APIRouter()
video_provider = YouTubeVideoProvider()

class RecipeVideoRequest(BaseModel):
    title: str
    summary: str

@router.post("/searchVideosAndSummary")
async def search_videos_and_summary(payload: RecipeVideoRequest):
    try:
        videos = video_provider.search_videos(
            query=payload.title,
            max_results=10
        )

        # Call Gemini and get parsed structured summary
        gemini_summary: RecipeSummary = await summarize_with_gemini(payload.summary)

        return {
            "videos": videos,
            "summary": gemini_summary.dict(),  # return as dict/JSON
        }
    except Exception as e:
        import traceback
        traceback.print_exc()  
        raise HTTPException(status_code=500, detail=str(e))
