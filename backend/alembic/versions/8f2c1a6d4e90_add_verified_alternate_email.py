
"""Add verified alternate email support.

Revision ID: 8f2c1a6d4e90
Revises: 52b9bd4ad7ba
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "8f2c1a6d4e90"
down_revision: Union[str, None] = "52b9bd4ad7ba"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if not inspector.has_table("users"):
        raise RuntimeError("No existe la tabla users.")

    user_columns = {
        column["name"]
        for column in inspector.get_columns("users")
    }

    required_columns = {"alternate_email", "alternate_email_verified_at"}
    if not required_columns.issubset(user_columns):
        raise RuntimeError(
            "Faltan columnas de correo alternativo creadas por 0001_initial_schema."
        )

    if not inspector.has_table("alternate_email_verification_codes"):
        raise RuntimeError(
            "No existe alternate_email_verification_codes, creada por 0001_initial_schema."
        )

    indexes = {
        index["name"]
        for index in inspector.get_indexes("users")
    }

    if "ix_users_alternate_email" not in indexes:
        op.create_index(
            "ix_users_alternate_email",
            "users",
            ["alternate_email"],
            unique=True,
        )

    op.create_table(
        "health_records",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("animal_id", sa.Integer(), nullable=False),
        sa.Column("created_by", sa.Integer(), nullable=True),
        sa.Column("record_type", sa.String(30), nullable=False),
        sa.Column("recorded_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("diagnosis", sa.String(500), nullable=True),
        sa.Column("treatment", sa.Text(), nullable=True),
        sa.Column("veterinarian", sa.String(120), nullable=True),
        sa.Column("next_check_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["animal_id"], ["animals.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_health_records_animal_date", "health_records", ["animal_id", "recorded_at"])

    op.create_table(
        "breeding_records",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("animal_id", sa.Integer(), nullable=False),
        sa.Column("related_animal_id", sa.Integer(), nullable=True),
        sa.Column("created_by", sa.Integer(), nullable=True),
        sa.Column("record_type", sa.String(30), nullable=False),
        sa.Column("recorded_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expected_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["animal_id"], ["animals.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["related_animal_id"], ["animals.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_breeding_records_animal_date", "breeding_records", ["animal_id", "recorded_at"])

    op.create_table(
        "production_records",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("animal_id", sa.Integer(), nullable=False),
        sa.Column("created_by", sa.Integer(), nullable=True),
        sa.Column("record_type", sa.String(20), nullable=False),
        sa.Column("quantity", sa.Numeric(12, 3), nullable=False),
        sa.Column("unit", sa.String(20), nullable=False),
        sa.Column("recorded_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("quantity > 0", name="ck_production_records_quantity_positive"),
        sa.ForeignKeyConstraint(["animal_id"], ["animals.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_production_records_animal_date", "production_records", ["animal_id", "recorded_at"])

    op.create_table(
        "inventory_items",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("farm_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(120), nullable=False),
        sa.Column("category", sa.String(40), nullable=False),
        sa.Column("sku", sa.String(60), nullable=True),
        sa.Column("unit", sa.String(20), nullable=False),
        sa.Column("minimum_quantity", sa.Numeric(12, 3), server_default="0", nullable=False),
        sa.Column("is_active", sa.Boolean(), server_default=sa.true(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["farm_id"], ["farms.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("farm_id", "sku", name="uq_inventory_items_farm_sku"),
    )

    op.create_table(
        "inventory_movements",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("item_id", sa.Integer(), nullable=False),
        sa.Column("animal_id", sa.Integer(), nullable=True),
        sa.Column("created_by", sa.Integer(), nullable=True),
        sa.Column("movement_type", sa.String(10), nullable=False),
        sa.Column("quantity", sa.Numeric(12, 3), nullable=False),
        sa.Column("recorded_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("quantity > 0", name="ck_inventory_movements_quantity_positive"),
        sa.ForeignKeyConstraint(["item_id"], ["inventory_items.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["animal_id"], ["animals.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_inventory_movements_item_date", "inventory_movements", ["item_id", "recorded_at"])

    op.create_table(
        "audit_logs",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("farm_id", sa.Integer(), nullable=True),
        sa.Column("actor_user_id", sa.Integer(), nullable=True),
        sa.Column("action", sa.String(60), nullable=False),
        sa.Column("entity_type", sa.String(60), nullable=False),
        sa.Column("entity_id", sa.Integer(), nullable=True),
        sa.Column("details", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["farm_id"], ["farms.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["actor_user_id"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_audit_logs_farm_created_at", "audit_logs", ["farm_id", "created_at"])


def downgrade() -> None:
    op.drop_index("ix_audit_logs_farm_created_at", table_name="audit_logs")
    op.drop_table("audit_logs")

    op.drop_index("ix_inventory_movements_item_date", table_name="inventory_movements")
    op.drop_table("inventory_movements")
    op.drop_table("inventory_items")

    op.drop_index("ix_production_records_animal_date", table_name="production_records")
    op.drop_table("production_records")

    op.drop_index("ix_breeding_records_animal_date", table_name="breeding_records")
    op.drop_table("breeding_records")

    op.drop_index("ix_health_records_animal_date", table_name="health_records")
    op.drop_table("health_records")

    op.drop_index("ix_users_alternate_email", table_name="users")
