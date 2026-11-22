"""Student profile model associated with User."""

import uuid
from datetime import date, datetime
from typing import Any

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Numeric,
    String,
    Text,
    Uuid,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.types import JSON

from app.db.base import Base


class StudentProfile(Base):
    __tablename__ = "student_profiles"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )

    # 1. Personal Information
    full_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    date_of_birth: Mapped[date | None] = mapped_column(Date, nullable=True)
    gender: Mapped[str | None] = mapped_column(String(32), nullable=True)
    state: Mapped[str | None] = mapped_column(String(100), nullable=True)
    district: Mapped[str | None] = mapped_column(String(100), nullable=True)
    category: Mapped[str | None] = mapped_column(String(64), nullable=True)  # sc, st, obc, general, etc.
    is_disabled: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    disability_type: Mapped[str | None] = mapped_column(String(100), nullable=True)
    disability_percentage: Mapped[float | None] = mapped_column(Numeric(5, 2), nullable=True)
    phone_number: Mapped[str | None] = mapped_column(String(20), nullable=True)

    # 2. Academic Information
    education_level: Mapped[str | None] = mapped_column(String(64), nullable=True)  # secondary, higher_secondary, undergraduate, postgraduate, doctorate
    course: Mapped[str | None] = mapped_column(String(128), nullable=True)
    stream: Mapped[str | None] = mapped_column(String(128), nullable=True)
    institution_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    institution_state: Mapped[str | None] = mapped_column(String(100), nullable=True)
    institution_district: Mapped[str | None] = mapped_column(String(100), nullable=True)
    board_or_university: Mapped[str | None] = mapped_column(String(255), nullable=True)
    academic_year: Mapped[str | None] = mapped_column(String(32), nullable=True)  # e.g., 2026-2027
    current_year_of_study: Mapped[int | None] = mapped_column(nullable=True)
    previous_exam_percentage: Mapped[float | None] = mapped_column(Numeric(5, 2), nullable=True)

    # 3. Financial Information
    annual_family_income: Mapped[float | None] = mapped_column(Numeric(12, 2), nullable=True)
    income_bracket: Mapped[str | None] = mapped_column(String(64), nullable=True)

    # 4. Additional Information
    is_hosteller: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    additional_attributes: Mapped[dict[str, Any] | None] = mapped_column(
        JSONB().with_variant(JSON, "sqlite"),
        nullable=True,
        default=dict,
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

    # Relationships
    user = relationship("User", backref="student_profile", lazy="joined")
