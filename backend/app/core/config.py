"""Application settings loaded from environment variables prefixed with CWY_."""

import json
import os
from functools import lru_cache
from typing import Literal

from pydantic import Field, SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime settings. Values come from the environment or a local .env file."""

    model_config = SettingsConfigDict(env_file=".env", env_prefix="CWY_", extra="ignore")

    app_name: str = "Claim What's Yours API"
    environment: Literal["development", "testing", "production"] = "development"
    api_prefix: str = "/api/v1"
    database_url: SecretStr | None = None
    # Stored as a raw string so comma-separated values parse on pydantic-settings>=2.4.
    # Use the cors_origins_list property to get the parsed list.
    cors_allowed_origins: str = ""
    database_connect_timeout_seconds: int = Field(default=3, ge=1)
    # Firebase Authentication settings. The service-account file path is local
    # configuration only; never commit the credentials file itself.
    firebase_project_id: str | None = None
    firebase_credentials_path: str | None = None

    # LLM Provider Configuration (Groq only)
    # Supported providers: "groq", "none"
    llm_provider: Literal["groq", "none"] = "groq"
    llm_api_key: SecretStr | None = None
    llm_model: str = "openai/gpt-oss-120b"
    llm_timeout_seconds: int = Field(default=30, ge=1, le=120)
    llm_max_output_tokens: int = Field(default=1024, ge=50, le=4096)

    # Ingestion & Ingestion Scheduler Settings
    ingestion_secret: SecretStr | None = None
    ingestion_interval_hours: int = Field(default=12, ge=1, le=168)

    @field_validator("llm_model", mode="before")
    @classmethod
    def _validate_llm_model(cls, value: str | None) -> str:
        """Fallback to default model if empty string provided."""
        if not value or not str(value).strip():
            return "openai/gpt-oss-120b"
        return str(value).strip()

    @field_validator("api_prefix")
    @classmethod
    def _validate_api_prefix(cls, value: str) -> str:
        """Require a leading slash and no trailing slash (and not just '/')."""
        if not value.startswith("/") or value == "/" or value.endswith("/"):
            raise ValueError("api_prefix must start with '/' and must not end with '/'.")
        return value

    @property
    def cors_origins_list(self) -> list[str]:
        """Return allowed origins from a JSON list string or a comma-separated string."""
        raw = self.cors_allowed_origins.strip()
        if not raw:
            return []
        if raw.startswith("["):
            parsed = json.loads(raw)
            items = [str(item) for item in parsed]
        else:
            items = raw.split(",")
        return [item.strip() for item in items if item.strip()]


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Return the cached application settings."""
    env_file = None if os.getenv("CWY_ENVIRONMENT") == "testing" else ".env"
    return Settings(_env_file=env_file)
