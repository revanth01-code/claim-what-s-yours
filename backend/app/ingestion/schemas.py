"""Validated input contracts for scholarship imports."""

from datetime import date, datetime
from decimal import Decimal
from typing import Any
from urllib.parse import urlsplit, urlunsplit
import re
import unicodedata

from pydantic import AnyHttpUrl, BaseModel, ConfigDict, Field, field_validator, model_validator

from app.modules.scholarships.models import (
    ScholarshipCategory,
    SourceType,
    VerificationStatus,
)


def normalize_text(value: str) -> str:
    """Collapse whitespace without changing the source meaning."""
    return " ".join(value.split())


def normalize_slug(value: str) -> str:
    """Return a stable ASCII slug suitable for the scholarship unique key."""
    normalized = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode()
    normalized = re.sub(r"[^a-zA-Z0-9]+", "-", normalized.lower()).strip("-")
    if not normalized:
        raise ValueError("slug must contain at least one alphanumeric character")
    return normalized


def normalize_url(value: AnyHttpUrl) -> str:
    """Normalize URLs used as stable source identifiers."""
    parsed = urlsplit(str(value))
    if parsed.username or parsed.password:
        raise ValueError("URLs containing user information are not allowed")
    path = parsed.path.rstrip("/") or "/"
    return urlunsplit(
        (parsed.scheme.lower(), parsed.netloc.lower(), path, parsed.query, "")
    )


class ImportAcademicYear(BaseModel):
    """Year-specific scholarship availability information."""

    model_config = ConfigDict(extra="forbid")

    year: str = Field(min_length=1, max_length=20)
    starts_on: date | None = None
    ends_on: date | None = None
    is_available: bool = False
    opening_date: date | None = None
    closing_date: date | None = None
    name_override: str | None = Field(default=None, max_length=255)
    description_override: str | None = None
    benefits_override: list[dict[str, Any]] | dict[str, Any] | None = None
    application_url_override: AnyHttpUrl | None = None

    @field_validator("year", "name_override", "description_override")
    @classmethod
    def _normalize_text_fields(cls, value: str | None) -> str | None:
        return normalize_text(value) if value is not None else None

    @field_validator("application_url_override")
    @classmethod
    def _normalize_application_url(cls, value: AnyHttpUrl | None) -> AnyHttpUrl | None:
        return AnyHttpUrl(normalize_url(value)) if value is not None else None

    @model_validator(mode="after")
    def _validate_dates(self) -> "ImportAcademicYear":
        if self.starts_on and self.ends_on and self.ends_on < self.starts_on:
            raise ValueError("ends_on must not be before starts_on")
        if self.opening_date and self.closing_date and self.closing_date < self.opening_date:
            raise ValueError("closing_date must not be before opening_date")
        return self


class ImportEligibilityCriteria(BaseModel):
    """Structured, non-evaluated eligibility information."""

    model_config = ConfigDict(extra="forbid")

    academic_year: str | None = Field(default=None, max_length=20)
    minimum_academic_percentage: Decimal | None = Field(default=None, ge=0, le=100)
    maximum_academic_percentage: Decimal | None = Field(default=None, ge=0, le=100)
    minimum_family_income: Decimal | None = Field(default=None, ge=0)
    maximum_family_income: Decimal | None = Field(default=None, ge=0)
    education_levels: list[str] | None = None
    courses: list[str] | None = None
    institution_requirements: dict[str, Any] | None = None
    categories: list[str] | None = None
    domicile_state: str | None = None
    gender_restriction: str | None = None
    disability_required: bool | None = None
    renewal_only: bool = False
    other_conditions: dict[str, Any] | None = None
    source_reference: str | None = None
    is_verified: bool = False

    @field_validator("academic_year", "domicile_state", "gender_restriction", "source_reference")
    @classmethod
    def _normalize_optional_text(cls, value: str | None) -> str | None:
        return normalize_text(value) if value is not None else None

    @model_validator(mode="after")
    def _validate_ranges(self) -> "ImportEligibilityCriteria":
        if (
            self.minimum_academic_percentage is not None
            and self.maximum_academic_percentage is not None
            and self.maximum_academic_percentage < self.minimum_academic_percentage
        ):
            raise ValueError("maximum academic percentage must not be lower than minimum")
        if (
            self.minimum_family_income is not None
            and self.maximum_family_income is not None
            and self.maximum_family_income < self.minimum_family_income
        ):
            raise ValueError("maximum family income must not be lower than minimum")
        return self


