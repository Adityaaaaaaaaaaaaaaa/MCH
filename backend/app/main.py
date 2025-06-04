from fastapi import FastAPI
from app.api.scan_food import router as router
from dotenv import load_dotenv
load_dotenv()
import os
print("DEBUG: GEMINI_API_KEY is", os.getenv("GEMINI_API_KEY"))



app = FastAPI()

# Register routers
app.include_router(router, prefix="/food")
