"""API router construction. The router is built per application so the configured API prefix is honoured."""

from fastapi import APIRouter

from app.api.v1.health import router as health_router


def build_api_router(prefix: str) -> APIRouter:
    """Return a router containing all v1 routes, mounted under the given prefix."""
    api_router = APIRouter(prefix=prefix)
    api_router.include_router(health_router)
    return api_router
