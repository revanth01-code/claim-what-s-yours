"""Alembic environment configuration."""

from logging.config import fileConfig

from alembic import context

from app.core.config import get_settings
from app.core.exceptions import DatabaseNotConfiguredError
from app.db.base import Base
from app.modules.eligibility import EligibilityCriteria
from app.modules.scholarships import (
    AcademicYear,
    OfficialSource,
    Scholarship,
    ScholarshipAcademicYear,
    ScholarshipSource,
)

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def get_database_url() -> str:
    """Return the configured database URL without exposing it in logs."""
    settings = get_settings()
    if settings.database_url is None:
        raise DatabaseNotConfiguredError()
    return settings.database_url.get_secret_value()


def run_migrations_offline() -> None:
    """Run migrations without creating an Engine."""
    context.configure(
        url=get_database_url(),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
        compare_server_default=True,
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations with a live SQLAlchemy connection."""
    from sqlalchemy import create_engine

    database_url = get_database_url()
    engine_options: dict[str, object] = {"pool_pre_ping": True}
    if database_url.startswith("postgresql"):
        engine_options["connect_args"] = {
            "connect_timeout": get_settings().database_connect_timeout_seconds
        }
    connectable = create_engine(database_url, **engine_options)

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
            compare_server_default=True,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
