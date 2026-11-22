"""Scholarship, source, verification and academic-year models."""

import enum
import uuid
from datetime import date, datetime

from sqlalchemy import (
    JSON,
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    ForeignKeyConstraint,
    Index,
    String,
    Text,
    UniqueConstraint,
    Uuid,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


JSONValue = JSONB().with_variant(JSON, "sqlite")


class ScholarshipCategory(str, enum.Enum):
    GENERAL = "general"
    SC = "sc"
    ST = "st"
    OBC = "obc"
    EBC = "ebc"
    MINORITY = "minority"
    ECONOMICALLY_WEAKER = "economically_weaker"
    DISABILITY = "disability"
    MERIT = "merit"
    OTHER = "other"


class SourceType(str, enum.Enum):
    GOVERNMENT_API = "government_api"
    GOVERNMENT_PORTAL = "government_portal"
    GOVERNMENT_DEPARTMENT = "government_department"
    OFFICIAL_NOTIFICATION = "official_notification"
    OFFICIAL_PDF = "official_pdf"
    OTHER_AUTHORITY = "other_authority"


class VerificationStatus(str, enum.Enum):
    COLLECTED = "collected"
    EXTRACTED = "extracted"
    PENDING_VALIDATION = "pending_validation"
    PENDING_VERIFICATION = "pending_verification"
    VERIFIED = "verified"
    APPROVED = "approved"
    REJECTED = "rejected"
    ARCHIVED = "archived"


class Scholarship(Base):
    __tablename__ = "scholarships"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    slug: Mapped[str] = mapped_column(String(255), nullable=False, unique=True)
    description: Mapped[str | None] = mapped_column(Text())
    administering_authority: Mapped[str] = mapped_column(String(255), nullable=False)
    category: Mapped[str] = mapped_column(String(64), nullable=False)
    benefits: Mapped[list[dict] | dict | None] = mapped_column(JSONValue)
    application_url: Mapped[str | None] = mapped_column(String(2048))
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

    eligibility_criteria: Mapped[list["EligibilityCriteria"]] = relationship(
        back_populates="scholarship",
        cascade="all, delete-orphan",
    )
    source_associations: Mapped[list["ScholarshipSource"]] = relationship(
        back_populates="scholarship",
        cascade="all, delete-orphan",
    )
    academic_year_associations: Mapped[list["ScholarshipAcademicYear"]] = relationship(
        back_populates="scholarship",
        cascade="all, delete-orphan",
    )

    __table_args__ = (
        Index("ix_scholarships_category_active", "category", "is_active"),
        Index("ix_scholarships_name", "name"),
        CheckConstraint("length(name) > 0", name="ck_scholarships_name_not_empty"),
        CheckConstraint(
            "length(administering_authority) > 0",
            name="ck_scholarships_authority_not_empty",
        ),
        CheckConstraint(
            "category IN ('general', 'sc', 'st', 'obc', 'ebc', 'minority', "
            "'economically_weaker', 'disability', 'merit', 'other')",
            name="ck_scholarships_category",
        ),
    )


class AcademicYear(Base):
    __tablename__ = "academic_years"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    year: Mapped[str] = mapped_column(String(20), nullable=False, unique=True)
    starts_on: Mapped[date | None] = mapped_column(Date())
    ends_on: Mapped[date | None] = mapped_column(Date())
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    scholarship_associations: Mapped[list["ScholarshipAcademicYear"]] = relationship(
        back_populates="academic_year",
    )
    eligibility_criteria: Mapped[list["EligibilityCriteria"]] = relationship(
        back_populates="academic_year"
    )

    __table_args__ = (
        CheckConstraint("length(year) > 0", name="ck_academic_years_year_not_empty"),
        CheckConstraint(
            "ends_on IS NULL OR starts_on IS NULL OR ends_on >= starts_on",
            name="ck_academic_years_date_range",
        ),
        CheckConstraint(
            "ends_on IS NULL OR starts_on IS NULL OR ends_on >= starts_on",
            name="ck_academic_years_date_range",
        ),
    )


class ScholarshipAcademicYear(Base):
    __tablename__ = "scholarship_academic_years"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    scholarship_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("scholarships.id", ondelete="CASCADE"),
        nullable=False,
    )
    academic_year_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("academic_years.id", ondelete="RESTRICT"),
        nullable=False,
    )
    is_available: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default="true"
    )
    opening_date: Mapped[date | None] = mapped_column(Date())
    closing_date: Mapped[date | None] = mapped_column(Date())
    name_override: Mapped[str | None] = mapped_column(String(255))
    description_override: Mapped[str | None] = mapped_column(Text())
    benefits_override: Mapped[list[dict] | dict | None] = mapped_column(JSONValue)
    application_url_override: Mapped[str | None] = mapped_column(String(2048))

    scholarship: Mapped["Scholarship"] = relationship(
        back_populates="academic_year_associations"
    )
    academic_year: Mapped["AcademicYear"] = relationship(
        back_populates="scholarship_associations"
    )

    __table_args__ = (
        UniqueConstraint(
            "scholarship_id",
            "academic_year_id",
            name="uq_scholarship_academic_year",
        ),
        Index(
            "ix_scholarship_academic_year_dates",
            "opening_date",
            "closing_date",
        ),
        CheckConstraint(
            "closing_date IS NULL OR opening_date IS NULL "
            "OR closing_date >= opening_date",
            name="ck_scholarship_academic_year_dates",
        ),
    )


