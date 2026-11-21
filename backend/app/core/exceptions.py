"""Uniform JSON error responses and exception handler registration."""

import logging
from typing import Any

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

logger = logging.getLogger(__name__)


class DatabaseNotConfiguredError(RuntimeError):
    """Raised when a database operation is requested without a configured URL."""

    def __init__(self) -> None:
        super().__init__("Database is not configured.")


def _error_body(code: str, message: str) -> dict[str, Any]:
    """Build the standard error payload."""
    return {"error": {"code": code, "message": message}}


async def _http_exception_handler(
    request: Request, exc: StarletteHTTPException
) -> JSONResponse:
    """Convert HTTP exceptions into the standard error payload."""
    message = exc.detail if isinstance(exc.detail, str) else "Request failed"
    return JSONResponse(
        status_code=exc.status_code,
        content=_error_body("http_error", message),
    )


async def _validation_exception_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    """Convert request validation errors into a 422 standard payload."""
    return JSONResponse(
        status_code=422,
        content=_error_body("validation_error", "Request validation failed"),
    )


async def _database_not_configured_handler(
    request: Request, exc: DatabaseNotConfiguredError
) -> JSONResponse:
    """Map an unconfigured database dependency to a stable 503 response."""
    del request, exc
    return JSONResponse(
        status_code=503,
        content=_error_body(
            "database_not_configured",
            "Database is not configured.",
        ),
    )


async def _unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Log the traceback server-side and return a generic 500 payload."""
    logger.exception("Unhandled exception while processing request")
    return JSONResponse(
        status_code=500,
        content=_error_body("internal_error", "An unexpected error occurred"),
    )


def register_exception_handlers(app: FastAPI) -> None:
    """Register the HTTP, validation and catch-all exception handlers on the app."""
    app.add_exception_handler(StarletteHTTPException, _http_exception_handler)
    app.add_exception_handler(RequestValidationError, _validation_exception_handler)
    app.add_exception_handler(
        DatabaseNotConfiguredError,
        _database_not_configured_handler,
    )
    app.add_exception_handler(Exception, _unhandled_exception_handler)
