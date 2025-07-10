from fastapi import FastAPI
from app.api.scan_food import router as food_router
from app.api.scan_receipt import router as receipt_router
from app.api.recipe_ing_search import router as recipe_ing_router
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# Register routers
app.include_router(food_router, prefix="/food")
app.include_router(receipt_router, prefix="/receipt")
app.include_router(recipe_ing_router, prefix="/agent/recipes")

# (Optional) Add a home page route for sanity checks
@app.get("/")
async def root():
    return {"message": "API is running"}
