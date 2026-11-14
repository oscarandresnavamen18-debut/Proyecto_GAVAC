import os
import subprocess
import sys
from pathlib import Path

from alembic.config import Config
from alembic.script import ScriptDirectory
from sqlalchemy import create_engine, inspect, text

from app.models import Animal, AnimalEvent


def test_alembic_migrations_upgrade_and_downgrade_on_isolated_sqlite(tmp_path):
    backend_dir = Path(__file__).resolve().parents[1]
    config = Config(str(backend_dir / "alembic.ini"))
    config.set_main_option("script_location", str(backend_dir / "alembic"))
    scripts = ScriptDirectory.from_config(config)
    database_url = f"sqlite:///{(tmp_path / 'migration.db').as_posix()}"
    env = os.environ.copy()
    env.update(
        DATABASE_URL=database_url,
        ENVIRONMENT="test",
        JWT_SECRET_KEY="test-only-secret-key-with-at-least-32-characters",
    )

    assert scripts.get_heads() == ["d7a3e5c9b1f2"]
    assert scripts.get_revision("d7a3e5c9b1f2").down_revision == "c4e8a1b2d3f5"
    assert scripts.get_revision("c4e8a1b2d3f5").down_revision == "b7d4e2f1a9c3"
    assert scripts.get_revision("b7d4e2f1a9c3").down_revision == "a3f1c9d27b44"
    social_revision = scripts.get_revision("a3f1c9d27b44")
    assert social_revision.down_revision == "8f2c1a6d4e90"
    assert "idx_animal_finca_active" in {index.name for index in Animal.__table__.indexes}
    assert "idx_events_animal_type" in {
        index.name for index in AnimalEvent.__table__.indexes
    }

    subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "head"],
        cwd=backend_dir,
        env=env,
        check=True,
        capture_output=True,
        text=True,
    )
    engine = create_engine(database_url)
    try:
        inspector = inspect(engine)
        assert {
            "usuarios",
            "fincas",
            "animales",
            "eventos_animales",
            "codigos_recuperacion_contrasena",
            "codigos_verificacion_correo",
            "registros_sanitarios",
            "registros_reproductivos",
            "registros_produccion",
            "insumos",
            "movimientos_insumos",
            "auditoria",
        } == set(inspector.get_table_names()) - {"alembic_version"}
        assert "module_permissions" in {
            column["name"] for column in inspector.get_columns("usuarios")
        }
        assert "ix_animals_finca_status" in {
            index["name"] for index in inspector.get_indexes("animales")
        }
        assert "ix_cattle_events_animal_fecha" in {
            index["name"] for index in inspector.get_indexes("eventos_animales")
        }
        with engine.connect() as connection:
            current_revision = connection.execute(
                text("SELECT version_num FROM alembic_version")
            ).scalar_one()
            assert current_revision == "d7a3e5c9b1f2"
            user_columns = {column["name"] for column in inspector.get_columns("usuarios")}
            assert {"auth_provider", "provider_subject"} <= user_columns
    finally:
        engine.dispose()

    subprocess.run(
        [sys.executable, "-m", "alembic", "downgrade", "base"],
        cwd=backend_dir,
        env=env,
        check=True,
        capture_output=True,
        text=True,
    )
    engine = create_engine(database_url)
    try:
        remaining = set(inspect(engine).get_table_names())
        assert not remaining & {"users", "usuarios", "fincas", "animales"}
    finally:
        engine.dispose()
