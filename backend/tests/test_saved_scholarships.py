"""Tests for saved/bookmarked scholarships."""

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
from app.modules.scholarships.models import SavedScholarship, Scholarship
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
def sample_user(db_session: Session) -> User:
    user = User(
        firebase_uid=f"firebase_{uuid.uuid4().hex[:8]}",
        email=f"saver_{uuid.uuid4().hex[:6]}@example.com",
        display_name="Saved Student",
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
        name="Telangana Post-Matric ePASS",
        slug=f"telangana-post-matric-epass-{uuid.uuid4().hex[:6]}",
        administering_authority="Telangana ePASS",
        category="sc",
        is_active=True,
    )
    db_session.add(sch)
    db_session.commit()
    db_session.refresh(sch)
    return sch


def test_save_and_unsave_scholarship_lifecycle(
    db_session: Session, sample_user: User, sample_scholarship: Scholarship
) -> None:
    app = create_app()
    app.dependency_overrides[get_db_session] = lambda: db_session
    app.dependency_overrides[get_current_user] = lambda: sample_user

    with TestClient(app) as client:
        # 1. Initially not saved
        chk1 = client.get(f"/api/v1/scholarships/{sample_scholarship.id}/is-saved")
        assert chk1.status_code == 200
        assert chk1.json()["is_saved"] is False

        # 2. List saved is empty
        list_res = client.get("/api/v1/scholarships/saved")
        assert list_res.status_code == 200
        assert list_res.json() == []

        # 3. Save it
        save_res = client.post(f"/api/v1/scholarships/{sample_scholarship.id}/save")
        assert save_res.status_code == 201
        assert save_res.json()["saved"] is True

        # 4. Check is-saved is now True
        chk2 = client.get(f"/api/v1/scholarships/{sample_scholarship.id}/is-saved")
        assert chk2.status_code == 200
        assert chk2.json()["is_saved"] is True

        # 5. List saved contains the scholarship
        list_res2 = client.get("/api/v1/scholarships/saved")
        assert list_res2.status_code == 200
        assert len(list_res2.json()) == 1
        assert list_res2.json()[0]["id"] == str(sample_scholarship.id)

        # 6. Saving again is idempotent
        save_res_dup = client.post(f"/api/v1/scholarships/{sample_scholarship.id}/save")
        assert save_res_dup.status_code == 201

        # 7. Unsave it
        del_res = client.delete(f"/api/v1/scholarships/{sample_scholarship.id}/save")
        assert del_res.status_code == 200
        assert del_res.json()["saved"] is False

        # 8. List saved is empty again
        list_res3 = client.get("/api/v1/scholarships/saved")
        assert list_res3.status_code == 200
        assert list_res3.json() == []
