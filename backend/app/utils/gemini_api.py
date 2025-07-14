GEMINI_API_ROOT = "https://generativelanguage.googleapis.com/v1beta/models"

DEFAULT_STABLE_GEMINI_MODEL = "gemini-2.0-flash-001"
GEMINI_FLASH_2_5_MODEL = "gemini-2.5-flash" 

def gemini_model_url(model=DEFAULT_STABLE_GEMINI_MODEL, method="generateContent", api_key=None):
    url = f"{GEMINI_API_ROOT}/{model}:{method}"
    if api_key:
        url += f"?key={api_key}"
    return url

def gemini_flash_2_5_url(method="generateContent", api_key=None):
    return gemini_model_url(model=GEMINI_FLASH_2_5_MODEL, method=method, api_key=api_key)
