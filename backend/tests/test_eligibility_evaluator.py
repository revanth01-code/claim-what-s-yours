"""Unit tests for deterministic eligibility evaluator."""

import uuid
from decimal import Decimal
import pytest

from app.modules.eligibility.evaluator import evaluate_eligibility
from app.modules.eligibility.models import EligibilityCriteria
from app.modules.profiles.models import StudentProfile


def test_unverified_criteria_produces_uncertain():
    criteria = EligibilityCriteria(
        id=uuid.uuid4(),
        scholarship_id=uuid.uuid4(),
        is_verified=False,
    )
    profile = StudentProfile(user_id=uuid.uuid4(), state="Maharashtra")
    res = evaluate_eligibility(profile, criteria, "Test Scholarship")
    assert res.status == "uncertain"
    assert "pending administrative verification" in res.summary


def test_missing_profile_data_produces_needs_more_information():
    criteria = EligibilityCriteria(
        id=uuid.uuid4(),
        scholarship_id=uuid.uuid4(),
        domicile_state="Karnataka",
        maximum_family_income=Decimal("250000.00"),
        is_verified=True,
    )
    profile = StudentProfile(
        user_id=uuid.uuid4(),
        state="Karnataka",
        annual_family_income=None,  # Missing!
    )
    res = evaluate_eligibility(profile, criteria, "Test Scholarship")
    assert res.status == "needs_more_information"
    assert "annual_family_income" in res.missing_fields
    assert len(res.matched_conditions) == 1


def test_ineligible_precedence():
    criteria = EligibilityCriteria(
        id=uuid.uuid4(),
        scholarship_id=uuid.uuid4(),
        domicile_state="Kerala",
        maximum_family_income=Decimal("250000.00"),
        minimum_academic_percentage=Decimal("75.00"),
        is_verified=True,
    )
    profile = StudentProfile(
        user_id=uuid.uuid4(),
        state="Kerala",
        annual_family_income=300000.0,  # Exceeds max!
        previous_exam_percentage=None,  # Missing!
    )
    res = evaluate_eligibility(profile, criteria, "Test Scholarship")
    # Even though percentage is missing, unmet income must make it ineligible (ineligible > needs_more_info)
    assert res.status == "ineligible"
    assert len(res.unmet_conditions) == 1
    assert "income" in res.unmet_conditions[0].lower()


def test_fully_eligible_evaluation():
    criteria = EligibilityCriteria(
        id=uuid.uuid4(),
        scholarship_id=uuid.uuid4(),
        domicile_state="Telangana",
        categories=["sc", "st"],
        maximum_family_income=Decimal("200000.00"),
        minimum_academic_percentage=Decimal("60.00"),
        education_levels=["undergraduate", "postgraduate"],
        gender_restriction="female",
        is_verified=True,
    )
    profile = StudentProfile(
        user_id=uuid.uuid4(),
        state="Telangana",
        category="sc",
        annual_family_income=150000.0,
        previous_exam_percentage=82.5,
        education_level="undergraduate",
        gender="female",
    )
    res = evaluate_eligibility(profile, criteria, "Telangana Merit Postmatric")
    assert res.status == "eligible"
    assert len(res.unmet_conditions) == 0
    assert len(res.missing_fields) == 0
    assert len(res.matched_conditions) == 6
