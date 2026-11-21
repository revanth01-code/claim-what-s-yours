"""Settings tests. Settings(_env_file=None) ignores any local backend/.env file."""

import pytest
from pydantic import ValidationError

from app.core.config import Settings

_ALL_CWY_ENV_VARS = (
    "CWY_APP_NAME",
    "CWY_ENVIRONMENT",
    "CWY_API_PREFIX",
    "CWY_DATABASE_URL",
    "CWY_DATABASE_CONNECT_TIMEOUT_SECONDS",
    "CWY_CORS_ALLOWED_ORIGINS",
)


def test_default_settings(monkeypatch: pytest.MonkeyPatch) -> None:
    for name in _ALL_CWY_ENV_VARS:
        monkeypatch.delenv(name, raising=False)
    settings = Settings(_env_file=None)
    assert settings.environment == "development"
    assert settings.api_prefix == "/api/v1"
    assert settings.database_url is None
    assert settings.database_connect_timeout_seconds == 3
    assert settings.cors_origins_list == []


def test_cors_comma_separated_parsed(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("CWY_CORS_ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:8080")
    settings = Settings(_env_file=None)
    assert settings.cors_origins_list == ["http://localhost:3000", "http://localhost:8080"]


def test_cors_json_list_parsed(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("CWY_CORS_ALLOWED_ORIGINS", '["http://localhost:3000"]')
    settings = Settings(_env_file=None)
    assert settings.cors_origins_list == ["http://localhost:3000"]


@pytest.mark.parametrize("prefix", ["api/v1", "/api/v1/"])
def test_invalid_api_prefix_rejected(monkeypatch: pytest.MonkeyPatch, prefix: str) -> None:
    monkeypatch.setenv("CWY_API_PREFIX", prefix)
    with pytest.raises(ValidationError):
        Settings(_env_file=None)


def test_invalid_environment_rejected(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("CWY_ENVIRONMENT", "invalid")
    with pytest.raises(ValidationError):
        Settings(_env_file=None)


def test_database_url_is_accessible(monkeypatch: pytest.MonkeyPatch) -> None:
    url = "postgresql+psycopg://u:topsecret@h/db"
    monkeypatch.setenv("CWY_DATABASE_URL", url)
    settings = Settings(_env_file=None)
    assert settings.database_url is not None
    assert settings.database_url.get_secret_value() == url


def test_database_url_password_never_appears_in_repr(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv(
        "CWY_DATABASE_URL",
        "postgresql+psycopg://u:topsecret@h/db",
    )
    settings = Settings(_env_file=None)

    assert "topsecret" not in repr(settings)
    assert "topsecret" not in str(settings)
