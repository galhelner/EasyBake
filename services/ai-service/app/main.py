import os
import sys
from pathlib import Path

import uvicorn
from fastapi import FastAPI

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[1]))
    from app.api.endpoints import router as ai_router
else:
    from app.api.endpoints import router as ai_router

app = FastAPI(title="EasyBake AI Service")

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