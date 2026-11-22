"""Pydantic schemas for deterministic eligibility evaluation."""

import uuid
from typing import Any, Literal
from pydantic import BaseModel, ConfigDict, Field

EligibilityStatus = Literal[
    "eligible",
    "ineligible",
    "needs_more_information",
    "uncertain",
]


class ConditionEvaluation(BaseModel):
    field: str
    criterion: str
    student_value: Any = None
    passed: bool | None = None  # None if missing info or uncertain
    reason: str


class EligibilityEvaluationResult(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    scholarship_id: uuid.UUID
    scholarship_name: str
    status: EligibilityStatus
    summary: str
    matched_conditions: list[str] = []
    unmet_conditions: list[str] = []
    missing_fields: list[str] = []
    detailed_evaluations: list[ConditionEvaluation] = []
    is_criteria_verified: bool = False


class StudentBatchEligibilityResponse(BaseModel):
    evaluations: list[EligibilityEvaluationResult]
    total_evaluated: int
    eligible_count: int
    needs_info_count: int
    ineligible_count: int
    uncertain_count: int
