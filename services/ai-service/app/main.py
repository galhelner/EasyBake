import os
import sys
from contextlib import asynccontextmanager
from collections.abc import AsyncIterator
from pathlib import Path

from dotenv import load_dotenv
import uvicorn
from fastapi import FastAPI

# Load environment variables from .env file before any imports that depend on them
load_dotenv()

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[1]))
    from app.api.endpoints import router as ai_router
    from app.core.logger import get_logger
    from app.services.gemini_service import MODEL_NAME
else:
    from app.api.endpoints import router as ai_router
    from app.core.logger import get_logger
    from app.services.gemini_service import MODEL_NAME

logger = get_logger()

@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    logger.info(f"EasyBake AI Service model: {MODEL_NAME}")
    yield


app = FastAPI(title="EasyBake AI Service", lifespan=lifespan)

app.include_router(ai_router, prefix="/api")

@app.get("/health")
def health_check():
    return {"status": "AI Service is running"}


if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host=os.getenv("HOST", "127.0.0.1"),
        port=int(os.getenv("PORT", "8000")),
        reload=os.getenv("UVICORN_RELOAD", "false").lower() == "true",
    )