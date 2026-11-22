"""API routes for student profile management."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db_session
from app.modules.auth.dependencies import get_current_user
from app.modules.profiles import service
from app.modules.users.models import User
from app.schemas.profile import (
    ProfileCompletionResponse,
    StudentProfileResponse,
    StudentProfileUpdate,
)

router = APIRouter(prefix="/students/me/profile", tags=["Student Profile"])


@router.get("", response_model=StudentProfileResponse)
def get_my_profile(
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_db_session),
) -> StudentProfileResponse:
    """Retrieve the current authenticated student's profile."""
    profile = service.get_or_create_profile(session, current_user)
    session.commit()
    return StudentProfileResponse.model_validate(profile)


@router.put("", response_model=StudentProfileResponse)
def update_my_profile(
    payload: StudentProfileUpdate,
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_db_session),
) -> StudentProfileResponse:
    """Create or update the current authenticated student's profile."""
    profile = service.update_profile(session, current_user, payload)
    session.commit()
    return StudentProfileResponse.model_validate(profile)


@router.get("/completion", response_model=ProfileCompletionResponse)
def get_my_profile_completion(
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_db_session),
) -> ProfileCompletionResponse:
    """Retrieve profile completeness metrics and missing fields."""
    profile = service.get_profile_by_user_id(session, current_user.id)
    return service.calculate_completion(profile)
