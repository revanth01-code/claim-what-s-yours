"""Tests for GET /api/v1/auth/me and the public-endpoint regression.

The Firebase verifier is replaced through dependency injection, and the application user
lookup runs against an in-memory SQLite database that only contains the users table. No
test calls the real Firebase SDK, connects to PostgreSQL or needs credentials or network
access.
"""

from collections.abc import Callable, Generator, Iterator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event, select
from sqlalchemy.engine import Connection, Engine
from sqlalchemy.exc import IntegrityError, OperationalError
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.exceptions import (
    AccountDisabledError,
    AuthenticationError,
    AuthServiceUnavailableError,
)
from app.db.session import get_db_session
from app.modules.auth.firebase import reset_firebase_app_cache
from app.modules.auth.verifier import VerifiedIdentity, get_id_token_verifier
from app.modules.users.models import User

ME_PATH = "/api/v1/auth/me"
VALID_TOKEN = "header.payload.signature"


class FakeVerifier:
    """Stands in for the Firebase verifier: returns an identity or raises a configured error."""

    def __init__(
        self,
        identity: VerifiedIdentity | None = None,
        error: Exception | None = None,
    ) -> None:
        self._identity = identity
        self._error = error
        self.tokens: list[str] = []

    def verify(self, id_token: str) -> VerifiedIdentity:
        self.tokens.append(id_token)
        if self._error is not None:
            raise self._error
        assert self._identity is not None
        return self._identity


def make_identity(
    uid: str = "user-1",
    email: str | None = "someone@example.com",
    email_verified: bool = True,
    name: str | None = "Someone",
) -> VerifiedIdentity:
    return VerifiedIdentity(uid=uid, email=email, email_verified=email_verified, name=name)


def make_user_database() -> tuple[sessionmaker[Session], Engine]:
    """Return a session factory over a fresh in-memory SQLite database holding only users."""
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

    User.__table__.create(engine)
    return sessionmaker(bind=engine, autoflush=False, expire_on_commit=False), engine


@pytest.fixture(autouse=True)
def _reset_firebase_cache() -> Iterator[None]:
    """Clear the cached Firebase app before and after each test."""
    reset_firebase_app_cache()
    yield
    reset_firebase_app_cache()


@pytest.fixture
def use_verifier(client: TestClient) -> Iterator[Callable[[FakeVerifier], FakeVerifier]]:
    """Inject a FakeVerifier through dependency_overrides; clear the override on teardown."""

    def install(verifier: FakeVerifier) -> FakeVerifier:
        client.app.dependency_overrides[get_id_token_verifier] = lambda: verifier
        return verifier

    yield install
    client.app.dependency_overrides.pop(get_id_token_verifier, None)


@pytest.fixture
def user_store(client: TestClient) -> Iterator[sessionmaker[Session]]:
    """Back get_db_session with an in-memory users table; yield its session factory."""
    factory, engine = make_user_database()

    def override_db_session() -> Generator[Session, None, None]:
        session = factory()
        try:
            yield session
        finally:
            session.close()

    client.app.dependency_overrides[get_db_session] = override_db_session
    yield factory
    client.app.dependency_overrides.pop(get_db_session, None)
    engine.dispose()


def test_missing_authorization_header_returns_401(client: TestClient) -> None:
    response = client.get(ME_PATH)

    assert response.status_code == 401
    body = response.json()
    assert body["error"]["code"] == "authentication_failed"
    assert "message" in body["error"]
    assert response.headers["WWW-Authenticate"] == "Bearer"


@pytest.mark.parametrize(
    "authorization",
    ["Basic abc", "Bearer", "Bearer  ", "Bearer a b", "Token abc"],
)
def test_malformed_authorization_header_returns_401_without_verifying(
    client: TestClient,
    use_verifier: Callable[[FakeVerifier], FakeVerifier],
    authorization: str,
) -> None:
    verifier = use_verifier(FakeVerifier(identity=make_identity()))

    response = client.get(ME_PATH, headers={"Authorization": authorization})

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "authentication_failed"
    assert response.headers["WWW-Authenticate"] == "Bearer"
    assert verifier.tokens == []


