from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.routers.auth import router as auth_router

settings = get_settings()
app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description="API de autenticação do Estudaí. Não cria nem altera tabelas automaticamente.",
)

if settings.allowed_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_credentials=False,
        allow_methods=["GET", "POST"],
        allow_headers=["Authorization", "Content-Type"],
    )

app.include_router(auth_router, prefix=settings.api_v1_prefix)


@app.get("/health", tags=["Sistema"])
def health():
    return {"status": "ok", "service": "estudai-api"}
