from fastapi import FastAPI
from app.api.scan_food import router as router
from dotenv import load_dotenv
load_dotenv()

app = FastAPI()

# Register routers
app.include_router(router, prefix="/food")
