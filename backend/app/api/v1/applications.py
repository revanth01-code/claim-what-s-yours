"""API router for student application tracking."""

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.db.session import get_db_session
from app.modules.applications.service import ApplicationService
from app.modules.auth.dependencies import get_current_user
from app.modules.users.models import User
from app.schemas.application import (
    ApplicationRecordCreate,
    ApplicationRecordResponse,
    ApplicationRecordUpdate,
)

router = APIRouter(prefix="/applications", tags=["applications"])


@router.get("/me", response_model=list[ApplicationRecordResponse])
def list_my_applications(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db_session)],
) -> list[ApplicationRecordResponse]:
    service = ApplicationService(db)
    return service.list_applications(current_user.id)


@router.post(
    "/me",
    response_model=ApplicationRecordResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_my_application(
    payload: ApplicationRecordCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db_session)],
) -> ApplicationRecordResponse:
    service = ApplicationService(db)
    return service.create_application(current_user.id, payload)


@router.get("/me/{application_id}", response_model=ApplicationRecordResponse)
def get_my_application(
    application_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db_session)],
) -> ApplicationRecordResponse:
    service = ApplicationService(db)
    return service.get_application(application_id, current_user.id)


@router.patch("/me/{application_id}", response_model=ApplicationRecordResponse)
def update_my_application(
    application_id: uuid.UUID,
    payload: ApplicationRecordUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db_session)],
) -> ApplicationRecordResponse:
    service = ApplicationService(db)
    return service.update_application(application_id, current_user.id, payload)
