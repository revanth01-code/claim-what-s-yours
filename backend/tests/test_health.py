"""Health endpoint tests. None of these require a running PostgreSQL server."""

from fastapi.testclient import TestClient
from sqlalchemy import text

from app.core.config import get_settings
from app.main import create_app

UNREACHABLE_DATABASE_URL = "postgresql+psycopg://user:secret@127.0.0.1:1/nonexistent"


def test_health_returns_200_with_expected_structure(client: TestClient) -> None:
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    body = response.json()
    for key in ("status", "application", "environment", "version"):
        assert key in body
    assert body["status"] == "ok"
    assert body["environment"] == "testing"
    assert body["version"] == "0.1.0"


def test_health_works_without_database_configured(client: TestClient) -> None:
    assert get_settings().database_url is None
    response = client.get("/api/v1/health")
    assert response.status_code == 200


def test_database_health_not_configured_returns_503(client: TestClient) -> None:
    response = client.get("/api/v1/health/database")
    assert response.status_code == 503
    body = response.json()
    assert body["database"] == "not_configured"
    assert body["status"] == "unavailable"


def test_database_health_success_with_mocked_session(
    client: TestClient, monkeypatch
) -> None:
    from app.db import health
    from app.core.config import get_settings

    class MockSession:
        def execute(self, statement) -> None:
            assert str(statement) == str(text("SELECT 1"))

        def close(self) -> None:
            return None

    class MockSessionFactory:
        def __call__(self) -> MockSession:
            return MockSession()

    monkeypatch.setenv(
        "CWY_DATABASE_URL",
        "postgresql+psycopg://user:secret@database.example/test",
    )
    get_settings.cache_clear()
    monkeypatch.setattr(
        health,
        "get_session_factory",
        lambda: MockSessionFactory(),
    )

    response = client.get("/api/v1/health/database")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "database": "reachable"}


def test_database_health_unreachable_returns_503_without_leaking(
    client: TestClient, monkeypatch
) -> None:
    from app.db.session import get_engine, get_session_factory

    monkeypatch.setenv("CWY_DATABASE_URL", UNREACHABLE_DATABASE_URL)
    monkeypatch.setenv("CWY_DATABASE_CONNECT_TIMEOUT_SECONDS", "1")
    get_settings.cache_clear()
    get_engine.cache_clear()
    get_session_factory.cache_clear()
    try:
        fresh_client = TestClient(create_app())
        response = fresh_client.get("/api/v1/health/database")
        assert response.status_code == 503
        body = response.json()
        assert body["database"] == "unreachable"
        assert body["status"] == "unavailable"
        assert "secret" not in response.text
        assert "127.0.0.1" not in response.text
    finally:
        get_engine.cache_clear()
        get_session_factory.cache_clear()


def test_app_stays_up_when_database_unreachable(client: TestClient, monkeypatch) -> None:
    from app.db.session import get_engine, get_session_factory

    monkeypatch.setenv("CWY_DATABASE_URL", UNREACHABLE_DATABASE_URL)
    monkeypatch.setenv("CWY_DATABASE_CONNECT_TIMEOUT_SECONDS", "1")
    get_settings.cache_clear()
    get_engine.cache_clear()
    get_session_factory.cache_clear()
    try:
        fresh_client = TestClient(create_app())
        db_response = fresh_client.get("/api/v1/health/database")
        assert db_response.status_code == 503
        response = fresh_client.get("/api/v1/health")
        assert response.status_code == 200
        assert response.json()["status"] == "ok"
    finally:
        get_engine.cache_clear()
        get_session_factory.cache_clear()


def test_unknown_route_returns_consistent_error(client: TestClient) -> None:
    response = client.get("/api/v1/does-not-exist")
    assert response.status_code == 404
    body = response.json()
    assert isinstance(body["error"], dict)
    assert "code" in body["error"]
    assert "message" in body["error"]
