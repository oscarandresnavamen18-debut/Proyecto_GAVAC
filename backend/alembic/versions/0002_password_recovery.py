
"""Add password recovery and token revocation support.

Revision ID: 0002_password_recovery
Revises: 0001_initial_schema
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0002_password_recovery"
down_revision: Union[str, None] = "0001_initial_schema"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if not inspector.has_table("users"):
        raise RuntimeError("No existe la tabla users.")

    if not inspector.has_table("password_reset_codes"):
        raise RuntimeError(
            "No existe password_reset_codes. "
            "Debe revisarse la migración inicial antes de continuar."
        )

    user_columns = {
        column["name"]: column
        for column in inspector.get_columns("users")
    }

    if "token_version" not in user_columns:
        op.add_column(
            "users",
            sa.Column(
                "token_version",
                sa.Integer(),
                server_default="0",
                nullable=False,
            ),
        )
    elif user_columns["token_version"]["type"].python_type is not int:
        raise RuntimeError("La columna token_version tiene un tipo incompatible.")

    reset_columns = {
        column["name"]
        for column in inspector.get_columns("password_reset_codes")
    }
    required_columns = {
        "user_id",
        "code_hash",
        "created_at",
        "expires_at",
        "failed_attempts",
    }

    if not required_columns.issubset(reset_columns):
        raise RuntimeError(
            "password_reset_codes no tiene la estructura esperada."
        )


def downgrade() -> None:
    # token_version y password_reset_codes pertenecen también
    # a la migración inicial 0001. No deben eliminarse aquí.
    pass
