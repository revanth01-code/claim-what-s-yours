"""Application record database models."""

from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING, Any

from sqlalchemy import DateTime, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy import JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.modules.scholarships.models import Scholarship
    from app.modules.users.models import User

JSONValue = JSONB().with_variant(JSON, "sqlite")


class ApplicationRecord(Base):
    __tablename__ = "application_records"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    scholarship_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("scholarships.id", ondelete="CASCADE"), index=True, nullable=False
    )
    portal_name: Mapped[str] = mapped_column(String(128), nullable=False)
    application_reference_number: Mapped[str] = mapped_column(String(128), nullable=False)
    status: Mapped[str] = mapped_column(String(32), default="submitted", nullable=False)
    academic_year: Mapped[str] = mapped_column(String(32), default="2026-2027", nullable=False)
    applied_amount: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)
    disbursed_amount: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    submitted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    timeline: Mapped[list[dict[str, Any]]] = mapped_column(JSONValue, default=list, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    scholarship: Mapped[Scholarship] = relationship("Scholarship", lazy="joined")
    user: Mapped[User] = relationship("User", lazy="joined")

    @property
    def scholarship_name(self) -> str:
        if self.scholarship:
            return self.scholarship.name
        return "Unknown Scholarship"
