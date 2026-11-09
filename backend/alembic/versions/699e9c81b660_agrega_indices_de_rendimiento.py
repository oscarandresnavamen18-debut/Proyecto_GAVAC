"""agrega indices de rendimiento

Revision ID: 699e9c81b660
Revises: 0001_initial_schema
Create Date: 2026-10-15

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "699e9c81b660"
down_revision: Union[str, None] = "0001_initial_schema"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_index("ix_animals_finca_status", "animals", ["finca_id", "status"], if_not_exists=True)
    op.create_index("ix_cattle_events_animal_fecha", "cattle_events", ["animal_id", "event_date"], if_not_exists=True)


def downgrade() -> None:
    op.drop_index("ix_cattle_events_animal_fecha", table_name="cattle_events")
    op.drop_index("ix_animals_finca_status", table_name="animals")
