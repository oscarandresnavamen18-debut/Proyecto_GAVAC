"""Agregar identidad de proveedores sociales.

Revision ID: a3f1c9d27b44
Revises: 8f2c1a6d4e90
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "a3f1c9d27b44"
down_revision: Union[str, Sequence[str], None] = "8f2c1a6d4e90"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("users") as batch_op:
        batch_op.alter_column("hashed_password", existing_type=sa.String(length=255), nullable=True)
        batch_op.add_column(sa.Column("auth_provider", sa.String(length=20), server_default="local", nullable=False))
        batch_op.add_column(sa.Column("provider_subject", sa.String(length=255), nullable=True))
        batch_op.create_unique_constraint("uq_user_provider_subject", ["auth_provider", "provider_subject"])


def downgrade() -> None:
    bind = op.get_bind()
    social_users = bind.execute(sa.text("SELECT COUNT(*) FROM users WHERE hashed_password IS NULL")).scalar_one()
    if social_users:
        raise RuntimeError("No se puede revertir la autenticación social mientras existan usuarios sin contraseña.")
    with op.batch_alter_table("users") as batch_op:
        batch_op.drop_constraint("uq_user_provider_subject", type_="unique")
        batch_op.drop_column("provider_subject")
        batch_op.drop_column("auth_provider")
        batch_op.alter_column("hashed_password", existing_type=sa.String(length=255), nullable=False)
