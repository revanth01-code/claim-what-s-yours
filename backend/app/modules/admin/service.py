"""Domain service for scholarship review, verification, criteria management, and publication."""

from datetime import date, datetime, timezone
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.modules.admin.models import AuditAction, VerificationAuditLog
from app.modules.eligibility.models import EligibilityCriteria
from app.modules.scholarships.models import (
    OfficialSource,
    Scholarship,
    ScholarshipAcademicYear,
    ScholarshipSource,
    VerificationStatus,
)
from app.modules.users.models import User
from app.schemas.admin import (
    AdminCriteriaCreateRequest,
    AdminCriteriaReviewRequest,
    AdminCriteriaUpdateRequest,
    AdminSourceReviewRequest,
)


class VerificationError(ValueError):
    """Raised when a verification transition or publication rule is violated."""


def get_pending_scholarships(
    session: Session,
    skip: int = 0,
    limit: int = 50,
) -> tuple[list[Scholarship], int]:
    """Return inactive (pending publication) scholarships."""
    query = (
        select(Scholarship)
        .where(Scholarship.is_active.is_(False))
        .options(
            selectinload(Scholarship.source_associations).selectinload(ScholarshipSource.source),
            selectinload(Scholarship.eligibility_criteria),
            selectinload(Scholarship.academic_year_associations),
        )
        .order_by(Scholarship.created_at.desc())
    )
    total = session.scalar(select(func.count()).select_from(query.subquery())) or 0
    items = list(session.scalars(query.offset(skip).limit(limit)))
    return items, total


def review_source(
    session: Session,
    scholarship_id: UUID,
    source_id: UUID,
    admin: User,
    request: AdminSourceReviewRequest,
) -> ScholarshipSource:
    """Verify or reject a source association for a scholarship, optionally updating source metadata."""
    query = (
        select(ScholarshipSource)
        .where(
            ScholarshipSource.scholarship_id == scholarship_id,
            ScholarshipSource.source_id == source_id,
        )
        .options(
            selectinload(ScholarshipSource.source),
            selectinload(ScholarshipSource.scholarship),
        )
    )
    if session.bind and session.bind.dialect.name == "postgresql":
        query = query.with_for_update()

    assoc = session.scalar(query)
    if not assoc:
        raise VerificationError("Source association not found for this scholarship.")

    valid_statuses = {VerificationStatus.VERIFIED.value, VerificationStatus.REJECTED.value}
    if request.status not in valid_statuses:
        raise VerificationError(f"Invalid verification status '{request.status}'. Allowed: {valid_statuses}")

    # State machine check: rejected sources cannot be reverified
    if assoc.verification_status == VerificationStatus.REJECTED.value:
        raise VerificationError("A rejected source cannot be re-verified. Create a new source record instead.")

    # Check for cascade effects: if rejecting a previously verified source while scholarship is active
    old_status = assoc.verification_status
    new_status = request.status

    # Update association
    assoc.verification_status = new_status
    assoc.verified_by = admin.email or str(admin.id)
    assoc.last_verified_at = datetime.now(timezone.utc)
    if request.notes:
        assoc.notes = request.notes

    # Update official source metadata if provided
    source = assoc.source
    if request.authority:
        source.authority = request.authority.strip()
    if request.title:
        source.title = request.title.strip()
    if request.document_reference:
        source.document_reference = request.document_reference.strip()

    # Record audit log for source review
    action = AuditAction.SOURCE_VERIFY if new_status == VerificationStatus.VERIFIED.value else AuditAction.SOURCE_REJECT
    log = VerificationAuditLog(
        scholarship_id=scholarship_id,
        admin_user_id=admin.id,
        action=action.value,
        target_type="source",
        target_id=source_id,
        notes=request.notes,
        details={
            "old_status": old_status,
            "status": new_status,
            "source_url": source.source_url,
            "authority": source.authority,
        },
    )
    session.add(log)

    # If status transitioned to rejected, verify if the active scholarship must be automatically unpublished
    if new_status == VerificationStatus.REJECTED.value:
        scholarship = assoc.scholarship or session.get(Scholarship, scholarship_id)
        if scholarship and scholarship.is_active:
            other_verified_count = session.scalar(
                select(func.count())
                .select_from(ScholarshipSource)
                .where(
                    ScholarshipSource.scholarship_id == scholarship_id,
                    ScholarshipSource.source_id != source_id,
                    ScholarshipSource.verification_status.in_(
                        [VerificationStatus.VERIFIED.value, VerificationStatus.APPROVED.value]
                    ),
                )
            ) or 0
            if other_verified_count == 0:
                scholarship.is_active = False
                unpublish_log = VerificationAuditLog(
                    scholarship_id=scholarship_id,
                    admin_user_id=admin.id,
                    action=AuditAction.SCHOLARSHIP_UNPUBLISH.value,
                    target_type="scholarship",
                    target_id=scholarship.id,
                    notes="Automatically unpublished: all verified sources have been revoked or rejected.",
                    details={"auto_unpublish": True, "trigger_source_id": str(source_id)},
                )
                session.add(unpublish_log)

    return assoc


