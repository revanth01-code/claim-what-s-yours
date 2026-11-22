"""Application user model, keyed by the Firebase Authentication uid.

Passwords, tokens and sensitive personal data are never stored here. The role is
owned by PostgreSQL and is never taken from client input or identity claims.
"""

import uuid
from datetime import datetime

from sqlalchemy import Boolean, CheckConstraint, DateTime, String, UniqueConstraint, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base

USER_ROLES = ("student", "admin")


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    firebase_uid: Mapped[str] = mapped_column(String(128), nullable=False)
    email: Mapped[str | None] = mapped_column(String(320))
    email_verified: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default="false"
    )
    display_name: Mapped[str | None] = mapped_column(String(255))
    role: Mapped[str] = mapped_column(
        String(32), nullable=False, default="student", server_default="student"
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default="true"
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    __table_args__ = (
        UniqueConstraint("firebase_uid", name="uq_users_firebase_uid"),
        CheckConstraint(
            "role IN (" + ", ".join(f"'{role}'" for role in USER_ROLES) + ")",
            name="ck_users_role_valid",
        ),
        CheckConstraint("length(firebase_uid) > 0", name="ck_users_firebase_uid_not_empty"),
    )
