"""create verification audit logs table

Revision ID: 5c8a2b1f4d9e
Revises: 4b9c1d2e3f4a
Create Date: 2026-11-22 13:10:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "5c8a2b1f4d9e"
down_revision: Union[str, Sequence[str], None] = "4b9c1d2e3f4a"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "verification_audit_logs",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("scholarship_id", sa.Uuid(), nullable=False),
        sa.Column("admin_user_id", sa.Uuid(), nullable=False),
        sa.Column("action", sa.String(length=64), nullable=False),
        sa.Column("target_type", sa.String(length=64), nullable=False),
        sa.Column("target_id", sa.Uuid(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "details",
            postgresql.JSONB(astext_type=sa.Text()).with_variant(
                sa.JSON(), "sqlite"
            ),
            nullable=True,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["admin_user_id"],
            ["users.id"],
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["scholarship_id"],
            ["scholarships.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_verification_audit_logs_admin",
        "verification_audit_logs",
        ["admin_user_id", "created_at"],
        unique=False,
    )
    op.create_index(
        "ix_verification_audit_logs_scholarship",
        "verification_audit_logs",
        ["scholarship_id", "created_at"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_verification_audit_logs_scholarship",
        table_name="verification_audit_logs",
    )
    op.drop_index(
        "ix_verification_audit_logs_admin",
        table_name="verification_audit_logs",
    )
    op.drop_table("verification_audit_logs")
