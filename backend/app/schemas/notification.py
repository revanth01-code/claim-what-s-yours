"""Pydantic schemas for student notifications."""

import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class NotificationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    message: str
    notification_type: str
    is_read: bool
    link_url: str | None = None
    created_at: datetime


class UnreadCountResponse(BaseModel):
    unread_count: int


class NotificationCreate(BaseModel):
    title: str = Field(min_length=1, max_length=255)
    message: str = Field(min_length=1, max_length=2000)
    notification_type: str = Field(default="general", max_length=64)
    link_url: str | None = Field(default=None, max_length=512)
