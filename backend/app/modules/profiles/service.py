"""Service layer for student profile operations."""

import uuid
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.profiles.models import StudentProfile
from app.modules.users.models import User
from app.schemas.profile import (
    ProfileCompletionResponse,
    SectionCompletion,
    StudentProfileUpdate,
)

# Core required fields per section for onboarding/eligibility calculation
SECTION_FIELDS = {
    "Personal": [
        ("full_name", "Full Name"),
        ("date_of_birth", "Date of Birth"),
        ("state", "State"),
        ("district", "District"),
        ("category", "Category"),
    ],
    "Academic": [
        ("education_level", "Education Level"),
        ("course", "Course"),
        ("institution_name", "Institution Name"),
        ("academic_year", "Academic Year"),
        ("previous_exam_percentage", "Previous Exam Percentage"),
    ],
    "Financial": [
        ("annual_family_income", "Annual Family Income"),
    ],
}


def get_profile_by_user_id(session: Session, user_id: uuid.UUID) -> StudentProfile | None:
    """Retrieve student profile by user ID."""
    stmt = select(StudentProfile).where(StudentProfile.user_id == user_id)
    return session.scalar(stmt)


def get_or_create_profile(session: Session, user: User) -> StudentProfile:
    """Retrieve existing profile or create an empty one for the user."""
    profile = get_profile_by_user_id(session, user.id)
    if not profile:
        profile = StudentProfile(
            user_id=user.id,
            full_name=user.display_name,
        )
        session.add(profile)
        session.flush()
    return profile


def update_profile(
    session: Session, user: User, update_data: StudentProfileUpdate
) -> StudentProfile:
    """Update student profile with validated data."""
    profile = get_or_create_profile(session, user)

    # Exclude unset fields from payload
    data_dict = update_data.model_dump(exclude_unset=True)
    for key, value in data_dict.items():
        if hasattr(profile, key):
            setattr(profile, key, value)

    # Synchronize display_name on User if full_name was provided
    if update_data.full_name and update_data.full_name.strip():
        user.display_name = update_data.full_name.strip()

    session.flush()
    return profile


def calculate_completion(profile: StudentProfile | None) -> ProfileCompletionResponse:
    """Calculate granular and overall profile completion metrics."""
    if not profile:
        sections = [
            SectionCompletion(
                name=name,
                is_completed=False,
                completed_fields=0,
                total_fields=len(fields),
                missing_fields=[f[1] for f in fields],
            )
            for name, fields in SECTION_FIELDS.items()
        ]
        return ProfileCompletionResponse(
            percentage=0,
            is_onboarding_completed=False,
            sections=sections,
        )

    sections: list[SectionCompletion] = []
    total_required = 0
    total_completed = 0

    for section_name, fields in SECTION_FIELDS.items():
        completed = 0
        missing = []
        for field_key, field_label in fields:
            total_required += 1
            val = getattr(profile, field_key, None)
            if val is not None and str(val).strip() != "":
                completed += 1
                total_completed += 1
            else:
                missing.append(field_label)

        sections.append(
            SectionCompletion(
                name=section_name,
                is_completed=len(missing) == 0,
                completed_fields=completed,
                total_fields=len(fields),
                missing_fields=missing,
            )
        )

    percentage = int((total_completed / total_required) * 100) if total_required > 0 else 0
    # Onboarding is completed when all sections have their minimum fields filled
    is_onboarding_completed = all(s.is_completed for s in sections)

    return ProfileCompletionResponse(
        percentage=percentage,
        is_onboarding_completed=is_onboarding_completed,
        sections=sections,
    )
