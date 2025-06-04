from fastapi import FastAPI
from app.api.scan_food import router as scan_food_router
from dotenv import load_dotenv
load_dotenv()


app = FastAPI()

# Register routers
app.include_router(scan_food_router, prefix="/food")
