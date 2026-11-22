"""PostgreSQL integration tests for the verification_audit_logs protections.

These tests exercise migration 6d7e8f9a0b1c against a real PostgreSQL server:
nullable scholarship_id, ON DELETE RESTRICT on the scholarship FK, the
append-only UPDATE/DELETE/TRUNCATE triggers, and the guarded downgrade.

Every test runs in its own throwaway schema. The public schema is never touched:
the connection's search_path points at the throwaway schema, and env.py uses the
connection supplied through config.attributes instead of building its own engine.

Requires CWY_TEST_DATABASE_URL to point at a disposable PostgreSQL database and
CWY_TEST_DATABASE_CONFIRM_DISPOSABLE to hold the exact confirmation value. The test
database must not be the application database (CWY_DATABASE_URL, or database_url in
backend/.env). Missing URL or non-PostgreSQL URL skips; a missing confirmation or a
test database that matches the application database fails. Messages never include
URLs, credentials, hosts or database names.
"""

import json
import os
import uuid
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config
from alembic.runtime.migration import MigrationContext
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import make_url
from sqlalchemy.exc import DBAPIError, IntegrityError

from app.core.config import Settings, get_settings


BACKEND_ROOT = Path(__file__).resolve().parents[1]

# Read at import time: the autouse _clean_settings fixture removes CWY_DATABASE_URL
# from the environment before each test runs.
POSTGRES_TEST_URL = os.environ.get("CWY_TEST_DATABASE_URL")
CONFIRM_ENV = "CWY_TEST_DATABASE_CONFIRM_DISPOSABLE"
CONFIRM_VALUE = "I_CONFIRM_THIS_DATABASE_IS_DISPOSABLE"
TEST_DATABASE_CONFIRMATION = os.environ.get(CONFIRM_ENV)

APP_URL_UNRESOLVED = object()
_LOOPBACK_HOSTS = frozenset({"localhost", "127.0.0.1", "::1", ""})


def _resolve_app_database_url():
    """Return the application URL: env var, else backend .env, None if unset, or the sentinel."""
    env_value = os.environ.get("CWY_DATABASE_URL")
    if env_value:
        return env_value
    try:
        settings = Settings(_env_file=BACKEND_ROOT / ".env")
    except Exception:
        return APP_URL_UNRESOLVED
    if settings.database_url is None:
        return None
    return settings.database_url.get_secret_value()


APP_DATABASE_URL = _resolve_app_database_url()

AUDIT_LOGS_REVISION = "5c8a2b1f4d9e"
PROTECT_AUDIT_LOGS_REVISION = "6d7e8f9a0b1c"

TRIGGER_NAME = "trg_prevent_audit_log_modification"
FK_NAME = "verification_audit_logs_scholarship_id_fkey"
APPEND_ONLY_MESSAGE = "append-only"

ORIGINAL_ACTION = "admin_provision"
ORIGINAL_TARGET_TYPE = "scholarship"
ORIGINAL_NOTES = "initial audit note"
ORIGINAL_DETAILS = {"reason": "audit-test", "count": 2}


def _url_identity(url) -> tuple[str, int, str]:
    """Return (host_key, port, database_key) for comparing two URLs without connecting."""
    host = url.host
    if host is None:
        query_host = url.query.get("host")
        if isinstance(query_host, tuple):
            query_host = query_host[0] if query_host else None
        host = query_host
    host_text = (host or "").lower()
    host_key = "loopback" if host_text in _LOOPBACK_HOSTS else host_text
    return host_key, url.port or 5432, (url.database or "").lower()


def _guard_test_database(test_url: str | None) -> None:
    """Skip, fail, or return if the PostgreSQL test database is safe to use.

    Messages never include the URL, credentials, host or database name.
    """
    if not test_url:
        pytest.skip("CWY_TEST_DATABASE_URL is not set; PostgreSQL audit-protection tests skipped")
    try:
        parsed = make_url(test_url)
    except Exception:
        pytest.fail("CWY_TEST_DATABASE_URL could not be parsed")
    if parsed.get_backend_name() != "postgresql":
        pytest.skip(
            "CWY_TEST_DATABASE_URL is not a PostgreSQL URL; PostgreSQL audit-protection tests skipped"
        )
    if TEST_DATABASE_CONFIRMATION != CONFIRM_VALUE:
        pytest.fail(
            f"{CONFIRM_ENV} must be set to the exact confirmation value before "
            "PostgreSQL audit tests run against a test database"
        )
    if APP_DATABASE_URL is APP_URL_UNRESOLVED:
        pytest.fail(
            "cannot verify the test database is separate from the application database; "
            "refusing to run"
        )
    if APP_DATABASE_URL is not None:
        same_database_message = (
            "the test database must not be the configured application database"
        )
        if test_url == APP_DATABASE_URL:
            pytest.fail(same_database_message)
        try:
            test_identity = _url_identity(parsed)
            app_identity = _url_identity(make_url(APP_DATABASE_URL))
        except Exception:
            pytest.fail(
                "cannot verify the test database is separate from the application database; "
                "refusing to run"
            )
        test_host, test_port, test_db = test_identity
        app_host, app_port, app_db = app_identity
        if test_db == app_db and (test_host, test_port) == (app_host, app_port):
            pytest.fail(same_database_message)
    try:
        probe = create_engine(
            test_url, pool_pre_ping=True, connect_args={"connect_timeout": 5}
        )
        try:
            with probe.connect():
                pass
        finally:
            probe.dispose()
    except Exception:
        pytest.skip(
            "PostgreSQL at CWY_TEST_DATABASE_URL is not reachable; audit-protection tests skipped"
        )


