"""API router for in-app student notifications."""

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db_session
from app.modules.auth.dependencies import get_current_user
from app.modules.notifications.service import NotificationService
from app.modules.users.models import User
from app.schemas.notification import NotificationResponse, UnreadCountResponse

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("/me", response_model=list[NotificationResponse])
def list_my_notifications(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db_session)],
) -> list[NotificationResponse]:
    service = NotificationService(db)
    return service.list_notifications(current_user.id)


@router.get("/me/unread-count", response_model=UnreadCountResponse)
def get_unread_count(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db_session)],
) -> UnreadCountResponse:
    service = NotificationService(db)
    count = service.get_unread_count(current_user.id)
    return UnreadCountResponse(unread_count=count)


@router.patch("/me/{notification_id}/read", response_model=NotificationResponse)
def mark_notification_read(
    notification_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db_session)],
) -> NotificationResponse:
    service = NotificationService(db)
    return service.mark_read(notification_id, current_user.id)


@router.post("/me/read-all", response_model=UnreadCountResponse)
def mark_all_notifications_read(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db_session)],
) -> UnreadCountResponse:
    service = NotificationService(db)
    service.mark_all_read(current_user.id)
    return UnreadCountResponse(unread_count=0)
