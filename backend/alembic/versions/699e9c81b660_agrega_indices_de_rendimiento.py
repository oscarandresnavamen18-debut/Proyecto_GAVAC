
"""Agrega indices de rendimiento

Revision ID: 699e9c81b660
Revises: 0001_initial_schema
Create Date: 2026-10-15
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "699e9c81b660"
down_revision: Union[str, None] = "0001_initial_schema"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_index(
        "ix_animals_finca_status",
        "animals",
        ["finca_id", "status"],
        if_not_exists=True,
    )
    op.create_index(
        "ix_cattle_events_animal_fecha",
        "cattle_events",
        ["animal_id", "event_date"],
        if_not_exists=True,
    )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if inspector.has_table("cattle_events"):
        indexes = {index["name"] for index in inspector.get_indexes("cattle_events")}
        if "ix_cattle_events_animal_fecha" in indexes:
            op.drop_index("ix_cattle_events_animal_fecha", table_name="cattle_events")

    if inspector.has_table("animals"):
        indexes = {index["name"] for index in inspector.get_indexes("animals")}
        if "ix_animals_finca_status" in indexes:
            op.drop_index("ix_animals_finca_status", table_name="animals")
