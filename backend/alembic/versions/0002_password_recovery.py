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
    columns = [col['name'] for col in inspector.get_columns('users')]
    if 'token_version' not in columns:
        op.add_column(
            "users",
            sa.Column("token_version", sa.Integer(), server_default="0", nullable=False),
        )
    if not inspector.has_table('password_reset_codes'):
        op.create_table(
            "password_reset_codes",
            sa.Column("user_id", sa.Integer(), nullable=False),
            sa.Column("code_hash", sa.String(length=64), nullable=False),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("failed_attempts", sa.Integer(), server_default="0", nullable=False),
            sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("user_id"),
        )

def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if inspector.has_table("password_reset_codes"):
        op.drop_table("password_reset_codes")
    columns = [col["name"] for col in inspector.get_columns("users")]
    if "token_version" in columns:
        with op.batch_alter_table("users") as batch_op:
            batch_op.drop_column("token_version")