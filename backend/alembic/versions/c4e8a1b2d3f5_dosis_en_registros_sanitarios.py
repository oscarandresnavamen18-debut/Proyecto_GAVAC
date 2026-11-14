"""Agregar dosis a los registros sanitarios.

Revision ID: c4e8a1b2d3f5
Revises: b7d4e2f1a9c3
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "c4e8a1b2d3f5"
down_revision: Union[str, Sequence[str], None] = "b7d4e2f1a9c3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("health_records") as batch_op:
        batch_op.add_column(sa.Column("dose", sa.String(length=60), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("health_records") as batch_op:
        batch_op.drop_column("dose")
