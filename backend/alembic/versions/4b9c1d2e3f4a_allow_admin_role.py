"""allow admin role in users check constraint

Revision ID: 4b9c1d2e3f4a
Revises: 3f8b2d4e91c0
Create Date: 2026-11-22 13:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "4b9c1d2e3f4a"
down_revision: Union[str, Sequence[str], None] = "3f8b2d4e91c0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("users") as batch_op:
        batch_op.drop_constraint("ck_users_role_valid", type_="check")
        batch_op.create_check_constraint(
            "ck_users_role_valid",
            "role IN ('student', 'admin')",
        )


def downgrade() -> None:
    with op.batch_alter_table("users") as batch_op:
        batch_op.drop_constraint("ck_users_role_valid", type_="check")
        batch_op.create_check_constraint(
            "ck_users_role_valid",
            "role IN ('student')",
        )
