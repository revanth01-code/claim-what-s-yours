"""Tests for AI Guidance service and endpoints."""

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
from app.modules.auth.dependencies import get_current_user
from app.modules.scholarships.models import Scholarship, OfficialSource, ScholarshipSource
from app.modules.users.models import User
from app.modules.profiles.models import StudentProfile


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
        email=f"ai_student_{uuid.uuid4().hex[:6]}@example.com",
        display_name="AI Student",
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
        name="PM-USP Central Sector Scheme",
        slug=f"pm-usp-csss-{uuid.uuid4().hex[:6]}",
        administering_authority="Department of Higher Education",
        category="merit",
        description="Merit-cum-means scholarship for college students.",
        application_url="https://scholarships.gov.in",
        is_active=True,
    )
    db_session.add(sch)
    db_session.commit()
    db_session.refresh(sch)
    return sch


@pytest.fixture
def app_client(db_session: Session) -> Iterator[TestClient]:
    app = create_app()
    app.dependency_overrides[get_db_session] = lambda: db_session
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


def test_ai_general_guidance(app_client: TestClient, sample_user: User):
    app_client.app.dependency_overrides[get_current_user] = lambda: sample_user

    res = app_client.post(
        "/api/v1/ai/guidance",
        json={"query": "How do I apply for scholarships?", "language": "en"},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["grounded"] is True
    assert "Claim What's Yours" in data["answer"]
    assert len(data["suggested_actions"]) > 0


def test_ai_scholarship_documents_multilingual(
    app_client: TestClient, sample_user: User, sample_scholarship: Scholarship
):
    app_client.app.dependency_overrides[get_current_user] = lambda: sample_user

    # English documents query
    res_en = app_client.post(
        "/api/v1/ai/guidance",
        json={
            "query": "What documents are required?",
            "scholarship_id": str(sample_scholarship.id),
            "language": "en",
        },
    )
    assert res_en.status_code == 200
    assert "Domicile" in res_en.json()["answer"]
    assert len(res_en.json()["citations"]) > 0

    # Telugu documents query
    res_te = app_client.post(
        "/api/v1/ai/guidance",
        json={
            "query": "దరఖాస్తు పత్రాలు ఏమిటి?",
            "scholarship_id": str(sample_scholarship.id),
            "language": "te",
        },
    )
    assert res_te.status_code == 200
    assert "నివాస ధృవీకరణ పత్రం" in res_te.json()["answer"]
