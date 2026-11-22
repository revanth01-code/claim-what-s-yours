"""create student_profiles table

Revision ID: 7a8b9c0d1e2f
Revises: 6d7e8f9a0b1c
Create Date: 2026-11-22 17:30:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "7a8b9c0d1e2f"
down_revision: Union[str, Sequence[str], None] = "6d7e8f9a0b1c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "student_profiles",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        # Personal
        sa.Column("full_name", sa.String(length=255), nullable=True),
        sa.Column("date_of_birth", sa.Date(), nullable=True),
        sa.Column("gender", sa.String(length=32), nullable=True),
        sa.Column("state", sa.String(length=100), nullable=True),
        sa.Column("district", sa.String(length=100), nullable=True),
        sa.Column("category", sa.String(length=64), nullable=True),
        sa.Column("is_disabled", sa.Boolean(), nullable=True),
        sa.Column("disability_type", sa.String(length=100), nullable=True),
        sa.Column("disability_percentage", sa.Numeric(precision=5, scale=2), nullable=True),
        sa.Column("phone_number", sa.String(length=20), nullable=True),
        # Academic
        sa.Column("education_level", sa.String(length=64), nullable=True),
        sa.Column("course", sa.String(length=128), nullable=True),
        sa.Column("stream", sa.String(length=128), nullable=True),
        sa.Column("institution_name", sa.String(length=255), nullable=True),
        sa.Column("institution_state", sa.String(length=100), nullable=True),
        sa.Column("institution_district", sa.String(length=100), nullable=True),
        sa.Column("board_or_university", sa.String(length=255), nullable=True),
        sa.Column("academic_year", sa.String(length=32), nullable=True),
        sa.Column("current_year_of_study", sa.Integer(), nullable=True),
        sa.Column("previous_exam_percentage", sa.Numeric(precision=5, scale=2), nullable=True),
        # Financial
        sa.Column("annual_family_income", sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column("income_bracket", sa.String(length=64), nullable=True),
        # Additional
        sa.Column("is_hosteller", sa.Boolean(), nullable=True),
        sa.Column(
            "additional_attributes",
            postgresql.JSONB(astext_type=sa.Text()).with_variant(sa.JSON(), "sqlite"),
            nullable=True,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_student_profiles_user_id_users",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_student_profiles"),
        sa.UniqueConstraint("user_id", name="uq_student_profiles_user_id"),
    )
    op.create_index(
        op.f("ix_student_profiles_user_id"),
        "student_profiles",
        ["user_id"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_student_profiles_user_id"), table_name="student_profiles")
    op.drop_table("student_profiles")