class ImportSource(BaseModel):
    """An official source and its import-time verification state."""

    model_config = ConfigDict(extra="forbid")

    source_url: AnyHttpUrl
    authority: str = Field(min_length=1, max_length=255)
    source_type: SourceType
    title: str | None = Field(default=None, max_length=255)
    document_reference: str | None = Field(default=None, max_length=255)
    verification_status: VerificationStatus = VerificationStatus.PENDING_VERIFICATION
    last_verified_at: datetime | None = None
    verified_by: str | None = Field(default=None, max_length=255)
    notes: str | None = None

    @field_validator("source_url")
    @classmethod
    def _normalize_source_url(cls, value: AnyHttpUrl) -> AnyHttpUrl:
        return AnyHttpUrl(normalize_url(value))

    @field_validator("authority", "title", "document_reference", "verified_by", "notes")
    @classmethod
    def _normalize_source_text(cls, value: str | None) -> str | None:
        return normalize_text(value) if value is not None else None


class ImportScholarship(BaseModel):
    """One complete scholarship record accepted by the importer."""

    model_config = ConfigDict(extra="forbid")

    name: str = Field(min_length=1, max_length=255)
    slug: str | None = Field(default=None, max_length=255)
    description: str | None = None
    administering_authority: str = Field(min_length=1, max_length=255)
    category: ScholarshipCategory
    benefits: list[dict[str, Any]] | dict[str, Any] | None = None
    application_url: AnyHttpUrl | None = None
    is_active: bool | None = None
    academic_years: list[ImportAcademicYear] = Field(default_factory=list)
    eligibility_criteria: list[ImportEligibilityCriteria] = Field(default_factory=list)
    sources: list[ImportSource] = Field(min_length=1)

    @field_validator("name", "description", "administering_authority")
    @classmethod
    def _normalize_required_text(cls, value: str | None) -> str | None:
        return normalize_text(value) if value is not None else None

    @field_validator("slug")
    @classmethod
    def _normalize_slug(cls, value: str | None) -> str | None:
        return normalize_slug(value) if value is not None else None

    @field_validator("application_url")
    @classmethod
    def _normalize_application_url(cls, value: AnyHttpUrl | None) -> AnyHttpUrl | None:
        return AnyHttpUrl(normalize_url(value)) if value is not None else None

    @model_validator(mode="after")
    def _derive_and_validate(self) -> "ImportScholarship":
        if self.slug is None:
            self.slug = normalize_slug(self.name)
        years = {item.year for item in self.academic_years}
        for criteria in self.eligibility_criteria:
            if criteria.academic_year is not None and criteria.academic_year not in years:
                raise ValueError(
                    f"eligibility criterion references missing academic year "
                    f"{criteria.academic_year!r}"
                )
        criteria_years = [
            criteria.academic_year for criteria in self.eligibility_criteria
        ]
        if len(criteria_years) != len(set(criteria_years)):
            raise ValueError("duplicate eligibility criteria for an academic year")
        source_urls = [normalize_url(source.source_url) for source in self.sources]
        if len(source_urls) != len(set(source_urls)):
            raise ValueError("duplicate source URLs are not allowed within a record")
        return self


class ImportDataset(BaseModel):
    """A complete validated import payload."""

    model_config = ConfigDict(extra="forbid")

    scholarships: list[ImportScholarship] = Field(min_length=1)

    @model_validator(mode="after")
    def _validate_unique_slugs(self) -> "ImportDataset":
        slugs = [record.slug for record in self.scholarships]
        duplicates = sorted({slug for slug in slugs if slugs.count(slug) > 1})
        if duplicates:
            raise ValueError(f"duplicate scholarship slugs: {', '.join(duplicates)}")
        return self
