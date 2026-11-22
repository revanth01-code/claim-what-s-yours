"""protect verification audit logs and restrict scholarship deletion

Revision ID: 6d7e8f9a0b1c
Revises: 5c8a2b1f4d9e
Create Date: 2026-11-22 13:45:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "6d7e8f9a0b1c"
down_revision: Union[str, Sequence[str], None] = "5c8a2b1f4d9e"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    dialect_name = bind.dialect.name

    if dialect_name == "postgresql":
        # Make scholarship_id nullable for non-scholarship audit events (e.g. admin provisioning)
        op.alter_column(
            "verification_audit_logs",
            "scholarship_id",
            existing_type=sa.Uuid(),
            nullable=True,
        )
        # Change foreign key from CASCADE to RESTRICT
        op.drop_constraint(
            "verification_audit_logs_scholarship_id_fkey",
            "verification_audit_logs",
            type_="foreignkey",
        )
        op.create_foreign_key(
            "verification_audit_logs_scholarship_id_fkey",
            "verification_audit_logs",
            "scholarships",
            ["scholarship_id"],
            ["id"],
            ondelete="RESTRICT",
        )
        # Create immutable append-only trigger
        op.execute("""
            CREATE OR REPLACE FUNCTION prevent_audit_log_modification()
            RETURNS TRIGGER AS $$
            BEGIN
                RAISE EXCEPTION 'verification_audit_logs records are append-only and cannot be modified or deleted';
            END;
            $$ LANGUAGE plpgsql;
        """)
        op.execute("""
            CREATE TRIGGER trg_prevent_audit_log_modification
            BEFORE UPDATE OR DELETE ON verification_audit_logs
            FOR EACH ROW
            EXECUTE FUNCTION prevent_audit_log_modification();
        """)
        # Block TRUNCATE too: row-level UPDATE/DELETE triggers do not fire on TRUNCATE.
        # Statement-level trigger reusing the same function (it always raises).
        op.execute("""
            CREATE TRIGGER trg_prevent_audit_log_truncate
            BEFORE TRUNCATE ON verification_audit_logs
            FOR EACH STATEMENT
            EXECUTE FUNCTION prevent_audit_log_modification();
        """)
    else:
        # SQLite / other dialect handling
        with op.batch_alter_table("verification_audit_logs") as batch_op:
            batch_op.alter_column(
                "scholarship_id",
                existing_type=sa.Uuid(),
                nullable=True,
            )
        op.execute("""
            CREATE TRIGGER IF NOT EXISTS trg_prevent_audit_log_update
            BEFORE UPDATE ON verification_audit_logs
            FOR EACH ROW
            BEGIN
                SELECT RAISE(ABORT, 'verification_audit_logs records are append-only and cannot be modified or deleted');
            END;
        """)
        op.execute("""
            CREATE TRIGGER IF NOT EXISTS trg_prevent_audit_log_delete
            BEFORE DELETE ON verification_audit_logs
            FOR EACH ROW
            BEGIN
                SELECT RAISE(ABORT, 'verification_audit_logs records are append-only and cannot be modified or deleted');
            END;
        """)


def downgrade() -> None:
    bind = op.get_bind()
    dialect_name = bind.dialect.name

    # Protect existing audit records: fail if records exist
    count = bind.execute(sa.text("SELECT COUNT(*) FROM verification_audit_logs")).scalar()
    if count and count > 0:
        raise RuntimeError(
            "Cannot downgrade migration: verification_audit_logs contains rows. Manual archival required."
        )

    if dialect_name == "postgresql":
        op.execute("DROP TRIGGER IF EXISTS trg_prevent_audit_log_truncate ON verification_audit_logs;")
        op.execute("DROP TRIGGER IF EXISTS trg_prevent_audit_log_modification ON verification_audit_logs;")
        op.execute("DROP FUNCTION IF EXISTS prevent_audit_log_modification();")
        op.drop_constraint(
            "verification_audit_logs_scholarship_id_fkey",
            "verification_audit_logs",
            type_="foreignkey",
        )
        op.create_foreign_key(
            "verification_audit_logs_scholarship_id_fkey",
            "verification_audit_logs",
            "scholarships",
            ["scholarship_id"],
            ["id"],
            ondelete="CASCADE",
        )
        op.alter_column(
            "verification_audit_logs",
            "scholarship_id",
            existing_type=sa.Uuid(),
            nullable=False,
        )
    else:
        op.execute("DROP TRIGGER IF EXISTS trg_prevent_audit_log_update;")
        op.execute("DROP TRIGGER IF EXISTS trg_prevent_audit_log_delete;")
        with op.batch_alter_table("verification_audit_logs") as batch_op:
            batch_op.alter_column(
                "scholarship_id",
                existing_type=sa.Uuid(),
                nullable=False,
            )
