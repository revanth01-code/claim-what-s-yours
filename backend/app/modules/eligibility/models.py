"""Structured eligibility criteria storage.

This module stores criteria only. It does not evaluate eligibility.
"""

import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    JSON,
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    ForeignKeyConstraint,
    Index,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    text,
    Uuid,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


JSONValue = JSONB().with_variant(JSON, "sqlite")


class EligibilityCriteria(Base):
    __tablename__ = "eligibility_criteria"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    scholarship_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("scholarships.id", ondelete="CASCADE"),
        nullable=False,
    )
    academic_year_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("academic_years.id", ondelete="RESTRICT"),
    )
    minimum_academic_percentage: Mapped[Decimal | None] = mapped_column(
        Numeric(5, 2)
    )
    maximum_academic_percentage: Mapped[Decimal | None] = mapped_column(
        Numeric(5, 2)
    )
    minimum_family_income: Mapped[Decimal | None] = mapped_column(
        Numeric(12, 2)
    )
    maximum_family_income: Mapped[Decimal | None] = mapped_column(
        Numeric(12, 2)
    )
    education_levels: Mapped[list[str] | None] = mapped_column(JSONValue)
    courses: Mapped[list[str] | None] = mapped_column(JSONValue)
    institution_requirements: Mapped[dict | None] = mapped_column(JSONValue)
    categories: Mapped[list[str] | None] = mapped_column(JSONValue)
    domicile_state: Mapped[str | None] = mapped_column(String(100))
    gender_restriction: Mapped[str | None] = mapped_column(String(32))
    disability_required: Mapped[bool | None] = mapped_column(Boolean)
    renewal_only: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default="false"
    )
    other_conditions: Mapped[dict | None] = mapped_column(JSONValue)
    source_reference: Mapped[str | None] = mapped_column(Text())
    is_verified: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default="false"
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

    scholarship: Mapped["Scholarship"] = relationship(
        back_populates="eligibility_criteria"
    )
    academic_year: Mapped["AcademicYear | None"] = relationship(
        back_populates="eligibility_criteria"
    )

    __table_args__ = (
        UniqueConstraint(
            "scholarship_id",
            "academic_year_id",
            name="uq_eligibility_criteria_scholarship_year",
        ),
        ForeignKeyConstraint(
            ["scholarship_id", "academic_year_id"],
            [
                "scholarship_academic_years.scholarship_id",
                "scholarship_academic_years.academic_year_id",
            ],
            ondelete="RESTRICT",
            name="fk_eligibility_criteria_scholarship_year",
        ),
        Index(
            "uq_eligibility_criteria_general",
            "scholarship_id",
            unique=True,
            postgresql_where=text("academic_year_id IS NULL"),
            sqlite_where=text("academic_year_id IS NULL"),
        ),
        CheckConstraint(
            "minimum_academic_percentage IS NULL "
            "OR (minimum_academic_percentage >= 0 "
            "AND minimum_academic_percentage <= 100)",
            name="ck_eligibility_min_academic_percentage",
        ),
        CheckConstraint(
            "maximum_academic_percentage IS NULL "
            "OR (maximum_academic_percentage >= 0 "
            "AND maximum_academic_percentage <= 100)",
            name="ck_eligibility_max_academic_percentage",
        ),
        CheckConstraint(
            "minimum_academic_percentage IS NULL "
            "OR maximum_academic_percentage IS NULL "
            "OR maximum_academic_percentage >= minimum_academic_percentage",
            name="ck_eligibility_academic_percentage_range",
        ),
        CheckConstraint(
            "minimum_family_income IS NULL OR minimum_family_income >= 0",
            name="ck_eligibility_min_family_income",
        ),
        CheckConstraint(
            "maximum_family_income IS NULL OR maximum_family_income >= 0",
            name="ck_eligibility_max_family_income",
        ),
        CheckConstraint(
            "minimum_family_income IS NULL "
            "OR maximum_family_income IS NULL "
            "OR maximum_family_income >= minimum_family_income",
            name="ck_eligibility_family_income_range",
        ),
    )
