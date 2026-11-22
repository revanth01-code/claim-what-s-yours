"""Unit and integration tests for administrator provisioning CLI."""

import io
import sys
import uuid
import pytest
from sqlalchemy import create_engine, select
from sqlalchemy.orm import sessionmaker

from app.db.base import Base
import app.db  # noqa: F401
from app.modules.admin.models import AuditAction, VerificationAuditLog
from app.modules.admin.provision import grant_admin
from app.modules.users.models import User


@pytest.fixture
def test_db(monkeypatch):
    engine = create_engine("sqlite+pysqlite:///:memory:")
    Base.metadata.create_all(engine)
    TestingSession = sessionmaker(bind=engine, autoflush=False, autocommit=False)

    monkeypatch.setattr("app.modules.admin.provision.get_session_factory", lambda: TestingSession)

    with TestingSession() as session:
        user = User(
            id=uuid.uuid4(),
            firebase_uid="student-uid-123",
            email="student@example.org",
            email_verified=True,
            role="student",
            is_active=True,
        )
        unverified_user = User(
            id=uuid.uuid4(),
            firebase_uid="unverified-uid-456",
            email="unverified@example.org",
            email_verified=False,
            role="student",
            is_active=True,
        )
        disabled_user = User(
            id=uuid.uuid4(),
            firebase_uid="disabled-uid-789",
            email="disabled@example.org",
            email_verified=True,
            role="student",
            is_active=False,
        )
        admin_user = User(
            id=uuid.uuid4(),
            firebase_uid="admin-uid-999",
            email="admin@example.org",
            email_verified=True,
            role="admin",
            is_active=True,
        )
        session.add_all([user, unverified_user, disabled_user, admin_user])
        session.commit()

    yield TestingSession
    engine.dispose()


def test_inspect_user(test_db, capsys):
    code = grant_admin(email="student@example.org", inspect=True)
    assert code == 0
    captured = capsys.readouterr()
    assert "User Details:" in captured.out
    assert "student-uid-123" in captured.out
    assert "Role: student" in captured.out

    # Verify no DB modification
    with test_db() as session:
        u = session.scalar(select(User).where(User.email == "student@example.org"))
        assert u.role == "student"


def test_dry_run_promotion(test_db, capsys):
    code = grant_admin(email="  STUDENT@EXAMPLE.ORG  ", dry_run=True)
    assert code == 0
    captured = capsys.readouterr()
    assert "[DRY RUN]" in captured.out
    assert "Target Role: admin" in captured.out
    assert "No database changes committed" in captured.out

    # Verify no DB modification
    with test_db() as session:
        u = session.scalar(select(User).where(User.email == "student@example.org"))
        assert u.role == "student"
        logs = session.scalars(select(VerificationAuditLog)).all()
        assert len(logs) == 0


def test_confirm_promotion_success(test_db, capsys):
    code = grant_admin(email="student@example.org", confirm=True)
    assert code == 0
    captured = capsys.readouterr()
    assert "role updated to 'admin'" in captured.out

    with test_db() as session:
        u = session.scalar(select(User).where(User.email == "student@example.org"))
        assert u.role == "admin"
        logs = session.scalars(select(VerificationAuditLog)).all()
        assert len(logs) == 1
        assert logs[0].action == AuditAction.ADMIN_PROMOTE.value
        assert logs[0].admin_user_id == u.id
        assert logs[0].target_id == u.id


def test_refuses_disabled_user(test_db, capsys):
    code = grant_admin(email="disabled@example.org", confirm=True)
    assert code == 1
    captured = capsys.readouterr()
    assert "Cannot promote disabled user" in captured.err

    with test_db() as session:
        u = session.scalar(select(User).where(User.email == "disabled@example.org"))
        assert u.role == "student"


def test_refuses_unverified_email(test_db, capsys):
    code = grant_admin(email="unverified@example.org", confirm=True)
    assert code == 1
    captured = capsys.readouterr()
    assert "unverified email" in captured.err

    with test_db() as session:
        u = session.scalar(select(User).where(User.email == "unverified@example.org"))
        assert u.role == "student"


def test_user_already_admin(test_db, capsys):
    code = grant_admin(email="admin@example.org", confirm=True)
    assert code == 0
    captured = capsys.readouterr()
    assert "already an administrator" in captured.out


def test_requires_mode(test_db, capsys):
    code = grant_admin(email="student@example.org")
    assert code == 1
    captured = capsys.readouterr()
    assert "Must specify one of --inspect, --dry-run, or --confirm" in captured.err