@pytest.fixture
def pg_url(monkeypatch) -> str:
    """Return the disposable PostgreSQL URL, or skip/fail with a safe message."""
    _guard_test_database(POSTGRES_TEST_URL)
    return POSTGRES_TEST_URL


@pytest.fixture
def isolated_schema(pg_url, monkeypatch):
    """Yield (connection, config, schema) bound to a fresh schema that is dropped on exit."""
    monkeypatch.setenv("CWY_DATABASE_URL", pg_url)
    monkeypatch.setenv("CWY_ENVIRONMENT", "testing")
    get_settings.cache_clear()

    schema = "cwy_audit_test_" + uuid.uuid4().hex[:12]
    quoted_schema = f'"{schema}"'
    config = Config(str(BACKEND_ROOT / "alembic.ini"))

    admin_engine = create_engine(
        pg_url, pool_pre_ping=True, connect_args={"connect_timeout": 5}
    )
    try:
        with admin_engine.connect() as admin:
            admin.exec_driver_sql(f"CREATE SCHEMA {quoted_schema}")
            admin.commit()

        migration_engine = create_engine(
            pg_url, pool_pre_ping=True, connect_args={"connect_timeout": 5}
        )
        try:
            with migration_engine.connect() as connection:
                connection.exec_driver_sql(f"SET search_path TO {quoted_schema}")
                connection.commit()

                config.attributes["connection"] = connection
                try:
                    yield connection, config, schema
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


def _scalar(connection, sql: str, **params):
    return connection.execute(text(sql), params).scalar()


def _schema_trigger_count(connection, schema: str) -> int:
    return _scalar(
        connection,
        """
        SELECT count(*)
        FROM pg_trigger t
        JOIN pg_class c ON c.oid = t.tgrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = :schema
          AND t.tgname IN ('trg_prevent_audit_log_modification', 'trg_prevent_audit_log_truncate')
          AND NOT t.tgisinternal
        """,
        schema=schema,
    )


def _fk_confdeltype(connection, schema: str) -> str:
    return _scalar(
        connection,
        """
        SELECT c.confdeltype
        FROM pg_constraint c
        JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname = :schema
          AND c.conname = 'verification_audit_logs_scholarship_id_fkey'
        """,
        schema=schema,
    )


def _sqlstate(exc: DBAPIError) -> str | None:
    orig = exc.orig
    return getattr(orig, "sqlstate", None) or getattr(getattr(orig, "diag", None), "sqlstate", None)


def _insert_user(connection, user_id: uuid.UUID) -> None:
    connection.execute(
        text("INSERT INTO users (id, firebase_uid) VALUES (:id, :firebase_uid)"),
        {"id": user_id, "firebase_uid": "test-" + uuid.uuid4().hex},
    )


def _insert_scholarship(connection, scholarship_id: uuid.UUID) -> None:
    suffix = uuid.uuid4().hex
    connection.execute(
        text(
            """
            INSERT INTO scholarships (id, name, slug, administering_authority, category)
            VALUES (:id, :name, :slug, :authority, :category)
            """
        ),
        {
            "id": scholarship_id,
            "name": "Audit test scholarship " + suffix,
            "slug": "test-" + suffix,
            "authority": "Audit test authority",
            "category": "general",
        },
    )


