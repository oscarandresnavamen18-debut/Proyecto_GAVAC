"""Esquema inicial de usuarios, fincas, animales y eventos

Revision ID: 0001_initial_schema
Revises:
Create Date: 2026-10-10 12:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


revision: str = '0001_initial_schema'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('email', sa.String(length=150), nullable=False),
        sa.Column('full_name', sa.String(length=100), nullable=False),
        sa.Column('hashed_password', sa.String(length=255), nullable=False),
        sa.Column('role', sa.Enum('ADMIN', 'VETERINARIO', 'MAYORDOMO', name='userrole'), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('NOW()')),
        sa.Column('token_version', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('farm_id', sa.Integer(), nullable=True),
        sa.Column('alternate_email', sa.String(length=150), nullable=True),
        sa.Column('alternate_email_verified_at', sa.DateTime(), nullable=True),
        *([sa.ForeignKeyConstraint(['farm_id'], ['farms.id'], name='fk_users_farm_id', ondelete='SET NULL')] if op.get_bind().dialect.name == 'sqlite' else []),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('alternate_email'),
        sa.UniqueConstraint('email')
    )
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)
    op.create_index(op.f('ix_users_id'), 'users', ['id'], unique=False)

    op.create_table(
        'farms',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('location', sa.String(length=150), nullable=True),
        sa.Column('owner_id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('NOW()')),
        sa.Column('token_version', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('farm_id', sa.Integer(), nullable=True),
        sa.Column('alternate_email', sa.String(length=150), nullable=True),
        sa.Column('alternate_email_verified_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['farm_id'], ['farms.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['owner_id'], ['users.id'], ondelete='RESTRICT'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('alternate_email')
    )
    op.create_index(op.f('ix_farms_id'), 'farms', ['id'], unique=False)

    if op.get_bind().dialect.name != 'sqlite':
        op.create_foreign_key('fk_users_farm_id', 'users', 'farms', ['farm_id'], ['id'], ondelete='SET NULL')

    op.create_table(
        'animals',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('finca_id', sa.Integer(), nullable=False),
        sa.Column('tag_id', sa.String(length=50), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=True),
        sa.Column('gender', sa.Enum('MACHO', 'HEMBRA', name='cattlegender'), nullable=False),
        sa.Column('birth_date', sa.Date(), nullable=False),
        sa.Column('breed', sa.String(length=50), nullable=False),
        sa.Column('color', sa.String(length=50), nullable=True),
        sa.Column('current_weight', sa.Numeric(precision=6, scale=2), nullable=False),
        sa.Column('status', sa.Enum('ACTIVO', 'VENDIDO', 'MUERTO', 'TRASLADADO', name='cattlestatus'), nullable=False, server_default='ACTIVO'),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('NOW()')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('NOW()')),
        sa.Column('deleted_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['finca_id'], ['farms.id'], ondelete='RESTRICT'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_animals_finca_id'), 'animals', ['finca_id'], unique=False)
    op.create_index(op.f('ix_animals_id'), 'animals', ['id'], unique=False)
    op.create_index(op.f('ix_animals_tag_id'), 'animals', ['tag_id'], unique=True)
    op.create_index(op.f('ix_animals_is_active'), 'animals', ['is_active'], unique=False)
    op.create_index('idx_animal_finca_active', 'animals', ['finca_id', 'is_active'], unique=False)
    op.create_index('idx_animal_status_active', 'animals', ['status', 'is_active'], unique=False)

    op.create_table(
        'cattle_events',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('animal_id', sa.Integer(), nullable=False),
        sa.Column('event_type', sa.Enum('VACUNACION', 'DESPARASITACION', 'PESAJE', 'TRATAMIENTO', name='eventtype'), nullable=False),
        sa.Column('event_date', sa.Date(), nullable=False),
        sa.Column('weight', sa.Numeric(precision=6, scale=2), nullable=True),
        sa.Column('description', sa.String(length=255), nullable=False),
        sa.Column('withdrawal_days', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('performed_by_id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('NOW()')),
        sa.ForeignKeyConstraint(['animal_id'], ['animals.id'], ondelete='RESTRICT'),
        sa.ForeignKeyConstraint(['performed_by_id'], ['users.id'], ondelete='RESTRICT'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_cattle_events_animal_id'), 'cattle_events', ['animal_id'], unique=False)
    op.create_index(op.f('ix_cattle_events_id'), 'cattle_events', ['id'], unique=False)
    op.create_index('idx_events_animal_type', 'cattle_events', ['animal_id', 'event_type'], unique=False)

    op.create_table(
        'password_reset_codes',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('code_hash', sa.String(length=255), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('NOW()')),
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.Column('failed_attempts', sa.Integer(), nullable=False, server_default='0'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_password_reset_codes_id'), 'password_reset_codes', ['id'], unique=False)
    op.create_index(op.f('ix_password_reset_codes_user_id'), 'password_reset_codes', ['user_id'], unique=True)

    op.create_table(
        'alternate_email_verification_codes',
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('email', sa.String(length=150), nullable=False),
        sa.Column('code_hash', sa.String(length=255), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('NOW()')),
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.Column('failed_attempts', sa.Integer(), nullable=False, server_default='0'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('user_id')
    )


def downgrade() -> None:
    op.drop_index('idx_events_animal_type', table_name='cattle_events')
    op.drop_index(op.f('ix_cattle_events_id'), table_name='cattle_events')
    op.drop_index(op.f('ix_cattle_events_animal_id'), table_name='cattle_events')
    op.drop_table('cattle_events')
    op.drop_index('idx_animal_status_active', table_name='animals')
    op.drop_index('idx_animal_finca_active', table_name='animals')
    op.drop_index(op.f('ix_animals_is_active'), table_name='animals')
    op.drop_index(op.f('ix_animals_tag_id'), table_name='animals')
    op.drop_index(op.f('ix_animals_id'), table_name='animals')
    op.drop_index(op.f('ix_animals_finca_id'), table_name='animals')
    op.drop_table('animals')
    if op.get_bind().dialect.name != 'sqlite':
        op.drop_constraint('fk_users_farm_id', 'users', type_='foreignkey')
    op.drop_index(op.f('ix_farms_id'), table_name='farms')
    op.drop_table('farms')
    op.drop_index(op.f('ix_users_id'), table_name='users')
    op.drop_index(op.f('ix_users_email'), table_name='users')
    op.drop_table('users')
