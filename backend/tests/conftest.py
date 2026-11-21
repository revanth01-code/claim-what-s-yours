"""Shared pytest fixtures.

Settings are cached, so every test starts from a clean environment and a
cleared settings cache. No test connects to a PostgreSQL server.
"""

from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient

_DATABASE_ENV_VARS = (
    "CWY_DATABASE_URL",
    "CWY_DATABASE_CONNECT_TIMEOUT_SECONDS",
    "CWY_CORS_ALLOWED_ORIGINS",
)


@pytest.fixture(autouse=True)
def _clean_settings(monkeypatch: pytest.MonkeyPatch) -> Iterator[None]:
    """Reset settings cache and environment before and after each test."""
    from app.core.config import get_settings

    get_settings.cache_clear()
    for name in _DATABASE_ENV_VARS:
        monkeypatch.delenv(name, raising=False)
    monkeypatch.setenv("CWY_ENVIRONMENT", "testing")
    yield
    get_settings.cache_clear()


@pytest.fixture
def client(_clean_settings: None) -> Iterator[TestClient]:
    """Yield a TestClient built after the clean-settings fixture has run."""
    from app.main import create_app

    yield TestClient(create_app())
