"""Scholarship database module."""

from app.modules.scholarships.models import (
    AcademicYear,
    OfficialSource,
    Scholarship,
    ScholarshipAcademicYear,
    ScholarshipSource,
)

__all__ = [
    "AcademicYear",
    "OfficialSource",
    "Scholarship",
    "ScholarshipAcademicYear",
    "ScholarshipSource",
]