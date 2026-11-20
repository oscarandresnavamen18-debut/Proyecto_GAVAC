
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
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    columns = {column["name"] for column in inspector.get_columns("users")}
    constraints = {
        constraint["name"]
        for constraint in inspector.get_unique_constraints("users")
    }

    with op.batch_alter_table("users") as batch_op:
        if "hashed_password" in columns:
            batch_op.alter_column(
                "hashed_password",
                existing_type=sa.String(length=255),
                nullable=True,
            )
        if "auth_provider" not in columns:
            batch_op.add_column(
                sa.Column(
                    "auth_provider",
                    sa.String(length=20),
                    server_default="local",
                    nullable=False,
                )
            )
        if "provider_subject" not in columns:
            batch_op.add_column(
                sa.Column("provider_subject", sa.String(length=255), nullable=True)
            )
        if "uq_user_provider_subject" not in constraints:
            batch_op.create_unique_constraint(
                "uq_user_provider_subject",
                ["auth_provider", "provider_subject"],
            )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    columns = {column["name"] for column in inspector.get_columns("users")}
    constraints = {
        constraint["name"]
        for constraint in inspector.get_unique_constraints("users")
    }

    if "hashed_password" in columns:
        social_users = bind.execute(
            sa.text("SELECT COUNT(*) FROM users WHERE hashed_password IS NULL")
        ).scalar_one()
        if social_users:
            raise RuntimeError(
                "No se puede revertir la autenticación social mientras existan usuarios sin contraseña."
            )

    with op.batch_alter_table("users") as batch_op:
        if "uq_user_provider_subject" in constraints:
            batch_op.drop_constraint("uq_user_provider_subject", type_="unique")
        if "provider_subject" in columns:
            batch_op.drop_column("provider_subject")
        if "auth_provider" in columns:
            batch_op.drop_column("auth_provider")
        if "hashed_password" in columns:
            batch_op.alter_column(
                "hashed_password",
                existing_type=sa.String(length=255),
                nullable=False,
            )
