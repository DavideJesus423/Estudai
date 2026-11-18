from google import genai

from app.core.config import get_settings

settings = get_settings()
if not settings.gemini_api_key:
    raise SystemExit("GEMINI_API_KEY não está no .env")

client = genai.Client(api_key=settings.gemini_api_key)
for model in client.models.list():
    if "generateContent" in (model.supported_actions or []):
        print(model.name.replace("models/", ""))