"""Migration and configuration integration tests."""

import os
import uuid
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config
from alembic.runtime.migration import MigrationContext
from alembic.script import ScriptDirectory
from sqlalchemy import create_engine, inspect
from app.core.config import Settings
from app.core.config import get_settings


BACKEND_ROOT = Path(__file__).resolve().parents[1]

# Read at import time: the autouse _clean_settings fixture removes CWY_DATABASE_URL
# from the environment before each test runs.
POSTGRES_TEST_URL = os.environ.get("CWY_DATABASE_URL")

INITIAL_REVISION = "6123f9c0e152"
USERS_REVISION = "3f8b2d4e91c0"


def test_migration_revision_exists_and_is_unique() -> None:
    config = Config(str(BACKEND_ROOT / "alembic.ini"))
    scripts = ScriptDirectory.from_config(config)
    revisions = list(scripts.walk_revisions())

    assert revisions
    assert len(revisions) == 2
    assert {revision.revision for revision in revisions} == {INITIAL_REVISION, USERS_REVISION}


def test_migration_configuration_uses_application_settings(
    monkeypatch,
) -> None:
    url = "postgresql+psycopg://test-user:test-password@localhost/test-db"
    monkeypatch.setenv("CWY_DATABASE_URL", url)

    settings = Settings(_env_file=None)
    assert settings.database_url is not None
    assert settings.database_url.get_secret_value() == url
    assert "test-password" not in repr(settings)


def test_migration_script_contains_upgrade_and_downgrade() -> None:
    versions = BACKEND_ROOT / "alembic" / "versions"
    revision_files = list(versions.glob("*.py"))

    assert len(revision_files) == 2
    for revision_file in revision_files:
        source = revision_file.read_text(encoding="utf-8")
        assert "def upgrade()" in source
        assert "def downgrade()" in source


def test_migration_upgrade_downgrade_and_reupgrade(
    tmp_path: Path,
    monkeypatch,
) -> None:
    database_path = tmp_path / "migration-cycle.sqlite"
    database_url = f"sqlite:///{database_path}"
    monkeypatch.setenv("CWY_DATABASE_URL", database_url)
    monkeypatch.setenv("CWY_ENVIRONMENT", "testing")
    get_settings.cache_clear()

    config = Config(str(BACKEND_ROOT / "alembic.ini"))

    command.upgrade(config, "head")
    engine = create_engine(database_url)
    upgraded_tables = set(inspect(engine).get_table_names())
    assert "scholarships" in upgraded_tables
    assert "eligibility_criteria" in upgraded_tables
    assert "scholarship_sources" in upgraded_tables
    engine.dispose()

    command.downgrade(config, "base")
    engine = create_engine(database_url)
    downgraded_tables = set(inspect(engine).get_table_names())
    assert "scholarships" not in downgraded_tables
    assert "eligibility_criteria" not in downgraded_tables
    engine.dispose()

    command.upgrade(config, "head")
    engine = create_engine(database_url)
    reupgraded_tables = set(inspect(engine).get_table_names())
    assert "scholarships" in reupgraded_tables
    assert "official_sources" in reupgraded_tables
    engine.dispose()

    get_settings.cache_clear()


def test_postgres_upgrade_head_then_downgrade_to_initial_revision(
    monkeypatch,
) -> None:
    if not POSTGRES_TEST_URL:
        pytest.skip("CWY_DATABASE_URL is not set; PostgreSQL migration test skipped")
    if not POSTGRES_TEST_URL.startswith("postgresql"):
        pytest.skip("CWY_DATABASE_URL is not a PostgreSQL URL; PostgreSQL migration test skipped")
    try:
        probe = create_engine(POSTGRES_TEST_URL, pool_pre_ping=True)
        with probe.connect():
            pass
        probe.dispose()
    except Exception:
        pytest.skip("PostgreSQL at CWY_DATABASE_URL is not reachable; migration test skipped")

    monkeypatch.setenv("CWY_DATABASE_URL", POSTGRES_TEST_URL)
    monkeypatch.setenv("CWY_ENVIRONMENT", "testing")
    get_settings.cache_clear()

    # Every migration runs inside a throwaway schema that this test creates and drops.
    # The public schema and the application's real tables are never touched: the
    # connection's search_path points at the throwaway schema, and env.py uses the
    # connection supplied through config.attributes instead of building its own engine.
    schema = "cwy_migration_test_" + uuid.uuid4().hex[:12]
    quoted_schema = f'"{schema}"'

    config = Config(str(BACKEND_ROOT / "alembic.ini"))

    admin_engine = create_engine(POSTGRES_TEST_URL, pool_pre_ping=True)
    try:
        with admin_engine.connect() as admin:
            admin.exec_driver_sql(f"CREATE SCHEMA {quoted_schema}")
            admin.commit()

        migration_engine = create_engine(POSTGRES_TEST_URL, pool_pre_ping=True)
        try:
            with migration_engine.connect() as connection:
                connection.exec_driver_sql(f"SET search_path TO {quoted_schema}")
                connection.commit()

                config.attributes["connection"] = connection
                try:
                    command.upgrade(config, "head")
                    connection.commit()
                    upgraded_tables = set(inspect(connection).get_table_names(schema=schema))
                    assert "users" in upgraded_tables
                    assert "scholarships" in upgraded_tables

                    command.downgrade(config, INITIAL_REVISION)
                    connection.commit()
                    downgraded_tables = set(inspect(connection).get_table_names(schema=schema))
                    assert "users" not in downgraded_tables
                    assert "scholarships" in downgraded_tables

                    command.upgrade(config, "head")
                    connection.commit()
                    reupgraded_tables = set(inspect(connection).get_table_names(schema=schema))
                    assert "users" in reupgraded_tables

                    current = MigrationContext.configure(connection).get_current_revision()
                    connection.commit()
                    assert current == USERS_REVISION
                finally:
                    config.attributes.pop("connection", None)
                    connection.rollback()
        finally:
            migration_engine.dispose()
    finally:
        try:
            with admin_engine.connect() as admin:
                admin.exec_driver_sql(f"DROP SCHEMA IF EXISTS {quoted_schema} CASCADE")
                admin.commit()
        finally:
            admin_engine.dispose()

    get_settings.cache_clear()

