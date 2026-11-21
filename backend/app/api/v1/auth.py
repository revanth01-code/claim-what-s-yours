"""Authentication routes (version 1)."""

from fastapi import APIRouter, Depends

from app.modules.auth.dependencies import get_current_user
from app.modules.users.models import User
from app.schemas.auth import AuthenticatedUserResponse

router = APIRouter(tags=["auth"])


@router.get("/auth/me", response_model=AuthenticatedUserResponse)
def get_me(
    user: User = Depends(get_current_user),
) -> AuthenticatedUserResponse:
    """Return the application user for the caller's verified Firebase ID token."""
    return AuthenticatedUserResponse(
        id=user.id,
        email=user.email,
        email_verified=user.email_verified,
        display_name=user.display_name,
        role=user.role,
        is_active=user.is_active,
    )
