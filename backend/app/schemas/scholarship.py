"""Pydantic response contracts for scholarship catalog APIs."""

from datetime import date, datetime
from decimal import Decimal
from typing import Any
from uuid import UUID

from pydantic import BaseModel


class EligibilityCriteriaResponse(BaseModel):
    id: UUID
    academic_year_id: UUID | None
    minimum_academic_percentage: Decimal | None
    maximum_academic_percentage: Decimal | None
    minimum_family_income: Decimal | None
    maximum_family_income: Decimal | None
    education_levels: list[str] | None
    courses: list[str] | None
    institution_requirements: dict[str, Any] | None
    categories: list[str] | None
    domicile_state: str | None
    gender_restriction: str | None
    disability_required: bool | None
    renewal_only: bool
    other_conditions: dict[str, Any] | None
    source_reference: str | None
    is_verified: bool

    model_config = {"from_attributes": True}


class AcademicYearAvailabilityResponse(BaseModel):
    academic_year: str
    starts_on: date | None
    ends_on: date | None
    is_available: bool
    opening_date: date | None
    closing_date: date | None
    name_override: str | None
    description_override: str | None
    benefits_override: list[dict[str, Any]] | dict[str, Any] | None
    application_url_override: str | None


class OfficialSourceResponse(BaseModel):
    id: UUID
    source_url: str
    authority: str
    source_type: str
    title: str | None
    document_reference: str | None
    verification_status: str
    last_verified_at: datetime | None
    verified_by: str | None

    model_config = {"from_attributes": True}


class ScholarshipResponse(BaseModel):
    id: UUID
    name: str
    slug: str
    description: str | None
    administering_authority: str
    category: str
    benefits: list[dict[str, Any]] | dict[str, Any] | None
    application_url: str | None
    is_active: bool
    created_at: datetime
    updated_at: datetime
    eligibility_criteria: list[EligibilityCriteriaResponse]
    academic_years: list[AcademicYearAvailabilityResponse]
    sources: list[OfficialSourceResponse]


class ScholarshipListMeta(BaseModel):
    page: int
    page_size: int
    total: int
    total_pages: int


class ScholarshipListResponse(BaseModel):
    data: list[ScholarshipResponse]
    meta: ScholarshipListMeta
