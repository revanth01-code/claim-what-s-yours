"""Schemas for admin scholarship review, verification, criteria, and publication."""

from datetime import date, datetime
from decimal import Decimal
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field


class AdminSourceReviewRequest(BaseModel):
    status: str = Field(description="'verified' or 'rejected'")
    notes: str | None = None
    authority: str | None = Field(default=None, max_length=255)
    title: str | None = Field(default=None, max_length=255)
    document_reference: str | None = Field(default=None, max_length=255)

    model_config = {"extra": "forbid"}


class AdminCriteriaCreateRequest(BaseModel):
    academic_year_id: UUID | None = None
    minimum_academic_percentage: Decimal | None = None
    maximum_academic_percentage: Decimal | None = None
    minimum_family_income: Decimal | None = None
    maximum_family_income: Decimal | None = None
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
    notes: str | None = None

    model_config = {"extra": "forbid"}


class AdminCriteriaUpdateRequest(BaseModel):
    academic_year_id: UUID | None = None
    minimum_academic_percentage: Decimal | None = None
    maximum_academic_percentage: Decimal | None = None
    minimum_family_income: Decimal | None = None
    maximum_family_income: Decimal | None = None
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
    notes: str | None = None

    model_config = {"extra": "forbid"}


class AdminCriteriaReviewRequest(BaseModel):
    is_verified: bool
    notes: str | None = None

    model_config = {"extra": "forbid"}


class AdminPublishRequest(BaseModel):
    notes: str | None = None

    model_config = {"extra": "forbid"}


class VerificationAuditLogResponse(BaseModel):
    id: UUID
    scholarship_id: UUID | None = None
    admin_user_id: UUID
    action: str
    target_type: str
    target_id: UUID | None
    notes: str | None
    details: dict[str, Any] | None
    created_at: datetime

    model_config = {"from_attributes": True}
