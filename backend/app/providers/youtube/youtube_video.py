import json
import os
import requests
from dotenv import load_dotenv
load_dotenv()

BLUE = "\033[94m"
RESET = "\033[0m"

class YouTubeVideoProvider:
    """Provider to fetch food-related YouTube videos using the YouTube Data API."""

    def __init__(self, api_key: str = None):
        self.api_key = api_key or os.getenv("YOUTUBE_API_KEY")
        if not self.api_key:
            print(f"{BLUE}[DEBUG] YouTube API key is missing!{RESET}")
            raise ValueError("YOUTUBE_API_KEY not set in environment or passed to YouTubeVideoProvider")
        self.base_url = "https://www.googleapis.com/youtube/v3/search"

    def search_videos(self, query: str, max_results: int = 10, safe_search: str = "strict"):
        # YouTube API: maxResults must be between 1 and 50
        max_results = max(1, min(max_results, 50))

        params = {
            "part": "snippet",
            "q": query,
            "type": "video",
            "order": "relevance",
            "maxResults": max_results,
            "safeSearch": safe_search,   # Can be "none", "moderate", or "strict"
            "videoEmbeddable": "true",  # Only embeddable videos (recommended for web/app)
            "key": self.api_key,
        }

        print(f"{BLUE}[DEBUG] Sending YouTube video search request...{RESET}")
        print(f"{BLUE}[DEBUG] Params: {params}{RESET}")

        try:
            response = requests.get(self.base_url, params=params)
            print(f"{BLUE}[DEBUG] YouTube API Response Code: {response.status_code}{RESET}")
            # PRINT RAW RESPONSE BODY
            print(f"{BLUE}[DEBUG] RAW YouTube API Response:\n{json.dumps(response.json(), indent=2)}{RESET}")
            if response.status_code != 200:
                print(f"{BLUE}[DEBUG] YouTube API Error Response: {response.text}{RESET}")
                response.raise_for_status()
            data = response.json()


            videos = []
            for item in data.get("items", []):
                video_id = item.get("id", {}).get("videoId")
                snippet = item.get("snippet", {})
                if not video_id or not snippet:
                    continue
                videos.append({
                    "title": snippet.get("title", ""),
                    "videoId": video_id,
                    "thumbnail": snippet.get("thumbnails", {}).get("medium", {}).get("url", ""),
                    "channelTitle": snippet.get("channelTitle", ""),
                    "publishedAt": snippet.get("publishedAt", ""),
                    "description": snippet.get("description", "")
                })

            print(f"{BLUE}[DEBUG] YouTube returned {len(videos)} videos{RESET}")
            return videos

        except Exception as e:
            print(f"{BLUE}[DEBUG] Exception in YouTubeVideoProvider: {e}{RESET}")
            raise
