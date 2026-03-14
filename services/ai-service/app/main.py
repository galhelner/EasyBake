from fastapi import FastAPI
from app.api.endpoints import router as ai_router

app = FastAPI(title="EasyBake AI Service")

app.include_router(ai_router, prefix="/api")

@app.get("/health")
def health_check():
    return {"status": "AI Service is running"}