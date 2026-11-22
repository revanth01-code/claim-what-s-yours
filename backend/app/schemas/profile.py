"""Pydantic schemas for Student Profile and Completion."""

import uuid
from datetime import date, datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, field_validator


class StudentProfileBase(BaseModel):
    model_config = ConfigDict(extra="forbid")

    # Personal Information
    full_name: str | None = Field(default=None, max_length=255)
    date_of_birth: date | None = None
    gender: str | None = Field(default=None, max_length=32)
    state: str | None = Field(default=None, max_length=100)
    district: str | None = Field(default=None, max_length=100)
    category: str | None = Field(default=None, max_length=64)
    is_disabled: bool | None = None
    disability_type: str | None = Field(default=None, max_length=100)
    disability_percentage: float | None = Field(default=None, ge=0.0, le=100.0)
    phone_number: str | None = Field(default=None, max_length=20)

    # Academic Information
    education_level: str | None = Field(default=None, max_length=64)
    course: str | None = Field(default=None, max_length=128)
    stream: str | None = Field(default=None, max_length=128)
    institution_name: str | None = Field(default=None, max_length=255)
    institution_state: str | None = Field(default=None, max_length=100)
    institution_district: str | None = Field(default=None, max_length=100)
    board_or_university: str | None = Field(default=None, max_length=255)
    academic_year: str | None = Field(default=None, max_length=32)
    current_year_of_study: int | None = Field(default=None, ge=1, le=10)
    previous_exam_percentage: float | None = Field(default=None, ge=0.0, le=100.0)

    # Financial Information
    annual_family_income: float | None = Field(default=None, ge=0.0)
    income_bracket: str | None = Field(default=None, max_length=64)

    # Additional Information
    is_hosteller: bool | None = None
    additional_attributes: dict[str, Any] | None = None

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str | None) -> str | None:
        if v is not None:
            clean = v.strip().replace(" ", "").replace("-", "")
            if clean and not clean.replace("+", "").isdigit():
                raise ValueError("Phone number must contain only digits and optional leading +")
            return clean
        return None


class StudentProfileUpdate(StudentProfileBase):
    """Payload for creating or updating a student profile."""
    pass


class StudentProfileResponse(StudentProfileBase):
    """Full profile response."""
    model_config = ConfigDict(from_attributes=True, extra="ignore")

    id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime
    updated_at: datetime


class SectionCompletion(BaseModel):
    name: str
    is_completed: bool
    completed_fields: int
    total_fields: int
    missing_fields: list[str]


class ProfileCompletionResponse(BaseModel):
    percentage: int = Field(ge=0, le=100)
    is_onboarding_completed: bool
    sections: list[SectionCompletion]