def _insert_audit(
    connection,
    *,
    audit_id: uuid.UUID,
    scholarship_id: uuid.UUID | None,
    admin_user_id: uuid.UUID,
    action: str,
    target_type: str,
    target_id: uuid.UUID | None,
    notes: str | None,
    details: dict | None,
) -> None:
    connection.execute(
        text(
            """
            INSERT INTO verification_audit_logs
                (id, scholarship_id, admin_user_id, action, target_type, target_id, notes, details)
            VALUES
                (:id, :scholarship_id, :admin_user_id, :action, :target_type, :target_id,
                 :notes, CAST(:details AS JSONB))
            """
        ),
        {
            "id": audit_id,
            "scholarship_id": scholarship_id,
            "admin_user_id": admin_user_id,
            "action": action,
            "target_type": target_type,
            "target_id": target_id,
            "notes": notes,
            "details": json.dumps(details) if details is not None else None,
        },
    )


def _seed_referenced_audit_row(connection) -> dict:
    """Insert a user, a scholarship and an audit row that references the scholarship."""
    user_id = uuid.uuid4()
    scholarship_id = uuid.uuid4()
    audit_id = uuid.uuid4()
    _insert_user(connection, user_id)
    _insert_scholarship(connection, scholarship_id)
    _insert_audit(
        connection,
        audit_id=audit_id,
        scholarship_id=scholarship_id,
        admin_user_id=user_id,
        action=ORIGINAL_ACTION,
        target_type=ORIGINAL_TARGET_TYPE,
        target_id=scholarship_id,
        notes=ORIGINAL_NOTES,
        details=ORIGINAL_DETAILS,
    )
    connection.commit()
    return {"user_id": user_id, "scholarship_id": scholarship_id, "audit_id": audit_id}


def _audit_action(connection, audit_id: uuid.UUID) -> str | None:
    return _scalar(
        connection,
        "SELECT action FROM verification_audit_logs WHERE id = :id",
        id=audit_id,
    )


def _audit_row_count(connection, audit_id: uuid.UUID) -> int:
    return _scalar(
        connection,
        "SELECT count(*) FROM verification_audit_logs WHERE id = :id",
        id=audit_id,
    )


def test_full_upgrade_to_head_in_isolated_schema(isolated_schema) -> None:
    connection, config, schema = isolated_schema

    command.upgrade(config, "head")
    connection.commit()

    assert "verification_audit_logs" in set(inspect(connection).get_table_names(schema=schema))
    current = MigrationContext.configure(connection).get_current_revision()
    connection.commit()
    assert current == PROTECT_AUDIT_LOGS_REVISION


def test_audit_scholarship_id_is_nullable(isolated_schema) -> None:
    connection, config, _schema = isolated_schema
    command.upgrade(config, "head")
    connection.commit()

    user_id = uuid.uuid4()
    audit_id = uuid.uuid4()
    _insert_user(connection, user_id)
    _insert_audit(
        connection,
        audit_id=audit_id,
        scholarship_id=None,
        admin_user_id=user_id,
        action="admin_provision",
        target_type="user",
        target_id=None,
        notes=None,
        details=None,
    )
    connection.commit()

    assert (
        _scalar(
            connection,
            "SELECT count(*) FROM verification_audit_logs "
            "WHERE id = :id AND scholarship_id IS NULL",
            id=audit_id,
        )
        == 1
    )


def test_audit_update_is_rejected_by_trigger(isolated_schema) -> None:
    connection, config, _schema = isolated_schema
    command.upgrade(config, "head")
    connection.commit()
    seeded = _seed_referenced_audit_row(connection)

    with pytest.raises(DBAPIError) as excinfo:
        connection.execute(
            text("UPDATE verification_audit_logs SET action = 'tampered' WHERE id = :id"),
            {"id": seeded["audit_id"]},
        )
    assert _sqlstate(excinfo.value) == "P0001"
    assert APPEND_ONLY_MESSAGE in str(excinfo.value)
    connection.rollback()

    assert _audit_action(connection, seeded["audit_id"]) == ORIGINAL_ACTION


def test_audit_delete_is_rejected_by_trigger(isolated_schema) -> None:
    connection, config, _schema = isolated_schema
    command.upgrade(config, "head")
    connection.commit()
    seeded = _seed_referenced_audit_row(connection)

    with pytest.raises(DBAPIError) as excinfo:
        connection.execute(
            text("DELETE FROM verification_audit_logs WHERE id = :id"),
            {"id": seeded["audit_id"]},
        )
    assert _sqlstate(excinfo.value) == "P0001"
    assert APPEND_ONLY_MESSAGE in str(excinfo.value)
    connection.rollback()

    assert _audit_row_count(connection, seeded["audit_id"]) == 1


