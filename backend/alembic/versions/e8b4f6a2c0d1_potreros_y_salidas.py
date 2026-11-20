"""Potreros (lotes), movimientos entre potreros y salidas de animales.

Revision ID: e8b4f6a2c0d1
Revises: d7a3e5c9b1f2
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "e8b4f6a2c0d1"
down_revision: Union[str, Sequence[str], None] = "d7a3e5c9b1f2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

exit_type = sa.Enum("VENTA", "MUERTE", name="exittype")


def upgrade() -> None:
    op.create_table(
        "lotes",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("farm_id", sa.Integer(), sa.ForeignKey("fincas.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(length=80), nullable=False),
        sa.Column("description", sa.String(length=255), nullable=True),
        sa.Column("area_hectares", sa.Numeric(10, 2), nullable=True),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("farm_id", "name", name="uq_lotes_finca_nombre"),
    )
    op.create_index("ix_lotes_farm_id", "lotes", ["farm_id"])

    with op.batch_alter_table("animales") as batch_op:
        batch_op.add_column(sa.Column("lote_id", sa.Integer(), nullable=True))
        batch_op.create_foreign_key(
            "fk_animales_lote_id", "lotes", ["lote_id"], ["id"], ondelete="SET NULL")
        batch_op.create_index("ix_animales_lote_id", ["lote_id"])

    op.create_table(
        "movimientos_lote",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("animal_id", sa.Integer(), sa.ForeignKey("animales.id", ondelete="CASCADE"), nullable=False),
        sa.Column("from_lot_id", sa.Integer(), sa.ForeignKey("lotes.id", ondelete="SET NULL"), nullable=True),
        sa.Column("to_lot_id", sa.Integer(), sa.ForeignKey("lotes.id", ondelete="SET NULL"), nullable=True),
        sa.Column("moved_at", sa.Date(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_by", sa.Integer(), sa.ForeignKey("usuarios.id", ondelete="SET NULL"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_movimientos_lote_animal_fecha", "movimientos_lote", ["animal_id", "moved_at"])

    op.create_table(
        "salidas_animales",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("animal_id", sa.Integer(), sa.ForeignKey("animales.id", ondelete="CASCADE"),
                  nullable=False, unique=True),
        sa.Column("exit_type", exit_type, nullable=False),
        sa.Column("exit_date", sa.Date(), nullable=False),
        sa.Column("price", sa.Numeric(14, 2), nullable=True),
        sa.Column("buyer", sa.String(length=120), nullable=True),
        sa.Column("cause", sa.String(length=255), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("lot_id", sa.Integer(), sa.ForeignKey("lotes.id", ondelete="SET NULL"), nullable=True),
        sa.Column("created_by", sa.Integer(), sa.ForeignKey("usuarios.id", ondelete="SET NULL"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("salidas_animales")
    exit_type.drop(op.get_bind(), checkfirst=True)
    op.drop_index("ix_movimientos_lote_animal_fecha", table_name="movimientos_lote")
    op.drop_table("movimientos_lote")
    with op.batch_alter_table("animales") as batch_op:
        batch_op.drop_index("ix_animales_lote_id")
        batch_op.drop_constraint("fk_animales_lote_id", type_="foreignkey")
        batch_op.drop_column("lote_id")
    op.drop_index("ix_lotes_farm_id", table_name="lotes")
    op.drop_table("lotes")
