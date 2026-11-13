
from logging.config import fileConfig
from alembic import context
from sqlalchemy import engine_from_config, pool, make_url
from app.config import settings
from app.db import Base
from app.models import User, Farm, Animal, AnimalEvent, PasswordResetCode

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

def get_url():
    url = make_url(settings.database_url)
    environment = settings.environment.lower()
    if url.get_backend_name() == "postgresql":
        return url.set(drivername="postgresql+psycopg")
    if url.get_backend_name() == "sqlite" and environment == "test":
        return url
    raise RuntimeError("La base de datos debe ser PostgreSQL fuera del entorno de pruebas.")

def run_migrations_offline():
    context.configure(
        url=get_url().render_as_string(hide_password=False),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()

def do_run_migrations(connection):
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online():
    configuration = config.get_section(config.config_ini_section) or {}
    configuration["sqlalchemy.url"] = get_url().render_as_string(hide_password=False)
    connectable = engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    try:
        with connectable.connect() as connection:
            do_run_migrations(connection)
    finally:
        connectable.dispose()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
