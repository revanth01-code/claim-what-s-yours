"""Startup tests: app factory, module-level app, and route registration."""

from fastapi import FastAPI
from fastapi import Depends
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from typing import Annotated

from app.core.config import get_settings
from app.main import create_app


def test_create_app_returns_fastapi_instance() -> None:
    application = create_app()
    assert isinstance(application, FastAPI)
    assert application.title == get_settings().app_name


def test_module_level_app_importable() -> None:
    import app.main

    assert hasattr(app.main, "app")
    assert isinstance(app.main.app, FastAPI)


def test_health_route_registered() -> None:
    application = create_app()
    schema = application.openapi()
    assert "/api/v1/health" in schema["paths"]
    assert "/api/v1/health/database" in schema["paths"]


def test_creating_app_does_not_require_database(monkeypatch) -> None:
    monkeypatch.delenv("CWY_DATABASE_URL", raising=False)
    get_settings.cache_clear()
    application = create_app()
    assert isinstance(application, FastAPI)
    assert get_settings().database_url is None


def test_api_prefix_changes_after_app_main_import(monkeypatch) -> None:
    import app.main

    monkeypatch.setenv("CWY_API_PREFIX", "/custom/v2")
    get_settings.cache_clear()

    application = create_app()
    schema = application.openapi()

    assert "/custom/v2/health" in schema["paths"]
    assert application.docs_url == "/custom/v2/docs"
    assert application.openapi_url == "/custom/v2/openapi.json"


def test_api_routes_and_docs_use_same_prefix(monkeypatch) -> None:
    monkeypatch.setenv("CWY_API_PREFIX", "/custom/v3")
    get_settings.cache_clear()

    application = create_app()
    client = TestClient(application)
    response = client.get("/custom/v3/health")
    docs_response = client.get("/custom/v3/docs")
    openapi_response = client.get("/custom/v3/openapi.json")
    schema = application.openapi()

    assert response.status_code == 200
    assert docs_response.status_code == 200
    assert openapi_response.status_code == 200
    assert "/custom/v3/health" in schema["paths"]
    assert application.openapi_url == "/custom/v3/openapi.json"
    assert application.docs_url == "/custom/v3/docs"
    assert application.openapi_url == "/custom/v3/openapi.json"


def test_unconfigured_database_dependency_returns_503(monkeypatch) -> None:
    from app.core.exceptions import register_exception_handlers
    from app.db.session import get_db_session

    monkeypatch.delenv("CWY_DATABASE_URL", raising=False)
    get_settings.cache_clear()

    application = FastAPI()
    register_exception_handlers(application)

    @application.get("/test/database")
    def database_test(
        session: Annotated[Session, Depends(get_db_session)],
    ) -> dict[str, str]:
        del session
        return {"status": "ok"}

    response = TestClient(application).get("/test/database")

    assert response.status_code == 503
    assert response.json() == {
        "error": {
            "code": "database_not_configured",
            "message": "Database is not configured.",
        }
    }
