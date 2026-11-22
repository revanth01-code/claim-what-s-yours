"""Tests for student in-app notifications."""

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
from app.modules.notifications.models import Notification
from app.modules.notifications.service import NotificationService
from app.modules.users.models import User
from app.schemas.notification import NotificationCreate


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
        email=f"notify_{uuid.uuid4().hex[:6]}@example.com",
        display_name="Notification Student",
        role="student",
        is_active=True,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


def test_notification_service_and_endpoints(
    db_session: Session, sample_user: User
) -> None:
    service = NotificationService(db_session)

    # 1. Create two notifications
    n1 = service.create_notification(
        sample_user.id,
        NotificationCreate(
            title="Deadline Approaching",
            message="Post-Matric registration closes on 31-March-2027.",
            notification_type="deadline_approaching",
            link_url="/scholarships/post-matric",
        ),
    )
    n2 = service.create_notification(
        sample_user.id,
        NotificationCreate(
            title="Application Status Updated",
            message="Your application NSP-2026-998877 is now Under Review.",
            notification_type="application_status_update",
        ),
    )

    # 2. Check unread count
    assert service.get_unread_count(sample_user.id) == 2

    # 3. Test API endpoints
    app = create_app()
    app.dependency_overrides[get_db_session] = lambda: db_session
    app.dependency_overrides[get_current_user] = lambda: sample_user

    with TestClient(app) as client:
        # Unread count endpoint
        cnt_res = client.get("/api/v1/notifications/me/unread-count")
        assert cnt_res.status_code == 200
        assert cnt_res.json()["unread_count"] == 2

        # List notifications
        list_res = client.get("/api/v1/notifications/me")
        assert list_res.status_code == 200
        assert len(list_res.json()) == 2

        # Mark single as read
        patch_res = client.patch(f"/api/v1/notifications/me/{n1.id}/read")
        assert patch_res.status_code == 200
        assert patch_res.json()["is_read"] is True

        # Unread count is now 1
        cnt_res2 = client.get("/api/v1/notifications/me/unread-count")
        assert cnt_res2.json()["unread_count"] == 1

        # Read all
        read_all_res = client.post("/api/v1/notifications/me/read-all")
        assert read_all_res.status_code == 200
        assert read_all_res.json()["unread_count"] == 0

        # Unread count is now 0
        cnt_res3 = client.get("/api/v1/notifications/me/unread-count")
        assert cnt_res3.json()["unread_count"] == 0
