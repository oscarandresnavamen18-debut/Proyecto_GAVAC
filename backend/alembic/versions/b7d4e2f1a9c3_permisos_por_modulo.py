"""Agregar permisos por módulo a los usuarios.

Revision ID: b7d4e2f1a9c3
Revises: a3f1c9d27b44
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "b7d4e2f1a9c3"
down_revision: Union[str, Sequence[str], None] = "a3f1c9d27b44"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("users") as batch_op:
        # NULL = se aplican los permisos por defecto del rol.
        batch_op.add_column(sa.Column("module_permissions", sa.JSON(), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("users") as batch_op:
        batch_op.drop_column("module_permissions")
