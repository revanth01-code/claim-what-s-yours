"""API router for AI Guidance and conversational application assistance."""

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db_session
from app.modules.ai.llm_client import LLMClient
from app.modules.ai.service import AIGuidanceService
from app.modules.auth.dependencies import get_current_user
from app.modules.profiles.models import StudentProfile
from app.modules.users.models import User
from app.schemas.ai import AIGuidanceRequest, AIGuidanceResponse

router = APIRouter(prefix="/ai", tags=["ai"])


@router.get("/status")
def get_ai_status() -> dict[str, object]:
    """Check AI provider configuration and live connectivity without exposing keys."""
    client = LLMClient()
    return client.validate_connectivity()


@router.post("/guidance", response_model=AIGuidanceResponse)
def get_ai_guidance(
    payload: AIGuidanceRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db_session)],
) -> AIGuidanceResponse:
    profile = None
    if payload.include_profile_context:
        profile = db.scalar(select(StudentProfile).where(StudentProfile.user_id == current_user.id))

    service = AIGuidanceService(db)
    return service.get_guidance(payload, profile)
