"""Verification and audit models for administrator reviews."""

import enum
import uuid
from datetime import datetime

from sqlalchemy import (
    DateTime,
    ForeignKey,
    Index,
    String,
    Text,
    Uuid,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy import JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

JSONValue = JSONB().with_variant(JSON, "sqlite")


class AuditAction(str, enum.Enum):
    SOURCE_VERIFY = "source_verify"
    SOURCE_REJECT = "source_reject"
    SOURCE_UPDATE = "source_update"
    CRITERIA_CREATE = "criteria_create"
    CRITERIA_UPDATE = "criteria_update"
    CRITERIA_APPROVE = "criteria_approve"
    CRITERIA_REJECT = "criteria_reject"
    SCHOLARSHIP_PUBLISH = "scholarship_publish"
    SCHOLARSHIP_UNPUBLISH = "scholarship_unpublish"
    ADMIN_PROMOTE = "admin_promote"


class VerificationAuditLog(Base):
    """Immutable audit trail for all verification and publication decisions."""

    __tablename__ = "verification_audit_logs"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    scholarship_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("scholarships.id", ondelete="CASCADE"),
        nullable=True,
    )
    admin_user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )
    action: Mapped[str] = mapped_column(String(64), nullable=False)
    target_type: Mapped[str] = mapped_column(String(64), nullable=False)
    target_id: Mapped[uuid.UUID | None] = mapped_column(Uuid(as_uuid=True))
    notes: Mapped[str | None] = mapped_column(Text())
    details: Mapped[dict | None] = mapped_column(JSONValue)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    __table_args__ = (
        Index("ix_verification_audit_logs_scholarship", "scholarship_id", "created_at"),
        Index("ix_verification_audit_logs_admin", "admin_user_id", "created_at"),
    )
