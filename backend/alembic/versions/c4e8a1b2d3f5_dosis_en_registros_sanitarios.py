
"""Agregar dosis a los registros sanitarios.

Revision ID: c4e8a1b2d3f5
Revises: b7d4e2f1a9c3
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "c4e8a1b2d3f5"
down_revision: Union[str, None] = "b7d4e2f1a9c3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if not inspector.has_table("health_records"):
        raise RuntimeError("No existe la tabla health_records.")

    columns = {
        column["name"]
        for column in inspector.get_columns("health_records")
    }

    if "dose" not in columns:
        with op.batch_alter_table("health_records") as batch_op:
            batch_op.add_column(
                sa.Column("dose", sa.String(length=60), nullable=True)
            )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if inspector.has_table("health_records"):
        columns = {
            column["name"]
            for column in inspector.get_columns("health_records")
        }

        if "dose" in columns:
            with op.batch_alter_table("health_records") as batch_op:
                batch_op.drop_column("dose")
