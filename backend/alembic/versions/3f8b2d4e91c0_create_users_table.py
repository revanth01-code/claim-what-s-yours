"""create users table

Revision ID: 3f8b2d4e91c0
Revises: 6123f9c0e152
Create Date: 2026-11-22 10:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "3f8b2d4e91c0"
down_revision: Union[str, Sequence[str], None] = "6123f9c0e152"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("firebase_uid", sa.String(length=128), nullable=False),
        sa.Column("email", sa.String(length=320), nullable=True),
        sa.Column(
            "email_verified",
            sa.Boolean(),
            server_default="false",
            nullable=False,
        ),
        sa.Column("display_name", sa.String(length=255), nullable=True),
        sa.Column(
            "role",
            sa.String(length=32),
            server_default="student",
            nullable=False,
        ),
        sa.Column(
            "is_active",
            sa.Boolean(),
            server_default="true",
            nullable=False,
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
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("firebase_uid", name="uq_users_firebase_uid"),
        sa.CheckConstraint("role IN ('student')", name="ck_users_role_valid"),
        sa.CheckConstraint("length(firebase_uid) > 0", name="ck_users_firebase_uid_not_empty"),
    )


def downgrade() -> None:
    op.drop_table("users")
