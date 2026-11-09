
import os
os.environ["DATABASE_URL"] = "sqlite:///:memory:"
os.environ["ENVIRONMENT"] = "test"
os.environ.setdefault("JWT_SECRET_KEY", "test-only-secret-key-with-at-least-32-characters")

import pytest
from app import main as main_module
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.config import settings
if not settings.database_url.startswith("sqlite:"):
    raise RuntimeError("Backend tests must never use a remote database")
settings.database_url = "sqlite:///:memory:"

import app.db as db_module
from app.db import Base, get_db

test_engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
db_module.engine = test_engine
db_module.SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=test_engine,
)

from app.main import app


@pytest.fixture(autouse=True)
def bypass_external_recaptcha_service(monkeypatch):
    monkeypatch.setattr(main_module, "verify_recaptcha", lambda _token: None)


@pytest.fixture(scope="function")
def db_session():
    Base.metadata.create_all(bind=test_engine)
    session = db_module.SessionLocal()
    try:
        yield session
    finally:
        session.close()
        with test_engine.connect() as connection:
            connection.exec_driver_sql("PRAGMA foreign_keys=OFF")
            connection.commit()
            try:
                for table in reversed(list(Base.metadata.tables.values())):
                    table.drop(connection, checkfirst=True)
                connection.commit()
            finally:
                connection.exec_driver_sql("PRAGMA foreign_keys=ON")
                connection.commit()


@pytest.fixture(scope="function")
def client(db_session):
    def _get_test_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = _get_test_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
