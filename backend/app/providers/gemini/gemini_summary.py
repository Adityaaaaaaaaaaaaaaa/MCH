import os
from google import genai
from app.utils.utils import RECIPE_SUMMARY_PROMPT
from pydantic import BaseModel
from typing import Optional

class RecipeSummary(BaseModel):
    title: str
    short_summary: str
    nutrition: Optional[str]
    servings: Optional[str]
    highlights: Optional[list[str]]

GEMINI_API_KEY = os.environ["GEMINI_API_KEY"]

async def summarize_with_gemini(html_summary: str) -> RecipeSummary:
    prompt = RECIPE_SUMMARY_PROMPT.format(html_summary=html_summary)
    client = genai.Client(api_key=GEMINI_API_KEY)
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
        config={
            "response_mime_type": "application/json",
            "response_schema": RecipeSummary,
        },
    )
    
    print("[GEMINI RAW RESPONSE]", response.text)  
    print("[GEMINI PARSED OBJECT]", response.parsed)
    return response.parsed