def add_or_update_criteria(
    session: Session,
    scholarship_id: UUID,
    admin: User,
    request: AdminCriteriaCreateRequest | AdminCriteriaUpdateRequest,
    criteria_id: UUID | None = None,
) -> EligibilityCriteria:
    """Add new eligibility criteria or update existing criteria for a scholarship.

    Creating criteria always sets is_verified=False.
    Updating criteria resets is_verified=False, requiring re-approval via review_criteria.
    """
    scholarship = session.get(Scholarship, scholarship_id)
    if not scholarship:
        raise VerificationError("Scholarship not found.")

    revoked_verification = False
    if criteria_id:
        criteria = session.get(EligibilityCriteria, criteria_id)
        if not criteria or criteria.scholarship_id != scholarship_id:
            raise VerificationError("Eligibility criteria not found for this scholarship.")
        if criteria.is_verified:
            revoked_verification = True
        action = AuditAction.CRITERIA_UPDATE
    else:
        criteria = EligibilityCriteria(scholarship_id=scholarship_id)
        session.add(criteria)
        action = AuditAction.CRITERIA_CREATE

    criteria.academic_year_id = request.academic_year_id
    criteria.minimum_academic_percentage = request.minimum_academic_percentage
    criteria.maximum_academic_percentage = request.maximum_academic_percentage
    criteria.minimum_family_income = request.minimum_family_income
    criteria.maximum_family_income = request.maximum_family_income
    criteria.education_levels = request.education_levels
    criteria.courses = request.courses
    criteria.institution_requirements = request.institution_requirements
    criteria.categories = request.categories
    criteria.domicile_state = request.domicile_state
    criteria.gender_restriction = request.gender_restriction
    criteria.disability_required = request.disability_required
    criteria.renewal_only = request.renewal_only
    criteria.other_conditions = request.other_conditions
    criteria.source_reference = request.source_reference
    criteria.is_verified = False  # Strict approval gate: create/update cannot mark verified

    session.flush()

    log = VerificationAuditLog(
        scholarship_id=scholarship_id,
        admin_user_id=admin.id,
        action=action.value,
        target_type="criteria",
        target_id=criteria.id,
        notes=request.notes,
        details={
            "is_verified": False,
            "verification_revoked": revoked_verification,
        },
    )
    session.add(log)
    return criteria


def review_criteria(
    session: Session,
    scholarship_id: UUID,
    criteria_id: UUID,
    admin: User,
    request: AdminCriteriaReviewRequest,
) -> EligibilityCriteria:
    """Approve or reject (un-verify) specific eligibility criteria."""
    criteria = session.get(EligibilityCriteria, criteria_id)
    if not criteria or criteria.scholarship_id != scholarship_id:
        raise VerificationError("Eligibility criteria not found for this scholarship.")

    criteria.is_verified = request.is_verified
    action = AuditAction.CRITERIA_APPROVE if request.is_verified else AuditAction.CRITERIA_REJECT

    log = VerificationAuditLog(
        scholarship_id=scholarship_id,
        admin_user_id=admin.id,
        action=action.value,
        target_type="criteria",
        target_id=criteria.id,
        notes=request.notes,
        details={"is_verified": request.is_verified},
    )
    session.add(log)
    return criteria


