"""Migration and configuration integration tests."""

import os
from pathlib import Path

from alembic import command
from alembic.config import Config
from alembic.script import ScriptDirectory
from sqlalchemy import create_engine, inspect
from app.core.config import Settings
from app.core.config import get_settings


BACKEND_ROOT = Path(__file__).resolve().parents[1]


def test_migration_revision_exists_and_is_unique() -> None:
    config = Config(str(BACKEND_ROOT / "alembic.ini"))
    scripts = ScriptDirectory.from_config(config)
    revisions = list(scripts.walk_revisions())

    assert revisions
    assert len(revisions) == 1
    assert revisions[0].revision == "6123f9c0e152"


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

    assert len(revision_files) == 1
    source = revision_files[0].read_text(encoding="utf-8")
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
