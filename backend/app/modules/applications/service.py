"""Service layer for student scholarship application tracking."""

import uuid
from datetime import datetime
from decimal import Decimal
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.modules.applications.models import ApplicationRecord
from app.modules.scholarships.models import Scholarship
from app.schemas.application import (
    ApplicationRecordCreate,
    ApplicationRecordResponse,
    ApplicationRecordUpdate,
)


class ApplicationService:
    def __init__(self, session: Session) -> None:
        self.session = session

    def list_applications(self, user_id: uuid.UUID) -> list[ApplicationRecord]:
        stmt = (
            select(ApplicationRecord)
            .options(selectinload(ApplicationRecord.scholarship))
            .where(ApplicationRecord.user_id == user_id)
            .order_by(ApplicationRecord.created_at.desc())
        )
        return list(self.session.scalars(stmt).all())

    def get_application(self, application_id: uuid.UUID, user_id: uuid.UUID) -> ApplicationRecord:
        stmt = (
            select(ApplicationRecord)
            .options(selectinload(ApplicationRecord.scholarship))
            .where(
                ApplicationRecord.id == application_id,
                ApplicationRecord.user_id == user_id,
            )
        )
        app_record = self.session.scalars(stmt).one_or_none()
        if not app_record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Application record {application_id} not found.",
            )
        return app_record

    def create_application(
        self, user_id: uuid.UUID, payload: ApplicationRecordCreate
    ) -> ApplicationRecord:
        scholarship = self.session.get(Scholarship, payload.scholarship_id)
        if not scholarship:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Scholarship {payload.scholarship_id} not found.",
            )

        now = datetime.utcnow()
        submitted_at = payload.submitted_at or now
        timeline = [
            {
                "status": "submitted",
                "timestamp": submitted_at.isoformat(),
                "note": payload.notes or "Application tracked in Claim What's Yours",
            }
        ]

        app_record = ApplicationRecord(
            user_id=user_id,
            scholarship_id=payload.scholarship_id,
            portal_name=payload.portal_name,
            application_reference_number=payload.application_reference_number,
            status="submitted",
            academic_year=payload.academic_year,
            applied_amount=Decimal(str(payload.applied_amount)) if payload.applied_amount is not None else None,
            notes=payload.notes,
            submitted_at=submitted_at,
            timeline=timeline,
        )
        self.session.add(app_record)
        self.session.commit()
        self.session.refresh(app_record)
        return app_record

    def update_application(
        self, application_id: uuid.UUID, user_id: uuid.UUID, payload: ApplicationRecordUpdate
    ) -> ApplicationRecord:
        app_record = self.get_application(application_id, user_id)

        now = datetime.utcnow()
        if payload.status and payload.status != app_record.status:
            app_record.status = payload.status
            new_timeline = list(app_record.timeline)
            new_timeline.append(
                {
                    "status": payload.status,
                    "timestamp": now.isoformat(),
                    "note": payload.notes or f"Status updated to {payload.status}",
                }
            )
            app_record.timeline = new_timeline

        if payload.application_reference_number is not None:
            app_record.application_reference_number = payload.application_reference_number
        if payload.applied_amount is not None:
            app_record.applied_amount = Decimal(str(payload.applied_amount))
        if payload.disbursed_amount is not None:
            app_record.disbursed_amount = Decimal(str(payload.disbursed_amount))
        if payload.notes is not None:
            app_record.notes = payload.notes

        app_record.updated_at = now
        self.session.commit()
        self.session.refresh(app_record)
        return app_record
