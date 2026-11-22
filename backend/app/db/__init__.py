"""Database base, session, health and model registration helpers."""

from app.db.base import Base
from app.modules.admin.models import VerificationAuditLog
from app.modules.eligibility import EligibilityCriteria
from app.modules.profiles.models import StudentProfile
from app.modules.scholarships import (
    AcademicYear,
    OfficialSource,
    Scholarship,
    ScholarshipAcademicYear,
    ScholarshipSource,
)
from app.modules.users.models import User

__all__ = [
    "AcademicYear",
    "Base",
    "EligibilityCriteria",
    "OfficialSource",
    "Scholarship",
    "ScholarshipAcademicYear",
    "ScholarshipSource",
    "StudentProfile",
    "User",
    "VerificationAuditLog",
]
