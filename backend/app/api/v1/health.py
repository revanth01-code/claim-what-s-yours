"""Health check routes (version 1)."""

from fastapi import APIRouter
from fastapi.responses import JSONResponse

from app.core.config import get_settings
from app.db.health import check_database_connection
from app.schemas.health import DatabaseHealthResponse, HealthResponse

APP_VERSION = "0.1.0"

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse)
def get_health() -> HealthResponse:
    """Report API liveness without touching the database."""
    settings = get_settings()
    return HealthResponse(
        status="ok",
        application=settings.app_name,
        environment=settings.environment,
        version=APP_VERSION,
    )


@router.get("/health/database")
def get_database_health() -> JSONResponse:
    """Report whether the configured database is reachable."""
    settings = get_settings()
    if settings.database_url is None:
        body = DatabaseHealthResponse(status="unavailable", database="not_configured")
        return JSONResponse(content=body.model_dump(), status_code=503)
    if check_database_connection():
        body = DatabaseHealthResponse(status="ok", database="reachable")
        return JSONResponse(content=body.model_dump(), status_code=200)
    body = DatabaseHealthResponse(status="unavailable", database="unreachable")
    return JSONResponse(content=body.model_dump(), status_code=503)
