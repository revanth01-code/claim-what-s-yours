"""FastAPI application factory and module-level app instance."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import build_api_router
from app.core.config import get_settings
from app.core.exceptions import register_exception_handlers
from app.core.logging import configure_logging


def create_app() -> FastAPI:
    """Build the FastAPI application. Does not connect to the database."""
    settings = get_settings()
    configure_logging()

    is_production = settings.environment == "production"
    docs_url = None if is_production else f"{settings.api_prefix}/docs"
    openapi_url = None if is_production else f"{settings.api_prefix}/openapi.json"

    app = FastAPI(
        title=settings.app_name,
        version="0.1.0",
        docs_url=docs_url,
        openapi_url=openapi_url,
        redoc_url=None,
    )

    origins = settings.cors_origins_list
    if origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=origins,
            allow_credentials=False,
            allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
            allow_headers=["Authorization", "Content-Type"],
        )

    register_exception_handlers(app)
    app.include_router(build_api_router(settings.api_prefix))
    return app


app = create_app()
