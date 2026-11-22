"""Tests for Student Profile backend API and business logic."""

import uuid
from collections.abc import Iterator
from datetime import date
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event
from sqlalchemy.engine import Connection, Engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.base import Base
from app.db.session import get_db_session
from app.main import create_app
from app.modules.auth.dependencies import get_current_user
from app.modules.profiles.models import StudentProfile
from app.modules.users.models import User


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
def test_student(db_session: Session) -> User:
    """Create a persistent student user."""
    student = User(
        id=uuid.uuid4(),
        firebase_uid=f"firebase-student-{uuid.uuid4()}",
        email="student.test@cwy.org",
        email_verified=True,
        display_name="Test Student",
        role="student",
        is_active=True,
    )
    db_session.add(student)
    db_session.commit()
    db_session.refresh(student)
    return student


@pytest.fixture
def other_student(db_session: Session) -> User:
    """Create another student user to test authorization isolation."""
    student = User(
        id=uuid.uuid4(),
        firebase_uid=f"firebase-other-{uuid.uuid4()}",
        email="other.student@cwy.org",
        email_verified=True,
        display_name="Other Student",
        role="student",
        is_active=True,
    )
    db_session.add(student)
    db_session.commit()
    db_session.refresh(student)
    return student


@pytest.fixture
def app_client(db_session: Session) -> Iterator[TestClient]:
    app = create_app()
    app.dependency_overrides[get_db_session] = lambda: db_session
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


def test_get_my_profile_empty(app_client: TestClient, test_student: User):
    """GET /api/v1/students/me/profile returns initial/default profile."""
    app_client.app.dependency_overrides[get_current_user] = lambda: test_student
    response = app_client.get("/api/v1/students/me/profile")
    assert response.status_code == 200
    data = response.json()
    assert data["user_id"] == str(test_student.id)
    assert data["full_name"] == "Test Student"
    assert data["education_level"] is None


def test_update_my_profile_and_calculate_completion(app_client: TestClient, test_student: User):
    """PUT updates profile and completion endpoint returns calculated progress."""
    app_client.app.dependency_overrides[get_current_user] = lambda: test_student

    # Check initial completion
    resp_comp_initial = app_client.get("/api/v1/students/me/profile/completion")
    assert resp_comp_initial.status_code == 200
    assert resp_comp_initial.json()["is_onboarding_completed"] is False
    assert resp_comp_initial.json()["percentage"] < 50

    # Update Personal & Academic & Financial
    payload = {
        "full_name": "Updated Student Name",
        "date_of_birth": "2004-05-15",
        "gender": "male",
        "state": "Telangana",
        "district": "Hyderabad",
        "category": "obc",
        "education_level": "undergraduate",
        "course": "B.Tech Computer Science",
        "institution_name": "JNTU Hyderabad",
        "academic_year": "2026-2027",
        "current_year_of_study": 3,
        "previous_exam_percentage": 84.5,
        "annual_family_income": 180000.0,
        "is_hosteller": True,
    }
    resp_update = app_client.put("/api/v1/students/me/profile", json=payload)
    assert resp_update.status_code == 200
    data = resp_update.json()
    assert data["full_name"] == "Updated Student Name"
    assert data["state"] == "Telangana"
    assert data["previous_exam_percentage"] == 84.5
    assert data["annual_family_income"] == 180000.0

    # Verify completion is now 100% and onboarding completed
    resp_comp_after = app_client.get("/api/v1/students/me/profile/completion")
    assert resp_comp_after.status_code == 200
    comp_data = resp_comp_after.json()
    assert comp_data["percentage"] == 100
    assert comp_data["is_onboarding_completed"] is True
    for section in comp_data["sections"]:
        assert section["is_completed"] is True
        assert len(section["missing_fields"]) == 0


def test_cross_user_profile_isolation(
    app_client: TestClient, test_student: User, other_student: User
):
    """Students can only read/update their own profile; no client-provided ID can override this."""
    # Student 1 updates profile
    app_client.app.dependency_overrides[get_current_user] = lambda: test_student
    app_client.put(
        "/api/v1/students/me/profile",
        json={"full_name": "Student One", "state": "Telangana"},
    )

    # Student 2 requests their profile
    app_client.app.dependency_overrides[get_current_user] = lambda: other_student
    resp = app_client.get("/api/v1/students/me/profile")
    assert resp.status_code == 200
    data = resp.json()
    assert data["user_id"] == str(other_student.id)
    assert data["user_id"] != str(test_student.id)
    assert data["state"] is None  # Student 2 does not see Student 1's state


def test_update_profile_validation_failures(app_client: TestClient, test_student: User):
    """Payloads violating constraints or types must fail with 422."""
    app_client.app.dependency_overrides[get_current_user] = lambda: test_student

    # Invalid percentage > 100
    resp = app_client.put(
        "/api/v1/students/me/profile",
        json={"previous_exam_percentage": 105.0},
    )
    assert resp.status_code == 422

    # Negative family income
    resp2 = app_client.put(
        "/api/v1/students/me/profile",
        json={"annual_family_income": -500.0},
    )
    assert resp2.status_code == 422

    # Invalid year of study
    resp3 = app_client.put(
        "/api/v1/students/me/profile",
        json={"current_year_of_study": 0},
    )
    assert resp3.status_code == 422


def test_unauthenticated_profile_access(app_client: TestClient):
    """Unauthenticated requests are rejected with 401."""
    resp = app_client.get("/api/v1/students/me/profile")
    assert resp.status_code == 401
