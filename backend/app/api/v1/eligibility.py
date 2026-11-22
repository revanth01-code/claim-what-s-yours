"""API router for deterministic eligibility evaluation."""

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.db.session import get_db_session
from app.modules.auth.dependencies import get_current_user
from app.modules.eligibility.evaluator import evaluate_eligibility
from app.modules.profiles.models import StudentProfile
from app.modules.scholarships.models import Scholarship
from app.modules.users.models import User
from app.schemas.eligibility import (
    EligibilityEvaluationResult,
    StudentBatchEligibilityResponse,
)

router = APIRouter(prefix="/eligibility", tags=["eligibility"])


@router.get("/me", response_model=StudentBatchEligibilityResponse)
def get_my_batch_eligibility(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db_session)],
) -> StudentBatchEligibilityResponse:
    profile = db.scalar(select(StudentProfile).where(StudentProfile.user_id == current_user.id))

    stmt = (
        select(Scholarship)
        .options(selectinload(Scholarship.eligibility_criteria))
        .where(Scholarship.is_active.is_(True))
        .order_by(Scholarship.name)
    )
    scholarships = list(db.scalars(stmt).all())

    evaluations: list[EligibilityEvaluationResult] = []
    eligible_count = 0
    needs_info_count = 0
    ineligible_count = 0
    uncertain_count = 0

    for sch in scholarships:
        res = evaluate_eligibility(profile, sch.eligibility_criteria, sch.name)
        # Ensure scholarship_id is set
        res.scholarship_id = sch.id
        evaluations.append(res)
        if res.status == "eligible":
            eligible_count += 1
        elif res.status == "needs_more_information":
            needs_info_count += 1
        elif res.status == "ineligible":
            ineligible_count += 1
        else:
            uncertain_count += 1

    return StudentBatchEligibilityResponse(
        evaluations=evaluations,
        total_evaluated=len(scholarships),
        eligible_count=eligible_count,
        needs_info_count=needs_info_count,
        ineligible_count=ineligible_count,
        uncertain_count=uncertain_count,
    )


@router.get("/me/{scholarship_id}", response_model=EligibilityEvaluationResult)
def get_my_scholarship_eligibility(
    scholarship_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db_session)],
) -> EligibilityEvaluationResult:
    profile = db.scalar(select(StudentProfile).where(StudentProfile.user_id == current_user.id))

    stmt = (
        select(Scholarship)
        .options(selectinload(Scholarship.eligibility_criteria))
        .where(Scholarship.id == scholarship_id)
    )
    sch = db.scalars(stmt).one_or_none()
    if not sch:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Scholarship {scholarship_id} not found.",
        )

    res = evaluate_eligibility(profile, sch.eligibility_criteria, sch.name)
    res.scholarship_id = sch.id
    return res
