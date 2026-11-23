"""API router construction. The router is built per application so the configured API prefix is honoured."""

from fastapi import APIRouter

from app.api.v1.admin_ingestion import router as admin_ingestion_router
from app.api.v1.admin_scholarships import router as admin_scholarships_router
from app.api.v1.ai import router as ai_router
from app.api.v1.applications import router as applications_router
from app.api.v1.auth import router as auth_router
from app.api.v1.eligibility import router as eligibility_router
from app.api.v1.health import router as health_router
from app.api.v1.notifications import router as notifications_router
from app.api.v1.scholarships import router as scholarships_router
from app.api.v1.students import router as students_router


def build_api_router(prefix: str) -> APIRouter:
    """Return a router containing all v1 routes, mounted under the given prefix."""
    api_router = APIRouter(prefix=prefix)
    api_router.include_router(health_router)
    api_router.include_router(scholarships_router)
    api_router.include_router(auth_router)
    api_router.include_router(admin_scholarships_router)
    api_router.include_router(admin_ingestion_router)
    api_router.include_router(students_router)
    api_router.include_router(applications_router)
    api_router.include_router(eligibility_router)
    api_router.include_router(ai_router)
    api_router.include_router(notifications_router)
    return api_router

