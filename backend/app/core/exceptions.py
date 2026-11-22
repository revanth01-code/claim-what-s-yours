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


class DatabaseUnavailableError(RuntimeError):
    """Raised when a configured database cannot serve a request."""

    def __init__(self) -> None:
        super().__init__("Database is unavailable.")


class AuthenticationError(RuntimeError):
    """Raised when a request carries missing, invalid or expired credentials (401)."""

    status_code = 401
    error_code = "authentication_failed"

    def __init__(self, message: str = "Authentication failed.") -> None:
        super().__init__(message)


class AccountDisabledError(RuntimeError):
    """Raised when a valid identity maps to a disabled account (403)."""

    status_code = 403
    error_code = "account_disabled"

    def __init__(self) -> None:
        super().__init__("Account is disabled.")


class AuthorizationError(RuntimeError):
    """Raised when an authenticated user lacks permission for an operation (403)."""

    status_code = 403
    error_code = "forbidden"

    def __init__(self, message: str = "Access forbidden.") -> None:
        super().__init__(message)


class AuthServiceUnavailableError(RuntimeError):
    """Raised when the identity provider cannot be reached or verified (503)."""

    status_code = 503
    error_code = "auth_service_unavailable"

    def __init__(self) -> None:
        super().__init__("Authentication service is temporarily unavailable.")


class EntityNotFoundError(RuntimeError):
    """Raised when a requested resource does not exist (404)."""

    status_code = 404
    error_code = "not_found"

    def __init__(self, message: str = "Resource not found.") -> None:
        super().__init__(message)


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
        headers=exc.headers,
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


async def _database_unavailable_handler(
    request: Request, exc: DatabaseUnavailableError
) -> JSONResponse:
    """Map database execution failures to a stable 503 response."""
    del request, exc
    return JSONResponse(
        status_code=503,
        content=_error_body(
            "database_unavailable",
            "Database is temporarily unavailable.",
        ),
    )


async def _authentication_error_handler(
    request: Request, exc: AuthenticationError
) -> JSONResponse:
    """Map authentication failures to a 401 response with a Bearer challenge."""
    del request
    return JSONResponse(
        status_code=exc.status_code,
        content=_error_body(exc.error_code, str(exc)),
        headers={"WWW-Authenticate": "Bearer"},
    )


async def _account_disabled_handler(request: Request, exc: AccountDisabledError) -> JSONResponse:
    """Map disabled accounts to a stable 403 response."""
    del request
    return JSONResponse(
        status_code=exc.status_code,
        content=_error_body(exc.error_code, str(exc)),
    )


async def _authorization_error_handler(
    request: Request, exc: AuthorizationError
) -> JSONResponse:
    """Map permission failures to a stable 403 response."""
    del request
    return JSONResponse(
        status_code=exc.status_code,
        content=_error_body(exc.error_code, str(exc)),
    )


async def _auth_service_unavailable_handler(
    request: Request, exc: AuthServiceUnavailableError
) -> JSONResponse:
    """Map identity provider outages to a stable 503 response."""
    del request
    return JSONResponse(
        status_code=exc.status_code,
        content=_error_body(exc.error_code, str(exc)),
    )


async def _entity_not_found_handler(
    request: Request, exc: EntityNotFoundError
) -> JSONResponse:
    """Map missing resource errors to a 404 response."""
    del request
    return JSONResponse(
        status_code=exc.status_code,
        content=_error_body(exc.error_code, str(exc)),
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
    app.add_exception_handler(
        DatabaseUnavailableError,
        _database_unavailable_handler,
    )
    app.add_exception_handler(AuthenticationError, _authentication_error_handler)
    app.add_exception_handler(AccountDisabledError, _account_disabled_handler)
    app.add_exception_handler(AuthorizationError, _authorization_error_handler)
    app.add_exception_handler(
        AuthServiceUnavailableError,
        _auth_service_unavailable_handler,
    )
    app.add_exception_handler(EntityNotFoundError, _entity_not_found_handler)
    app.add_exception_handler(Exception, _unhandled_exception_handler)