@pytest.mark.parametrize(
    "message",
    [
        "Authentication token has expired",
        "Authentication token has been revoked",
        "Invalid authentication token",
    ],
)
def test_verifier_authentication_error_returns_401_with_message(
    client: TestClient,
    use_verifier: Callable[[FakeVerifier], FakeVerifier],
    message: str,
) -> None:
    use_verifier(FakeVerifier(error=AuthenticationError(message)))

    response = client.get(ME_PATH, headers={"Authorization": f"Bearer {VALID_TOKEN}"})

    assert response.status_code == 401
    body = response.json()
    assert body["error"]["code"] == "authentication_failed"
    assert body["error"]["message"] == message
    assert response.headers["WWW-Authenticate"] == "Bearer"


def test_verifier_account_disabled_returns_403(
    client: TestClient,
    use_verifier: Callable[[FakeVerifier], FakeVerifier],
) -> None:
    use_verifier(FakeVerifier(error=AccountDisabledError()))

    response = client.get(ME_PATH, headers={"Authorization": f"Bearer {VALID_TOKEN}"})

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "account_disabled"


def test_inactive_user_returns_403_account_disabled(
    client: TestClient,
    use_verifier: Callable[[FakeVerifier], FakeVerifier],
    user_store: sessionmaker[Session],
) -> None:
    use_verifier(
        FakeVerifier(identity=make_identity(uid="disabled-uid", email="disabled@example.com"))
    )
    with user_store() as session:
        session.add(User(firebase_uid="disabled-uid", email="disabled@example.com", is_active=False))
        session.commit()

    response = client.get(ME_PATH, headers={"Authorization": f"Bearer {VALID_TOKEN}"})

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "account_disabled"
    assert "disabled@example.com" not in response.text
    assert VALID_TOKEN not in response.text


def test_verifier_service_unavailable_returns_503_not_401(
    client: TestClient,
    use_verifier: Callable[[FakeVerifier], FakeVerifier],
) -> None:
    use_verifier(FakeVerifier(error=AuthServiceUnavailableError()))

    response = client.get(ME_PATH, headers={"Authorization": f"Bearer {VALID_TOKEN}"})

    assert response.status_code == 503
    assert response.status_code != 401
    assert response.json()["error"]["code"] == "auth_service_unavailable"


def test_valid_token_provisions_user_and_returns_it_without_echoing_token(
    client: TestClient,
    use_verifier: Callable[[FakeVerifier], FakeVerifier],
    user_store: sessionmaker[Session],
) -> None:
    use_verifier(
        FakeVerifier(
            identity=make_identity(
                uid="firebase-uid-1",
                email="asha@example.com",
                email_verified=True,
                name="Asha",
            )
        )
    )

    response = client.get(ME_PATH, headers={"Authorization": f"Bearer {VALID_TOKEN}"})

    assert response.status_code == 200
    with user_store() as session:
        stored = session.scalar(select(User).where(User.firebase_uid == "firebase-uid-1"))
        assert stored is not None
        stored_id = str(stored.id)
    assert response.json() == {
        "id": stored_id,
        "email": "asha@example.com",
        "email_verified": True,
        "display_name": "Asha",
        "role": "student",
        "is_active": True,
    }
    assert VALID_TOKEN not in response.text


def test_response_uid_comes_only_from_verified_identity(
    client: TestClient,
    use_verifier: Callable[[FakeVerifier], FakeVerifier],
    user_store: sessionmaker[Session],
) -> None:
    use_verifier(FakeVerifier(identity=make_identity(uid="verified-uid")))

    response = client.request(
        "GET",
        f"{ME_PATH}?uid=attacker",
        headers={"Authorization": f"Bearer {VALID_TOKEN}"},
        json={"uid": "attacker", "sub": "attacker"},
    )

    assert response.status_code == 200
    assert "attacker" not in response.text
    with user_store() as session:
        stored_uids = set(session.scalars(select(User.firebase_uid)).all())
    assert stored_uids == {"verified-uid"}


def test_email_verified_false_is_not_inferred_from_email_domain(
    client: TestClient,
    use_verifier: Callable[[FakeVerifier], FakeVerifier],
    user_store: sessionmaker[Session],
) -> None:
    use_verifier(
        FakeVerifier(
            identity=make_identity(email="someone@gmail.com", email_verified=False),
        )
    )

    response = client.get(ME_PATH, headers={"Authorization": f"Bearer {VALID_TOKEN}"})

    assert response.status_code == 200
    assert response.json()["email"] == "someone@gmail.com"
    assert response.json()["email_verified"] is False


