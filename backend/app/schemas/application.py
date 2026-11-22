"""Pydantic schemas for student application tracking."""

import uuid
from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field

ApplicationStatus = Literal[
    "interested",
    "preparing",
    "draft",
    "submitted",
    "under_review",
    "approved",
    "disbursed",
    "rejected",
    "withdrawn",
]


class ApplicationTimelineEvent(BaseModel):
    status: ApplicationStatus
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    note: str | None = None


class ApplicationRecordCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    scholarship_id: uuid.UUID
    portal_name: str = Field(min_length=2, max_length=128)
    application_reference_number: str = Field(min_length=2, max_length=128)
    status: ApplicationStatus = "submitted"
    academic_year: str = Field(default="2026-2027", max_length=32)
    applied_amount: float | None = Field(default=None, ge=0.0)
    notes: str | None = Field(default=None, max_length=1000)
    submitted_at: datetime | None = None


class ApplicationRecordUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    status: ApplicationStatus | None = None
    application_reference_number: str | None = Field(default=None, min_length=2, max_length=128)
    applied_amount: float | None = Field(default=None, ge=0.0)
    disbursed_amount: float | None = Field(default=None, ge=0.0)
    notes: str | None = Field(default=None, max_length=1000)


class ApplicationRecordResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, extra="ignore")

    id: uuid.UUID
    user_id: uuid.UUID
    scholarship_id: uuid.UUID
    scholarship_name: str
    portal_name: str
    application_reference_number: str
    status: ApplicationStatus
    academic_year: str
    applied_amount: float | None = None
    disbursed_amount: float | None = None
    notes: str | None = None
    submitted_at: datetime | None = None
    timeline: list[dict[str, Any]] = []
    created_at: datetime
    updated_at: datetime

