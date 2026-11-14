"""Renombrar las tablas al español.

Las columnas y el API no cambian. En PostgreSQL las llaves foráneas apuntan a la
tabla (no a su nombre), así que se mantienen; en SQLite se actualizan al renombrar.

Revision ID: d7a3e5c9b1f2
Revises: c4e8a1b2d3f5
"""
from typing import Sequence, Union

from alembic import op


revision: str = "d7a3e5c9b1f2"
down_revision: Union[str, Sequence[str], None] = "c4e8a1b2d3f5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# nombre anterior -> nombre nuevo
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


def upgrade() -> None:
    for anterior, nuevo in TABLAS.items():
        op.rename_table(anterior, nuevo)


def downgrade() -> None:
    for anterior, nuevo in reversed(list(TABLAS.items())):
        op.rename_table(nuevo, anterior)
