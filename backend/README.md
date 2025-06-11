# My FastAPI Backend

## Folder Structure

- `app/`: Main application code
  - `main.py`: FastAPI entrypoint
  - `api/`: Routers for each endpoint (e.g., `scan_food.py`)
  - `utils/`: (Optional) Helper functions

## Usage

- Create a virtual environment: `python -m venv .venv`
- Activate: `.venv\Scripts\activate`
- Install requirements: `pip install -r requirements.txt`
- Create `.env` and set `GEMINI_API_KEY`
- Run: `start.bat` or `uvicorn app.main:app --reload`

## API Endpoints

- `/food/analyze`: Upload a food image to analyze via Gemini Vision API
