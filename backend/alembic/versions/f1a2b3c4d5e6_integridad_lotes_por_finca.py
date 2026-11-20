"""Garantizar que cada animal pertenezca a un lote de su finca."""

from alembic import op
import sqlalchemy as sa

revision = "f1a2b3c4d5e6"
down_revision = "e8b4f6a2c0d1"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    revision_actual = bind.execute(
        sa.text("SELECT version_num FROM alembic_version")
    ).scalar_one()

    if revision_actual != "e8b4f6a2c0d1":
        raise RuntimeError(
            f"Revision inesperada: {revision_actual}. Se esperaba e8b4f6a2c0d1."
        )

    invalid = bind.execute(sa.text("""
        SELECT COUNT(*)
        FROM animales a
        JOIN lotes l ON l.id = a.lote_id
        WHERE a.finca_id <> l.farm_id
    """)).scalar_one()

    orphan = bind.execute(sa.text("""
        SELECT COUNT(*)
        FROM animales a
        LEFT JOIN lotes l ON l.id = a.lote_id
        WHERE a.lote_id IS NOT NULL AND l.id IS NULL
    """)).scalar_one()

    if invalid or orphan:
        raise RuntimeError(
            f"Integridad invalida: cruces={invalid}, referencias inexistentes={orphan}"
        )

    with op.batch_alter_table("lotes") as batch_op:
        batch_op.create_unique_constraint(
            "uq_lotes_id_farm", ["id", "farm_id"]
        )

    with op.batch_alter_table("animales") as batch_op:
        batch_op.drop_constraint(
            "fk_animales_lote_id", type_="foreignkey"
        )
        batch_op.create_foreign_key(
            "fk_animales_lote_finca",
            "lotes",
            ["lote_id", "finca_id"],
            ["id", "farm_id"],
            ondelete="RESTRICT",
        )


def downgrade() -> None:
    with op.batch_alter_table("animales") as batch_op:
        batch_op.drop_constraint(
            "fk_animales_lote_finca", type_="foreignkey"
        )
        batch_op.create_foreign_key(
            "fk_animales_lote_id",
            "lotes",
            ["lote_id"],
            ["id"],
            ondelete="SET NULL",
        )

    with op.batch_alter_table("lotes") as batch_op:
        batch_op.drop_constraint(
            "uq_lotes_id_farm", type_="unique"
        )
