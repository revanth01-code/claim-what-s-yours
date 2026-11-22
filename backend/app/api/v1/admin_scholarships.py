"""Administrator scholarship verification and publication endpoints."""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.v1.scholarships import (
    _academic_year_response,
    _eligibility_response,
    _source_response,
)
from app.db.session import get_db_session
from app.modules.auth.dependencies import require_admin
from app.modules.admin.service import (
    VerificationError,
    add_or_update_criteria,
    get_audit_logs,
    get_pending_scholarships,
    publish_scholarship,
    review_criteria,
    review_source,
    unpublish_scholarship,
)
from app.modules.users.models import User
from app.schemas.admin import (
    AdminCriteriaCreateRequest,
    AdminCriteriaReviewRequest,
    AdminCriteriaUpdateRequest,
    AdminPublishRequest,
    AdminSourceReviewRequest,
    VerificationAuditLogResponse,
)
from app.schemas.scholarship import (
    EligibilityCriteriaResponse,
    OfficialSourceResponse,
    ScholarshipListMeta,
    ScholarshipListResponse,
    ScholarshipResponse,
)

router = APIRouter(prefix="/admin/scholarships", tags=["admin-scholarships"])


def _to_scholarship_response(scholarship) -> ScholarshipResponse:
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
            _eligibility_response(c) for c in scholarship.eligibility_criteria
        ],
        academic_years=[
            _academic_year_response(ay)
            for ay in scholarship.academic_year_associations
        ],
        sources=[_source_response(s) for s in scholarship.source_associations],
    )


@router.get("/pending", response_model=ScholarshipListResponse)
def list_pending(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    admin: User = Depends(require_admin),
    session: Session = Depends(get_db_session),
) -> ScholarshipListResponse:
    """List pending (inactive) scholarships awaiting verification or publication."""
    skip = (page - 1) * page_size
    items, total = get_pending_scholarships(session, skip=skip, limit=page_size)
    total_pages = (total + page_size - 1) // page_size if total > 0 else 0
    return ScholarshipListResponse(
        data=[_to_scholarship_response(s) for s in items],
        meta=ScholarshipListMeta(
            page=page,
            page_size=page_size,
            total=total,
            total_pages=total_pages,
        ),
    )


@router.post("/{scholarship_id}/sources/{source_id}/review", response_model=OfficialSourceResponse)
def review_scholarship_source(
    scholarship_id: UUID,
    source_id: UUID,
    request: AdminSourceReviewRequest,
    admin: User = Depends(require_admin),
    session: Session = Depends(get_db_session),
) -> OfficialSourceResponse:
    """Verify or reject a source association for a scholarship."""
    try:
        assoc = review_source(session, scholarship_id, source_id, admin, request)
        session.commit()
        return _source_response(assoc)
    except VerificationError as exc:
        session.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))


@router.post("/{scholarship_id}/criteria", response_model=EligibilityCriteriaResponse)
def create_criteria(
    scholarship_id: UUID,
    request: AdminCriteriaCreateRequest,
    admin: User = Depends(require_admin),
    session: Session = Depends(get_db_session),
) -> EligibilityCriteriaResponse:
    """Add new eligibility criteria to a scholarship."""
    try:
        criteria = add_or_update_criteria(session, scholarship_id, admin, request)
        session.commit()
        return _eligibility_response(criteria)
    except VerificationError as exc:
        session.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))


@router.put("/{scholarship_id}/criteria/{criteria_id}", response_model=EligibilityCriteriaResponse)
def update_criteria(
    scholarship_id: UUID,
    criteria_id: UUID,
    request: AdminCriteriaUpdateRequest,
    admin: User = Depends(require_admin),
    session: Session = Depends(get_db_session),
) -> EligibilityCriteriaResponse:
    """Update existing eligibility criteria for a scholarship."""
    try:
        criteria = add_or_update_criteria(session, scholarship_id, admin, request, criteria_id=criteria_id)
        session.commit()
        return _eligibility_response(criteria)
    except VerificationError as exc:
        session.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))


@router.post("/{scholarship_id}/criteria/{criteria_id}/review", response_model=EligibilityCriteriaResponse)
def review_scholarship_criteria(
    scholarship_id: UUID,
    criteria_id: UUID,
    request: AdminCriteriaReviewRequest,
    admin: User = Depends(require_admin),
    session: Session = Depends(get_db_session),
) -> EligibilityCriteriaResponse:
    """Approve or reject (un-verify) specific eligibility criteria."""
    try:
        criteria = review_criteria(session, scholarship_id, criteria_id, admin, request)
        session.commit()
        return _eligibility_response(criteria)
    except VerificationError as exc:
        session.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))


@router.post("/{scholarship_id}/publish", response_model=ScholarshipResponse)
def publish(
    scholarship_id: UUID,
    request: AdminPublishRequest | None = None,
    admin: User = Depends(require_admin),
    session: Session = Depends(get_db_session),
) -> ScholarshipResponse:
    """Explicitly publish an inactive scholarship once verified source and eligibility gates pass."""
    notes = request.notes if request else None
    try:
        scholarship = publish_scholarship(session, scholarship_id, admin, notes=notes)
        session.commit()
        return _to_scholarship_response(scholarship)
    except VerificationError as exc:
        session.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))


@router.post("/{scholarship_id}/unpublish", response_model=ScholarshipResponse)
def unpublish(
    scholarship_id: UUID,
    request: AdminPublishRequest | None = None,
    admin: User = Depends(require_admin),
    session: Session = Depends(get_db_session),
) -> ScholarshipResponse:
    """Unpublish (deactivate) an active scholarship."""
    notes = request.notes if request else None
    try:
        scholarship = unpublish_scholarship(session, scholarship_id, admin, notes=notes)
        session.commit()
        return _to_scholarship_response(scholarship)
    except VerificationError as exc:
        session.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))


@router.get("/{scholarship_id}/audit-logs", response_model=list[VerificationAuditLogResponse])
def audit_logs(
    scholarship_id: UUID,
    admin: User = Depends(require_admin),
    session: Session = Depends(get_db_session),
) -> list[VerificationAuditLogResponse]:
    """Retrieve full verification and publication audit trail for a scholarship."""
    logs = get_audit_logs(session, scholarship_id)
    return [VerificationAuditLogResponse.model_validate(log) for log in logs]
