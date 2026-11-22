"""create application_records table

Revision ID: 8b9c0d1e2f3a
Revises: 7a8b9c0d1e2f
Create Date: 2026-11-22 20:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "8b9c0d1e2f3a"
down_revision: Union[str, Sequence[str], None] = "7a8b9c0d1e2f"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "application_records",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("scholarship_id", sa.Uuid(), nullable=False),
        sa.Column("portal_name", sa.String(length=128), nullable=False),
        sa.Column("application_reference_number", sa.String(length=128), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False, server_default="submitted"),
        sa.Column("academic_year", sa.String(length=32), nullable=False, server_default="2026-2027"),
        sa.Column("applied_amount", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("disbursed_amount", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("submitted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "timeline",
            postgresql.JSONB(astext_type=sa.Text()).with_variant(sa.JSON(), "sqlite"),
            nullable=False,
            server_default=sa.text("'[]'"),
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["scholarship_id"], ["scholarships.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_application_records_scholarship_id"), "application_records", ["scholarship_id"], unique=False)
    op.create_index(op.f("ix_application_records_user_id"), "application_records", ["user_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_application_records_user_id"), table_name="application_records")
    op.drop_index(op.f("ix_application_records_scholarship_id"), table_name="application_records")
    op.drop_table("application_records")

