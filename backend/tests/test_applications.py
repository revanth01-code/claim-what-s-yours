"""Tests for student application tracking endpoints and service."""

import uuid
from collections.abc import Iterator
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event
from sqlalchemy.engine import Connection, Engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.base import Base
from app.db.session import get_db_session
from app.main import create_app
from app.modules.applications.service import ApplicationService
from app.modules.auth.dependencies import get_current_user
from app.modules.scholarships.models import Scholarship
from app.modules.users.models import User
from app.schemas.application import ApplicationRecordCreate, ApplicationRecordUpdate


@pytest.fixture
def sqlite_engine() -> Iterator[Engine]:
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    @event.listens_for(engine, "connect")
    def _disable_pysqlite_implicit_transactions(dbapi_connection: object, _record: object) -> None:
        dbapi_connection.isolation_level = None  # type: ignore[attr-defined]

    @event.listens_for(engine, "begin")
    def _emit_explicit_begin(connection: Connection) -> None:
        connection.exec_driver_sql("BEGIN")

    Base.metadata.create_all(engine)
    yield engine
    engine.dispose()


@pytest.fixture
def db_session(sqlite_engine: Engine) -> Iterator[Session]:
    session_factory = sessionmaker(bind=sqlite_engine, expire_on_commit=False)
    session = session_factory()
    yield session
    session.close()


@pytest.fixture
def sample_user(db_session: Session) -> User:
    user = User(
        firebase_uid=f"firebase_{uuid.uuid4().hex[:8]}",
        email=f"applicant_{uuid.uuid4().hex[:6]}@example.com",
        display_name="Test Applicant",
        role="student",
        is_active=True,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def sample_scholarship(db_session: Session) -> Scholarship:
    sch = Scholarship(
        name="Test Merit Scholarship",
        slug=f"test-merit-scholarship-{uuid.uuid4().hex[:6]}",
        administering_authority="Ministry of Education",
        category="merit",
        is_active=True,
    )
    db_session.add(sch)
    db_session.commit()
    db_session.refresh(sch)
    return sch


def test_application_service_lifecycle(
    db_session: Session, sample_user: User, sample_scholarship: Scholarship
) -> None:
    service = ApplicationService(db_session)

    # 1. Create application record
    create_payload = ApplicationRecordCreate(
        scholarship_id=sample_scholarship.id,
        portal_name="National Scholarship Portal",
        application_reference_number="NSP-2026-998877",
        academic_year="2026-2027",
        applied_amount=25000.0,
        notes="Applied with income certificate and caste certificate.",
    )

    created = service.create_application(sample_user.id, create_payload)
    assert created.portal_name == "National Scholarship Portal"
    assert created.application_reference_number == "NSP-2026-998877"
    assert created.status == "submitted"
    assert created.scholarship_name == "Test Merit Scholarship"
    assert len(created.timeline) == 1

    # 2. List applications
    apps = service.list_applications(sample_user.id)
    assert len(apps) == 1
    assert apps[0].id == created.id

    # 3. Update application status
    update_payload = ApplicationRecordUpdate(
        status="under_review",
        notes="Document verification in progress at state nodal office.",
    )
    updated = service.update_application(created.id, sample_user.id, update_payload)
    assert updated.status == "under_review"
    assert len(updated.timeline) == 2
    assert updated.timeline[-1]["status"] == "under_review"
    assert updated.notes == "Document verification in progress at state nodal office."


def test_application_api_endpoints(
    db_session: Session, sample_user: User, sample_scholarship: Scholarship
) -> None:
    app = create_app()
    app.dependency_overrides[get_db_session] = lambda: db_session
    app.dependency_overrides[get_current_user] = lambda: sample_user

    client = TestClient(app)

    # 1. Initially empty
    res = client.get("/api/v1/applications/me")
    assert res.status_code == 200
    assert res.json() == []

    # 2. Create application via API
    create_data = {
        "scholarship_id": str(sample_scholarship.id),
        "portal_name": "State Post-Matric Portal",
        "application_reference_number": "SPMP-445566",
        "academic_year": "2026-2027",
        "applied_amount": 18000.0,
        "notes": "Submitted with fee receipt.",
    }
    create_res = client.post("/api/v1/applications/me", json=create_data)
    assert create_res.status_code == 201
    created_id = create_res.json()["id"]

    # 3. Read it back
    get_res = client.get(f"/api/v1/applications/me/{created_id}")
    assert get_res.status_code == 200
    assert get_res.json()["application_reference_number"] == "SPMP-445566"

    # 4. Patch it
    patch_res = client.patch(
        f"/api/v1/applications/me/{created_id}",
        json={"status": "approved", "disbursed_amount": 18000.0},
    )
    assert patch_res.status_code == 200
    assert patch_res.json()["status"] == "approved"
    assert patch_res.json()["disbursed_amount"] == 18000.0
