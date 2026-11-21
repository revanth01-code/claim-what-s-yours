"""Response schemas for authentication endpoints."""

import uuid

from pydantic import BaseModel


class AuthenticatedUserResponse(BaseModel):
    """Application user of the caller. Never includes the raw token or the Firebase uid."""

    id: uuid.UUID
    email: str | None
    email_verified: bool
    display_name: str | None
    role: str
    is_active: bool