def test_health_endpoint_is_public(client: TestClient) -> None:
    response = client.get("/api/v1/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_scholarship_catalog_is_not_auth_gated(client: TestClient) -> None:
    # No database is configured in tests, so the catalog answers 503 for database
    # reasons only; an auth gate would have answered 401 before reaching it.
    response = client.get("/api/v1/scholarships")

    assert response.status_code != 401
    assert response.status_code != 403
    assert response.status_code == 503
    assert response.json()["error"]["code"] == "database_not_configured"


def test_surplus_spaces_before_bearer_token_are_accepted(
    client: TestClient,
    use_verifier: Callable[[FakeVerifier], FakeVerifier],
    user_store: sessionmaker[Session],
) -> None:
    # RFC 6750 allows one or more spaces after the scheme, so "Bearer  tok" is valid.
    verifier = use_verifier(FakeVerifier(identity=make_identity(uid="spaced-uid")))

    response = client.get(ME_PATH, headers={"Authorization": "Bearer  tok"})

    assert response.status_code == 200
    assert verifier.tokens == ["tok"]


def test_openapi_declares_bearer_security_on_me_endpoint(client: TestClient) -> None:
    response = client.get("/api/v1/openapi.json")

    assert response.status_code == 200
    document = response.json()
    schemes = document["components"]["securitySchemes"]
    assert any(
        scheme.get("type") == "http" and scheme.get("scheme") == "bearer"
        for scheme in schemes.values()
    )
    assert "security" in document["paths"][ME_PATH]["get"]


@pytest.fixture
def fail_db_with(
    client: TestClient,
    monkeypatch: pytest.MonkeyPatch,
) -> Iterator[Callable[[Exception], None]]:
    """Back get_db_session with a session whose scalar and commit raise the given error."""
    factory, engine = make_user_database()

    def install(error: Exception) -> None:
        def raise_error(*args: object, **kwargs: object) -> None:
            raise error

        def override_db_session() -> Generator[Session, None, None]:
            session = factory()
            monkeypatch.setattr(session, "scalar", raise_error)
            monkeypatch.setattr(session, "commit", raise_error)
            try:
                yield session
            finally:
                session.close()

        client.app.dependency_overrides[get_db_session] = override_db_session

    yield install
    client.app.dependency_overrides.pop(get_db_session, None)
    engine.dispose()


def test_database_outage_returns_503_database_unavailable(
    client: TestClient,
    use_verifier: Callable[[FakeVerifier], FakeVerifier],
    fail_db_with: Callable[[Exception], None],
) -> None:
    use_verifier(FakeVerifier(identity=make_identity(uid="u-db")))
    fail_db_with(OperationalError("SELECT 1", {}, Exception("connection refused")))
    outage_client = TestClient(client.app, raise_server_exceptions=False)

    response = outage_client.get(ME_PATH, headers={"Authorization": f"Bearer {VALID_TOKEN}"})

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "database_unavailable"
    assert "connection refused" not in response.text


def test_non_outage_database_error_is_not_reported_as_503(
    client: TestClient,
    use_verifier: Callable[[FakeVerifier], FakeVerifier],
    fail_db_with: Callable[[Exception], None],
) -> None:
    use_verifier(FakeVerifier(identity=make_identity(uid="u-db")))
    fail_db_with(IntegrityError("INSERT", {}, Exception("duplicate")))
    error_client = TestClient(client.app, raise_server_exceptions=False)

    response = error_client.get(ME_PATH, headers={"Authorization": f"Bearer {VALID_TOKEN}"})

    assert response.status_code == 500
    assert response.status_code != 503
    assert response.json()["error"]["code"] == "internal_error"


def test_disabled_account_is_not_mutated_or_committed(
    client: TestClient,
    use_verifier: Callable[[FakeVerifier], FakeVerifier],
    user_store: sessionmaker[Session],
) -> None:
    use_verifier(
        FakeVerifier(
            identity=VerifiedIdentity(
                uid="dis-uid",
                email="new@x.com",
                email_verified=True,
                name="New",
            )
        )
    )
    with user_store() as session:
        session.add(
            User(
                firebase_uid="dis-uid",
                email="old@x.com",
                email_verified=False,
                display_name="Old",
                is_active=False,
            )
        )
        session.commit()

    response = client.get(ME_PATH, headers={"Authorization": f"Bearer {VALID_TOKEN}"})

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "account_disabled"
    with user_store() as session:
        stored = session.scalar(select(User).where(User.firebase_uid == "dis-uid"))
        assert stored is not None
        assert stored.email == "old@x.com"
        assert stored.email_verified is False
        assert stored.display_name == "Old"
