"""Unir migraciones de recuperacion e indices

Revision ID: 52b9bd4ad7ba
Revises: 0002_password_recovery, 699e9c81b660
Create Date: 2026-10-16 08:39:21.105851

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '52b9bd4ad7ba'
down_revision: Union[str, Sequence[str], None] = ('0002_password_recovery', '699e9c81b660')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
