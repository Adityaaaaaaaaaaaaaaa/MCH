from fastapi import FastAPI
from app.api.scan.scan_food import router as food_router
from app.api.scan.scan_receipt import router as receipt_router
from app.api.recipe.recipe_ing_search import router as recipe_ing_router
from app.api.recipe.recipe_videos import router as recipe_vid_router
from app.api.meal_planner.meal_planner import router as meal_planner_router
from app.api.meal_planner.meal_planner_change_day import router as meal_planner_change_day_router
from app.api.meal_planner.meal_planner_ping import router as meal_planner_ping_router
from app.api.meal_planner.meal_planner_admin import router as meal_planner_admin_router
from app.api.cravings.ai_recipe_generator import router as ai_recipe_router
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="My Cooking Helper API", 
    version="0.1.0", 
    description="Backend for My Cooking Helper app"
)

app.include_router(food_router, prefix="/food")
app.include_router(receipt_router, prefix="/receipt")
app.include_router(recipe_ing_router, prefix="/recipes/find")
app.include_router(recipe_vid_router, prefix="/recipes/search")
app.include_router(meal_planner_router, prefix="/mealPlanner/week")
app.include_router(meal_planner_change_day_router, prefix="/mealPlanner/day")
app.include_router(meal_planner_ping_router, prefix="/mealPlanner/ping")
app.include_router(meal_planner_admin_router, prefix="/mealPlanner/userPlan")
app.include_router(ai_recipe_router, prefix="/recipes/gemini")

@app.get("/")
async def root():
    return {"message": "API is running"}
