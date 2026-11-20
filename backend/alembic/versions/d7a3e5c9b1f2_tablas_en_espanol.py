
"""Renombrar las tablas al español.

Las columnas y el API no cambian.
Revision ID: d7a3e5c9b1f2
Revises: c4e8a1b2d3f5
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "d7a3e5c9b1f2"
down_revision: Union[str, None] = "c4e8a1b2d3f5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

TABLAS = {
    "users": "usuarios",
    "farms": "fincas",
    "animals": "animales",
    "cattle_events": "eventos_animales",
    "health_records": "registros_sanitarios",
    "breeding_records": "registros_reproductivos",
    "production_records": "registros_produccion",
    "inventory_items": "insumos",
    "inventory_movements": "movimientos_insumos",
    "audit_logs": "auditoria",
    "password_reset_codes": "codigos_recuperacion_contrasena",
    "alternate_email_verification_codes": "codigos_verificacion_correo",
}


def renombrar_tabla(origen: str, destino: str) -> None:
    inspector = sa.inspect(op.get_bind())
    tablas = set(inspector.get_table_names())

    if origen in tablas and destino not in tablas:
        op.rename_table(origen, destino)
    elif origen in tablas and destino in tablas:
        raise RuntimeError(
            f"Existen ambas tablas '{origen}' y '{destino}'. "
            "Se requiere revisar el esquema antes de continuar."
        )
    elif origen not in tablas and destino not in tablas:
        raise RuntimeError(
            f"No existe ninguna de las tablas '{origen}' o '{destino}'."
        )


def upgrade() -> None:
    for anterior, nuevo in TABLAS.items():
        renombrar_tabla(anterior, nuevo)


def downgrade() -> None:
    for anterior, nuevo in reversed(list(TABLAS.items())):
        renombrar_tabla(nuevo, anterior)