def test_deleting_referenced_scholarship_is_restricted_by_fk(isolated_schema) -> None:
    connection, config, _schema = isolated_schema
    command.upgrade(config, "head")
    connection.commit()
    seeded = _seed_referenced_audit_row(connection)

    with pytest.raises(IntegrityError) as excinfo:
        connection.execute(
            text("DELETE FROM scholarships WHERE id = :id"),
            {"id": seeded["scholarship_id"]},
        )
    assert _sqlstate(excinfo.value) == "23503"
    connection.rollback()

    assert (
        _scalar(
            connection,
            "SELECT count(*) FROM scholarships WHERE id = :id",
            id=seeded["scholarship_id"],
        )
        == 1
    )


def test_audit_record_intact_after_rejected_operations(isolated_schema) -> None:
    connection, config, _schema = isolated_schema
    command.upgrade(config, "head")
    connection.commit()
    seeded = _seed_referenced_audit_row(connection)

    with pytest.raises(DBAPIError):
        connection.execute(
            text("UPDATE verification_audit_logs SET notes = 'tampered' WHERE id = :id"),
            {"id": seeded["audit_id"]},
        )
    connection.rollback()

    with pytest.raises(DBAPIError):
        connection.execute(
            text("DELETE FROM verification_audit_logs WHERE id = :id"),
            {"id": seeded["audit_id"]},
        )
    connection.rollback()

    with pytest.raises(IntegrityError):
        connection.execute(
            text("DELETE FROM scholarships WHERE id = :id"),
            {"id": seeded["scholarship_id"]},
        )
    connection.rollback()

    row = connection.execute(
        text(
            """
            SELECT scholarship_id, action, target_type, notes, details
            FROM verification_audit_logs
            WHERE id = :id
            """
        ),
        {"id": seeded["audit_id"]},
    ).one()
    assert row.scholarship_id == seeded["scholarship_id"]
    assert row.action == ORIGINAL_ACTION
    assert row.target_type == ORIGINAL_TARGET_TYPE
    assert row.notes == ORIGINAL_NOTES
    assert row.details == ORIGINAL_DETAILS


def test_downgrade_refused_while_audit_rows_exist(isolated_schema) -> None:
    connection, config, schema = isolated_schema
    command.upgrade(config, "head")
    connection.commit()
    seeded = _seed_referenced_audit_row(connection)

    with pytest.raises(RuntimeError, match="contains rows"):
        command.downgrade(config, AUDIT_LOGS_REVISION)
    connection.rollback()

    assert _schema_trigger_count(connection, schema) == 2
    assert _audit_row_count(connection, seeded["audit_id"]) == 1


def test_empty_table_downgrade_and_reupgrade_cycle(isolated_schema) -> None:
    connection, config, schema = isolated_schema
    command.upgrade(config, "head")
    connection.commit()

    command.downgrade(config, AUDIT_LOGS_REVISION)
    connection.commit()

    assert _schema_trigger_count(connection, schema) == 0
    assert (
        _scalar(
            connection,
            """
            SELECT is_nullable
            FROM information_schema.columns
            WHERE table_schema = :schema
              AND table_name = 'verification_audit_logs'
              AND column_name = 'scholarship_id'
            """,
            schema=schema,
        )
        == "NO"
    )
    assert _fk_confdeltype(connection, schema) == "c"  # CASCADE
    connection.commit()

    command.upgrade(config, "head")
    connection.commit()

    assert _schema_trigger_count(connection, schema) == 2
    assert _fk_confdeltype(connection, schema) == "r"  # RESTRICT
    current = MigrationContext.configure(connection).get_current_revision()
    connection.commit()
    assert current == PROTECT_AUDIT_LOGS_REVISION


def test_truncate_is_blocked_by_trigger(isolated_schema) -> None:
    connection, config, schema = isolated_schema
    command.upgrade(config, "head")
    connection.commit()
    seeded = _seed_referenced_audit_row(connection)

    quoted_schema = f'"{schema}"'
    with pytest.raises(DBAPIError) as excinfo:
        connection.exec_driver_sql(f"TRUNCATE {quoted_schema}.verification_audit_logs")
    connection.rollback()

    assert _sqlstate(excinfo.value) == "P0001"
    assert APPEND_ONLY_MESSAGE in str(excinfo.value)
    assert _audit_row_count(connection, seeded["audit_id"]) == 1
    assert _audit_action(connection, seeded["audit_id"]) == ORIGINAL_ACTION
    assert (
        _scalar(
            connection,
            """
            SELECT count(*)
            FROM pg_trigger t
            JOIN pg_class c ON c.oid = t.tgrelid
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = :schema
              AND t.tgname = 'trg_prevent_audit_log_truncate'
              AND NOT t.tgisinternal
            """,
            schema=schema,
        )
        == 1
    )