def publish_scholarship(
    session: Session,
    scholarship_id: UUID,
    admin: User,
    notes: str | None = None,
) -> Scholarship:
    """Publish an inactive scholarship after verifying all publication gates.

    Publication Gates:
    1. Scholarship must exist.
    2. At least one source must have verification_status == 'verified' or 'approved'.
    3. At least one eligibility criteria record must be present and ALL eligibility criteria must be verified.
    4. At least one valid, unexpired academic year association must exist.
    """
    if session.bind and session.bind.dialect.name == "postgresql":
        query = (
            select(Scholarship)
            .where(Scholarship.id == scholarship_id)
            .with_for_update()
            .options(
                selectinload(Scholarship.source_associations),
                selectinload(Scholarship.eligibility_criteria),
                selectinload(Scholarship.academic_year_associations).selectinload(ScholarshipAcademicYear.academic_year),
            )
        )
        scholarship = session.scalar(query)
    else:
        scholarship = session.get(
            Scholarship,
            scholarship_id,
            options=[
                selectinload(Scholarship.source_associations),
                selectinload(Scholarship.eligibility_criteria),
                selectinload(Scholarship.academic_year_associations).selectinload(ScholarshipAcademicYear.academic_year),
            ],
        )

    if not scholarship:
        raise VerificationError("Scholarship not found.")

    # Idempotent publish
    if scholarship.is_active:
        return scholarship

    # Gate 1: Sources evidence
    if not scholarship.source_associations:
        raise VerificationError("Cannot publish scholarship without official source evidence.")

    has_verified_source = any(
        assoc.verification_status in (VerificationStatus.VERIFIED.value, VerificationStatus.APPROVED.value)
        for assoc in scholarship.source_associations
    )
    if not has_verified_source:
        raise VerificationError(
            "Cannot publish scholarship: at least one official source must be verified or approved."
        )

    # Gate 2: Reviewed eligibility information
    if not scholarship.eligibility_criteria:
        raise VerificationError(
            "Cannot publish scholarship without reviewed eligibility criteria."
        )

    all_criteria_verified = all(
        crit.is_verified for crit in scholarship.eligibility_criteria
    )
    if not all_criteria_verified:
        raise VerificationError(
            "Cannot publish scholarship: all eligibility criteria must be reviewed and verified."
        )

    # Gate 3: Academic year association and expiry check
    if not scholarship.academic_year_associations:
        raise VerificationError(
            "Cannot publish scholarship without an associated academic year."
        )

    today = date.today()
    valid_ay_found = False
    for assoc in scholarship.academic_year_associations:
        if not assoc.is_available:
            continue
        if assoc.closing_date is not None and assoc.closing_date < today:
            continue
        ay = assoc.academic_year
        if ay and ay.ends_on is not None and ay.ends_on < today:
            continue
        valid_ay_found = True
        break

    if not valid_ay_found:
        raise VerificationError(
            "Cannot publish scholarship: no active, unexpired academic year association found."
        )

    # Activate scholarship
    scholarship.is_active = True

    log = VerificationAuditLog(
        scholarship_id=scholarship_id,
        admin_user_id=admin.id,
        action=AuditAction.SCHOLARSHIP_PUBLISH.value,
        target_type="scholarship",
        target_id=scholarship.id,
        notes=notes,
        details={"is_active": True},
    )
    session.add(log)
    return scholarship


def unpublish_scholarship(
    session: Session,
    scholarship_id: UUID,
    admin: User,
    notes: str | None = None,
) -> Scholarship:
    """Deactivate/unpublish a scholarship."""
    if session.bind and session.bind.dialect.name == "postgresql":
        scholarship = session.scalar(
            select(Scholarship).where(Scholarship.id == scholarship_id).with_for_update()
        )
    else:
        scholarship = session.get(Scholarship, scholarship_id)

    if not scholarship:
        raise VerificationError("Scholarship not found.")

    # Idempotent unpublish
    if not scholarship.is_active:
        return scholarship

    scholarship.is_active = False

    log = VerificationAuditLog(
        scholarship_id=scholarship_id,
        admin_user_id=admin.id,
        action=AuditAction.SCHOLARSHIP_UNPUBLISH.value,
        target_type="scholarship",
        target_id=scholarship.id,
        notes=notes,
        details={"is_active": False},
    )
    session.add(log)
    return scholarship


def get_audit_logs(
    session: Session,
    scholarship_id: UUID,
) -> list[VerificationAuditLog]:
    """Retrieve the audit trail for a scholarship ordered chronologically."""
    query = (
        select(VerificationAuditLog)
        .where(VerificationAuditLog.scholarship_id == scholarship_id)
        .order_by(VerificationAuditLog.created_at.asc())
    )
    return list(session.scalars(query))