class OfficialSource(Base):
    __tablename__ = "official_sources"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    source_url: Mapped[str] = mapped_column(String(2048), nullable=False)
    authority: Mapped[str] = mapped_column(String(255), nullable=False)
    source_type: Mapped[str] = mapped_column(String(64), nullable=False)
    title: Mapped[str | None] = mapped_column(String(255))
    document_reference: Mapped[str | None] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    scholarship_associations: Mapped[list["ScholarshipSource"]] = relationship(
        back_populates="source",
        cascade="all, delete-orphan",
    )

    __table_args__ = (
        UniqueConstraint("source_url", name="uq_official_sources_url"),
        Index("ix_official_sources_authority", "authority"),
        CheckConstraint(
            "length(source_url) > 0",
            name="ck_official_sources_url_not_empty",
        ),
        CheckConstraint(
            "source_type IN ('government_api', 'government_portal', "
            "'government_department', 'official_notification', "
            "'official_pdf', 'other_authority')",
            name="ck_official_sources_source_type",
        ),
    )


class ScholarshipSource(Base):
    __tablename__ = "scholarship_sources"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    scholarship_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("scholarships.id", ondelete="CASCADE"),
        nullable=False,
    )
    source_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("official_sources.id", ondelete="CASCADE"),
        nullable=False,
    )
    verification_status: Mapped[str] = mapped_column(
        String(32),
        nullable=False,
        default=VerificationStatus.PENDING_VERIFICATION.value,
        server_default=VerificationStatus.PENDING_VERIFICATION.value,
    )
    last_verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    verified_by: Mapped[str | None] = mapped_column(String(255))
    notes: Mapped[str | None] = mapped_column(Text())

    scholarship: Mapped["Scholarship"] = relationship(
        back_populates="source_associations"
    )
    source: Mapped["OfficialSource"] = relationship(
        back_populates="scholarship_associations"
    )

    __table_args__ = (
        UniqueConstraint(
            "scholarship_id",
            "source_id",
            name="uq_scholarship_source",
        ),
        Index(
            "ix_scholarship_sources_status_verified",
            "verification_status",
            "last_verified_at",
        ),
        CheckConstraint(
            "verification_status IN ('collected', 'extracted', "
            "'pending_validation', 'pending_verification', 'verified', "
            "'approved', 'rejected', 'archived')",
            name="ck_scholarship_sources_verification_status",
        ),
    )


class SavedScholarship(Base):
    __tablename__ = "saved_scholarships"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    scholarship_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("scholarships.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        server_default=func.now(),
        nullable=False,
    )

    scholarship: Mapped["Scholarship"] = relationship(lazy="joined")

    __table_args__ = (
        UniqueConstraint("user_id", "scholarship_id", name="uq_saved_scholarships_user_scholarship"),
    )

