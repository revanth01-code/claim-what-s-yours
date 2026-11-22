"""Tests for just-in-time user provisioning against an in-memory SQLite database.

Only the users table is created. The engine applies the documented pysqlite workaround so
that SAVEPOINT (session.begin_nested) behaves as it does on PostgreSQL. No test needs a
PostgreSQL server, Firebase credentials or network access.
"""

from collections.abc import Iterator

import pytest
from sqlalchemy import create_engine, event, func, select
from sqlalchemy.engine import Connection, Engine
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.modules.auth.verifier import VerifiedIdentity
from app.modules.users import service as service_module
from app.modules.users.models import User
from app.modules.users.service import get_or_create_user_by_identity


def make_identity(
    uid: str = "uid-1",
    email: str | None = "a@example.com",
    email_verified: bool = False,
    name: str | None = "A",
) -> VerifiedIdentity:
    return VerifiedIdentity(uid=uid, email=email, email_verified=email_verified, name=name)


def count_users(session: Session, firebase_uid: str) -> int:
    count = session.scalar(
        select(func.count()).select_from(User).where(User.firebase_uid == firebase_uid)
    )
    return int(count or 0)


@pytest.fixture
def engine() -> Iterator[Engine]:
    sqlite_engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    @event.listens_for(sqlite_engine, "connect")
    def _disable_pysqlite_implicit_transactions(dbapi_connection: object, _record: object) -> None:
        dbapi_connection.isolation_level = None  # type: ignore[attr-defined]

    @event.listens_for(sqlite_engine, "begin")
    def _emit_explicit_begin(connection: Connection) -> None:
        connection.exec_driver_sql("BEGIN")

    User.__table__.create(sqlite_engine)
    yield sqlite_engine
    sqlite_engine.dispose()


@pytest.fixture
def session(engine: Engine) -> Iterator[Session]:
    factory = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)
    db_session = factory()
    yield db_session
    db_session.close()


def test_first_call_creates_active_student_user(session: Session) -> None:
    user = get_or_create_user_by_identity(session, make_identity())
    session.commit()

    assert user.id is not None
    assert user.firebase_uid == "uid-1"
    assert user.role == "student"
    assert user.is_active is True
    assert user.email == "a@example.com"
    assert user.email_verified is False
    assert user.display_name == "A"


def test_second_call_with_same_uid_returns_same_row_without_duplicate(
    session: Session,
) -> None:
    first = get_or_create_user_by_identity(session, make_identity())
    session.commit()

    second = get_or_create_user_by_identity(session, make_identity())
    session.commit()

    assert second.id == first.id
    assert count_users(session, "uid-1") == 1


def test_changed_verified_claims_are_updated_on_next_call(session: Session) -> None:
    first = get_or_create_user_by_identity(
        session,
        make_identity(email="a@example.com", email_verified=False, name="A"),
    )
    session.commit()

    updated = get_or_create_user_by_identity(
        session,
        make_identity(email="new@example.com", email_verified=True, name="B"),
    )
    session.commit()

    assert updated.id == first.id
    assert updated.email == "new@example.com"
    assert updated.email_verified is True
    assert updated.display_name == "B"
    assert count_users(session, "uid-1") == 1


def test_existing_inactive_user_is_returned_unchanged_by_service(session: Session) -> None:
    session.add(User(firebase_uid="uid-1", email="a@example.com", is_active=False))
    session.commit()

    user = get_or_create_user_by_identity(session, make_identity())
    session.commit()

    assert user.is_active is False
    assert count_users(session, "uid-1") == 1


def test_lost_insert_race_returns_row_committed_by_other_request(
    session: Session,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    # Another request committed the same uid after our first SELECT missed it.
    existing = User(firebase_uid="uid-1", email="a@example.com", email_verified=False)
    session.add(existing)
    session.commit()
    existing_id = existing.id

    real_select = service_module._select_by_firebase_uid
    calls: list[str] = []

    def select_that_misses_before_insert(db_session: Session, firebase_uid: str) -> User | None:
        calls.append(firebase_uid)
        if len(calls) == 1:
            return None
        return real_select(db_session, firebase_uid)

    monkeypatch.setattr(service_module, "_select_by_firebase_uid", select_that_misses_before_insert)

    user = get_or_create_user_by_identity(session, make_identity())
    session.commit()

    assert user.id == existing_id
    assert len(calls) == 2
    assert count_users(session, "uid-1") == 1


def test_firebase_uid_is_unique_at_database_level(session: Session) -> None:
    session.add(User(firebase_uid="dup"))
    session.commit()

    session.add(User(firebase_uid="dup"))
    with pytest.raises(IntegrityError):
        session.commit()
    session.rollback()

    assert count_users(session, "dup") == 1


def seed_committed_user(engine: Engine, **fields: object) -> None:
    """Commit a user row from its own session, as a concurrent request would."""
    seed_session = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)()
    try:
        seed_session.add(User(**fields))
        seed_session.commit()
    finally:
        seed_session.close()


