"""Public scholarship catalog endpoints."""

from typing import Literal
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.session import get_db_session
from app.modules.scholarships.models import (
    Scholarship,
    ScholarshipAcademicYear,
    ScholarshipSource,
)
from app.modules.scholarships.service import (
    SortField,
    SortOrder,
    get_scholarship,
    list_scholarships,
)
from app.schemas.scholarship import (
    AcademicYearAvailabilityResponse,
    EligibilityCriteriaResponse,
    OfficialSourceResponse,
    ScholarshipListMeta,
    ScholarshipListResponse,
    ScholarshipResponse,
)

router = APIRouter(prefix="/scholarships", tags=["scholarships"])

CategoryFilter = Literal[
    "general",
    "sc",
    "st",
    "obc",
    "ebc",
    "minority",
    "economically_weaker",
    "disability",
    "merit",
    "other",
]


def _eligibility_response(criteria) -> EligibilityCriteriaResponse:
    return EligibilityCriteriaResponse.model_validate({
        "id": criteria.id,
        "academic_year_id": criteria.academic_year_id,
        "minimum_academic_percentage": criteria.minimum_academic_percentage,
        "maximum_academic_percentage": criteria.maximum_academic_percentage,
        "minimum_family_income": criteria.minimum_family_income,
        "maximum_family_income": criteria.maximum_family_income,
        "education_levels": criteria.education_levels,
        "courses": criteria.courses,
        "institution_requirements": criteria.institution_requirements,
        "categories": criteria.categories,
        "domicile_state": criteria.domicile_state,
        "gender_restriction": criteria.gender_restriction,
        "disability_required": criteria.disability_required,
        "renewal_only": criteria.renewal_only,
        "other_conditions": criteria.other_conditions,
        "source_reference": criteria.source_reference,
        "is_verified": criteria.is_verified,
    })


def _academic_year_response(
    association: ScholarshipAcademicYear,
) -> AcademicYearAvailabilityResponse:
    return AcademicYearAvailabilityResponse(
        academic_year=association.academic_year.year,
        starts_on=association.academic_year.starts_on,
        ends_on=association.academic_year.ends_on,
        is_available=association.is_available,
        opening_date=association.opening_date,
        closing_date=association.closing_date,
        name_override=association.name_override,
        description_override=association.description_override,
        benefits_override=association.benefits_override,
        application_url_override=association.application_url_override,
    )


def _source_response(
    association: ScholarshipSource,
) -> OfficialSourceResponse:
    return OfficialSourceResponse(
        id=association.source.id,
        source_url=association.source.source_url,
        authority=association.source.authority,
        source_type=association.source.source_type,
        title=association.source.title,
        document_reference=association.source.document_reference,
        verification_status=association.verification_status,
        last_verified_at=association.last_verified_at,
        verified_by=association.verified_by,
    )


def _scholarship_response(scholarship: Scholarship) -> ScholarshipResponse:
    return ScholarshipResponse(
        id=scholarship.id,
        name=scholarship.name,
        slug=scholarship.slug,
        description=scholarship.description,
        administering_authority=scholarship.administering_authority,
        category=scholarship.category,
        benefits=scholarship.benefits,
        application_url=scholarship.application_url,
        is_active=scholarship.is_active,
        created_at=scholarship.created_at,
        updated_at=scholarship.updated_at,
        eligibility_criteria=[
            _eligibility_response(criteria)
            for criteria in scholarship.eligibility_criteria
        ],
        academic_years=[
            _academic_year_response(association)
            for association in scholarship.academic_year_associations
        ],
        sources=[
            _source_response(association)
            for association in scholarship.source_associations
        ],
    )


@router.get("", response_model=ScholarshipListResponse)
def get_scholarships(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    search: str | None = Query(default=None, max_length=200),
    academic_year: str | None = Query(default=None, max_length=20),
    category: CategoryFilter | None = None,
    education_level: str | None = Query(default=None, max_length=100),
    sort_by: SortField = Query(default="name"),
    sort_order: SortOrder = Query(default="asc"),
    session: Session = Depends(get_db_session),
) -> ScholarshipListResponse:
    """List active scholarships with pagination and supported filters."""
    items, total, total_pages = list_scholarships(
        session,
        page=page,
        page_size=page_size,
        search=search,
        academic_year=academic_year,
        category=category,
        education_level=education_level,
        sort_by=sort_by,
        sort_order=sort_order,
    )
    return ScholarshipListResponse(
        data=[_scholarship_response(item) for item in items],
        meta=ScholarshipListMeta(
            page=page,
            page_size=page_size,
            total=total,
            total_pages=total_pages,
        ),
    )


@router.get("/{scholarship_id}", response_model=ScholarshipResponse)
def get_scholarship_detail(
    scholarship_id: UUID,
    session: Session = Depends(get_db_session),
) -> ScholarshipResponse:
    """Retrieve one active scholarship."""
    scholarship = get_scholarship(session, scholarship_id)
    if scholarship is None:
        raise HTTPException(status_code=404, detail="Scholarship not found")
    return _scholarship_response(scholarship)
