"""Notification service layer."""

import uuid
from fastapi import HTTPException, status
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.modules.notifications.models import Notification
from app.schemas.notification import NotificationCreate


class NotificationService:
    def __init__(self, session: Session) -> None:
        self.session = session

    def list_notifications(self, user_id: uuid.UUID, limit: int = 50) -> list[Notification]:
        stmt = (
            select(Notification)
            .where(Notification.user_id == user_id)
            .order_by(Notification.created_at.desc())
            .limit(limit)
        )
        return list(self.session.scalars(stmt).all())

    def get_unread_count(self, user_id: uuid.UUID) -> int:
        stmt = (
            select(Notification)
            .where(Notification.user_id == user_id, Notification.is_read.is_(False))
        )
        return len(list(self.session.scalars(stmt).all()))

    def mark_read(self, notification_id: uuid.UUID, user_id: uuid.UUID) -> Notification:
        stmt = select(Notification).where(
            Notification.id == notification_id, Notification.user_id == user_id
        )
        n = self.session.scalars(stmt).one_or_none()
        if not n:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Notification {notification_id} not found.",
            )
        n.is_read = True
        self.session.commit()
        self.session.refresh(n)
        return n

    def mark_all_read(self, user_id: uuid.UUID) -> int:
        stmt = (
            update(Notification)
            .where(Notification.user_id == user_id, Notification.is_read.is_(False))
            .values(is_read=True)
        )
        res = self.session.execute(stmt)
        self.session.commit()
        return res.rowcount

    def create_notification(
        self, user_id: uuid.UUID, payload: NotificationCreate
    ) -> Notification:
        n = Notification(
            user_id=user_id,
            title=payload.title,
            message=payload.message,
            notification_type=payload.notification_type,
            link_url=payload.link_url,
            is_read=False,
        )
        self.session.add(n)
        self.session.commit()
        self.session.refresh(n)
        return n
