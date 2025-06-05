from fastapi import FastAPI
from app.api.scan_food import router as food_router
from app.api.scan_receipt import router as receipt_router
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# Register routers
app.include_router(food_router, prefix="/food")
app.include_router(receipt_router, prefix="/receipt")

# (Optional) Add a home page route for sanity checks
@app.get("/")
async def root():
    return {"message": "API is running"}
