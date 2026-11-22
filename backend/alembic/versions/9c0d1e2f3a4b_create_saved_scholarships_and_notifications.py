"""create saved_scholarships and notifications tables

Revision ID: 9c0d1e2f3a4b
Revises: 8b9c0d1e2f3a
Create Date: 2026-11-22 23:15:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "9c0d1e2f3a4b"
down_revision: Union[str, Sequence[str], None] = "8b9c0d1e2f3a"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. saved_scholarships
    op.create_table(
        "saved_scholarships",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("scholarship_id", sa.Uuid(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["scholarship_id"],
            ["scholarships.id"],
            name="fk_saved_scholarships_scholarship_id",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_saved_scholarships_user_id",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_saved_scholarships"),
        sa.UniqueConstraint("user_id", "scholarship_id", name="uq_saved_scholarships_user_scholarship"),
    )
    op.create_index(
        op.f("ix_saved_scholarships_scholarship_id"),
        "saved_scholarships",
        ["scholarship_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_saved_scholarships_user_id"),
        "saved_scholarships",
        ["user_id"],
        unique=False,
    )

    # 2. notifications
    op.create_table(
        "notifications",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("notification_type", sa.String(length=64), nullable=False, server_default="general"),
        sa.Column("is_read", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("link_url", sa.String(length=512), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_notifications_user_id",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_notifications"),
    )
    op.create_index(
        op.f("ix_notifications_user_id"),
        "notifications",
        ["user_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_notifications_is_read"),
        "notifications",
        ["is_read"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_notifications_is_read"), table_name="notifications")
    op.drop_index(op.f("ix_notifications_user_id"), table_name="notifications")
    op.drop_table("notifications")

    op.drop_index(op.f("ix_saved_scholarships_user_id"), table_name="saved_scholarships")
    op.drop_index(op.f("ix_saved_scholarships_scholarship_id"), table_name="saved_scholarships")
    op.drop_table("saved_scholarships")