def test_race_winner_claims_are_synchronised_when_active(
    engine: Engine,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    seed_committed_user(
        engine,
        firebase_uid="race-uid",
        email="old@x.com",
        email_verified=False,
        display_name="Old",
        is_active=True,
    )

    race_session = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)()
    try:
        real_select = service_module._select_by_firebase_uid
        calls: list[str] = []

        def select_that_misses_before_insert(db_session: Session, firebase_uid: str) -> User | None:
            calls.append(firebase_uid)
            if len(calls) == 1:
                return None
            return real_select(db_session, firebase_uid)

        monkeypatch.setattr(
            service_module, "_select_by_firebase_uid", select_that_misses_before_insert
        )

        user = get_or_create_user_by_identity(
            race_session,
            VerifiedIdentity(uid="race-uid", email="new@x.com", email_verified=True, name="New"),
        )
        race_session.commit()

        assert len(calls) == 2
        assert user.email == "new@x.com"
        assert user.email_verified is True
        assert user.display_name == "New"
        assert count_users(race_session, "race-uid") == 1
    finally:
        race_session.close()

    check_session = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)()
    try:
        stored = check_session.scalar(select(User).where(User.firebase_uid == "race-uid"))
        assert stored is not None
        assert stored.email == "new@x.com"
        assert stored.email_verified is True
        assert stored.display_name == "New"
        assert count_users(check_session, "race-uid") == 1
    finally:
        check_session.close()


def test_disabled_race_winner_is_not_mutated(
    engine: Engine,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    seed_committed_user(
        engine,
        firebase_uid="race-uid",
        email="old@x.com",
        email_verified=False,
        display_name="Old",
        is_active=False,
    )

    race_session = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)()
    try:
        real_select = service_module._select_by_firebase_uid
        calls: list[str] = []

        def select_that_misses_before_insert(db_session: Session, firebase_uid: str) -> User | None:
            calls.append(firebase_uid)
            if len(calls) == 1:
                return None
            return real_select(db_session, firebase_uid)

        monkeypatch.setattr(
            service_module, "_select_by_firebase_uid", select_that_misses_before_insert
        )

        user = get_or_create_user_by_identity(
            race_session,
            VerifiedIdentity(uid="race-uid", email="new@x.com", email_verified=True, name="New"),
        )
        race_session.commit()

        assert len(calls) == 2
        assert user.email == "old@x.com"
        assert user.email_verified is False
        assert user.display_name == "Old"
        assert user.is_active is False
    finally:
        race_session.close()

    check_session = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)()
    try:
        stored = check_session.scalar(select(User).where(User.firebase_uid == "race-uid"))
        assert stored is not None
        assert stored.email == "old@x.com"
        assert stored.email_verified is False
        assert stored.display_name == "Old"
        assert count_users(check_session, "race-uid") == 1
    finally:
        check_session.close()


def test_check_constraint_rejects_unknown_role(session: Session) -> None:
    session.add(User(firebase_uid="ck-role", role="superadmin"))
    with pytest.raises(IntegrityError):
        session.commit()
    session.rollback()

    assert count_users(session, "ck-role") == 0


def test_check_constraint_rejects_empty_firebase_uid(session: Session) -> None:
    session.add(User(firebase_uid=""))
    with pytest.raises(IntegrityError):
        session.commit()
    session.rollback()

    assert count_users(session, "") == 0


def test_valid_student_role_with_normal_uid_is_inserted(session: Session) -> None:
    session.add(User(firebase_uid="ck-student", role="student"))
    session.commit()

    assert count_users(session, "ck-student") == 1
    stored = session.scalar(select(User).where(User.firebase_uid == "ck-student"))
    assert stored is not None
    assert stored.role == "student"
