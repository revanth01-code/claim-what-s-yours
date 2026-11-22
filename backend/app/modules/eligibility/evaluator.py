"""Deterministic Eligibility Evaluator.

Implements zero-hallucination, explainable, rule-based matching
between StudentProfile and EligibilityCriteria.
Authority: Eligibility criteria in PostgreSQL. No LLM decision-making.
"""

from decimal import Decimal
from typing import Any

from app.modules.eligibility.models import EligibilityCriteria
from app.modules.profiles.models import StudentProfile
from app.schemas.eligibility import (
    ConditionEvaluation,
    EligibilityEvaluationResult,
    EligibilityStatus,
)


def evaluate_eligibility(
    profile: StudentProfile | None,
    criteria: EligibilityCriteria | None,
    scholarship_name: str = "Scholarship",
) -> EligibilityEvaluationResult:
    """Evaluate a student's profile against structured scholarship eligibility criteria."""
    if criteria is None:
        return EligibilityEvaluationResult(
            scholarship_id=getattr(profile, "id", None) or criteria,  # placeholder
            scholarship_name=scholarship_name,
            status="uncertain",
            summary="Eligibility criteria have not yet been defined for this scholarship.",
            is_criteria_verified=False,
        )

    matched: list[str] = []
    unmet: list[str] = []
    missing: list[str] = []
    evaluations: list[ConditionEvaluation] = []

    # If criteria is not verified by admin, result must be uncertain
    if not criteria.is_verified:
        return EligibilityEvaluationResult(
            scholarship_id=criteria.scholarship_id,
            scholarship_name=scholarship_name,
            status="uncertain",
            summary="Official eligibility criteria are pending administrative verification.",
            is_criteria_verified=False,
        )

    if profile is None:
        return EligibilityEvaluationResult(
            scholarship_id=criteria.scholarship_id,
            scholarship_name=scholarship_name,
            status="needs_more_information",
            summary="Please complete your student profile to check eligibility.",
            missing_fields=["profile"],
            is_criteria_verified=True,
        )

    # 1. State / Domicile Check
    if criteria.domicile_state:
        req_state = criteria.domicile_state.strip().lower()
        stu_state = (profile.state or "").strip().lower() if profile.state else None
        if not stu_state:
            missing.append("state")
            evaluations.append(
                ConditionEvaluation(
                    field="state",
                    criterion=f"Must be a resident of {criteria.domicile_state}",
                    student_value=None,
                    passed=None,
                    reason="State of domicile is missing in profile",
                )
            )
        elif stu_state == req_state:
            matched.append(f"Domicile in {criteria.domicile_state}")
            evaluations.append(
                ConditionEvaluation(
                    field="state",
                    criterion=f"Must be a resident of {criteria.domicile_state}",
                    student_value=profile.state,
                    passed=True,
                    reason=f"Resident of {profile.state}",
                )
            )
        else:
            unmet.append(f"Requires domicile in {criteria.domicile_state} (Profile has {profile.state})")
            evaluations.append(
                ConditionEvaluation(
                    field="state",
                    criterion=f"Must be a resident of {criteria.domicile_state}",
                    student_value=profile.state,
                    passed=False,
                    reason=f"Profile state ({profile.state}) does not match required {criteria.domicile_state}",
                )
            )

    # 2. Category Check (SC, ST, OBC, General, etc.)
    if criteria.categories:
        req_cats = [c.strip().lower() for c in criteria.categories]
        stu_cat = (profile.category or "").strip().lower() if profile.category else None
        if not stu_cat:
            missing.append("category")
            evaluations.append(
                ConditionEvaluation(
                    field="category",
                    criterion=f"Must belong to categories: {', '.join(criteria.categories)}",
                    student_value=None,
                    passed=None,
                    reason="Social category is not specified in profile",
                )
            )
        elif stu_cat in req_cats:
            matched.append(f"Category {profile.category} eligible")
            evaluations.append(
                ConditionEvaluation(
                    field="category",
                    criterion=f"Categories: {', '.join(criteria.categories)}",
                    student_value=profile.category,
                    passed=True,
                    reason=f"Belongs to eligible category {profile.category}",
                )
            )
        else:
            unmet.append(f"Category {profile.category} does not qualify ({', '.join(criteria.categories)})")
            evaluations.append(
                ConditionEvaluation(
                    field="category",
                    criterion=f"Categories: {', '.join(criteria.categories)}",
                    student_value=profile.category,
                    passed=False,
                    reason=f"Category {profile.category} is not in eligible categories",
                )
            )

    # 3. Family Income Check (Maximum limit)
    if criteria.maximum_family_income is not None:
        max_income = float(criteria.maximum_family_income)
        stu_income = float(profile.annual_family_income) if profile.annual_family_income is not None else None
        if stu_income is None:
            missing.append("annual_family_income")
            evaluations.append(
                ConditionEvaluation(
                    field="annual_family_income",
                    criterion=f"Annual family income <= ₹{max_income:,.2f}",
                    student_value=None,
                    passed=None,
                    reason="Annual family income not provided in profile",
                )
            )
        elif stu_income <= max_income:
            matched.append(f"Annual family income (₹{stu_income:,.0f}) within limit of ₹{max_income:,.0f}")
            evaluations.append(
                ConditionEvaluation(
                    field="annual_family_income",
                    criterion=f"Income <= ₹{max_income:,.2f}",
                    student_value=stu_income,
                    passed=True,
                    reason=f"Family income ₹{stu_income:,.2f} is within threshold",
                )
            )
        else:
            unmet.append(f"Annual family income (₹{stu_income:,.0f}) exceeds ₹{max_income:,.0f}")
            evaluations.append(
                ConditionEvaluation(
                    field="annual_family_income",
                    criterion=f"Income <= ₹{max_income:,.2f}",
                    student_value=stu_income,
                    passed=False,
                    reason=f"Family income ₹{stu_income:,.2f} exceeds threshold ₹{max_income:,.2f}",
                )
            )

    # 4. Minimum Academic Percentage
    if criteria.minimum_academic_percentage is not None:
        min_pct = float(criteria.minimum_academic_percentage)
        stu_pct = float(profile.previous_exam_percentage) if profile.previous_exam_percentage is not None else None
        if stu_pct is None:
            missing.append("previous_exam_percentage")
            evaluations.append(
                ConditionEvaluation(
                    field="previous_exam_percentage",
                    criterion=f"Minimum academic score >= {min_pct}%",
                    student_value=None,
                    passed=None,
                    reason="Previous examination percentage not provided in profile",
                )
            )
        elif stu_pct >= min_pct:
            matched.append(f"Academic score ({stu_pct}%) meets minimum requirement of {min_pct}%")
            evaluations.append(
                ConditionEvaluation(
                    field="previous_exam_percentage",
                    criterion=f"Score >= {min_pct}%",
                    student_value=stu_pct,
                    passed=True,
                    reason=f"Score {stu_pct}% meets or exceeds {min_pct}%",
                )
            )
        else:
            unmet.append(f"Academic score ({stu_pct}%) is below required {min_pct}%")
            evaluations.append(
                ConditionEvaluation(
                    field="previous_exam_percentage",
                    criterion=f"Score >= {min_pct}%",
                    student_value=stu_pct,
                    passed=False,
                    reason=f"Score {stu_pct}% is below required {min_pct}%",
                )
            )

    # 5. Education Levels (e.g. Higher Secondary, Undergraduate, Postgraduate)
    if criteria.education_levels:
        req_levels = [lvl.strip().lower() for lvl in criteria.education_levels]
        stu_level = (profile.education_level or "").strip().lower() if profile.education_level else None
        if not stu_level:
            missing.append("education_level")
            evaluations.append(
                ConditionEvaluation(
                    field="education_level",
                    criterion=f"Education level must be: {', '.join(criteria.education_levels)}",
                    student_value=None,
                    passed=None,
                    reason="Education level missing in profile",
                )
            )
        elif stu_level in req_levels:
            matched.append(f"Education level ({profile.education_level}) qualifies")
            evaluations.append(
                ConditionEvaluation(
                    field="education_level",
                    criterion=f"Education levels: {', '.join(criteria.education_levels)}",
                    student_value=profile.education_level,
                    passed=True,
                    reason=f"Current education level {profile.education_level} is eligible",
                )
            )
        else:
            unmet.append(f"Education level ({profile.education_level}) does not qualify ({', '.join(criteria.education_levels)})")
            evaluations.append(
                ConditionEvaluation(
                    field="education_level",
                    criterion=f"Education levels: {', '.join(criteria.education_levels)}",
                    student_value=profile.education_level,
                    passed=False,
                    reason=f"Level {profile.education_level} is not in eligible education levels",
                )
            )

    # 6. Gender Restriction
    if criteria.gender_restriction and criteria.gender_restriction.strip().lower() not in ("all", "any", "none"):
        req_gen = criteria.gender_restriction.strip().lower()
        stu_gen = (profile.gender or "").strip().lower() if profile.gender else None
        if not stu_gen:
            missing.append("gender")
            evaluations.append(
                ConditionEvaluation(
                    field="gender",
                    criterion=f"Gender requirement: {criteria.gender_restriction}",
                    student_value=None,
                    passed=None,
                    reason="Gender not provided in profile",
                )
            )
        elif stu_gen == req_gen:
            matched.append(f"Gender requirement ({profile.gender}) met")
            evaluations.append(
                ConditionEvaluation(
                    field="gender",
                    criterion=f"Gender: {criteria.gender_restriction}",
                    student_value=profile.gender,
                    passed=True,
                    reason=f"Gender {profile.gender} matches requirement",
                )
            )
        else:
            unmet.append(f"Restricted to {criteria.gender_restriction} (Profile has {profile.gender})")
            evaluations.append(
                ConditionEvaluation(
                    field="gender",
                    criterion=f"Gender: {criteria.gender_restriction}",
                    student_value=profile.gender,
                    passed=False,
                    reason=f"Gender {profile.gender} does not match {criteria.gender_restriction}",
                )
            )

    # 7. Disability Requirement
    if criteria.disability_required is True:
        stu_dis = profile.is_disabled
        if stu_dis is None:
            missing.append("is_disabled")
            evaluations.append(
                ConditionEvaluation(
                    field="is_disabled",
                    criterion="Candidate must have Persons with Disabilities (PwD) status",
                    student_value=None,
                    passed=None,
                    reason="Disability status not provided in profile",
                )
            )
        elif stu_dis is True:
            matched.append("Persons with Disabilities (PwD) requirement met")
            evaluations.append(
                ConditionEvaluation(
                    field="is_disabled",
                    criterion="Candidate must have PwD status",
                    student_value=True,
                    passed=True,
                    reason="Candidate has PwD status",
                )
            )
        else:
            unmet.append("Requires Persons with Disabilities (PwD) status")
            evaluations.append(
                ConditionEvaluation(
                    field="is_disabled",
                    criterion="Candidate must have PwD status",
                    student_value=False,
                    passed=False,
                    reason="Profile does not have PwD status",
                )
            )

    # Precedence: ineligible > needs_more_information > uncertain > eligible
    if len(unmet) > 0:
        status: EligibilityStatus = "ineligible"
        summary = f"You do not currently meet {len(unmet)} requirement(s) for this scholarship."
    elif len(missing) > 0:
        status = "needs_more_information"
        summary = f"Missing {len(missing)} profile detail(s) needed to verify eligibility."
    else:
        status = "eligible"
        summary = f"Congratulations! You satisfy all {len(matched)} verified eligibility criteria."

    return EligibilityEvaluationResult(
        scholarship_id=criteria.scholarship_id,
        scholarship_name=scholarship_name,
        status=status,
        summary=summary,
        matched_conditions=matched,
        unmet_conditions=unmet,
        missing_fields=missing,
        detailed_evaluations=evaluations,
        is_criteria_verified=True,
    )
