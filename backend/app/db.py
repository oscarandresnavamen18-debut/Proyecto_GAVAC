from sqlalchemy import create_engine, make_url
from sqlalchemy.orm import DeclarativeBase, sessionmaker
from sqlalchemy.pool import StaticPool
from app.config import settings

database_url = make_url(settings.database_url)
environment = settings.environment.lower()

if database_url.get_backend_name() == "sqlite":
    if environment != "test":
        raise RuntimeError("La aplicación requiere PostgreSQL fuera del entorno de pruebas.")
    engine = create_engine(
        database_url,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
        echo=False,
    )
elif database_url.get_backend_name() == "postgresql":
    database_url = database_url.set(drivername="postgresql+psycopg")
    engine = create_engine(database_url, echo=False, pool_pre_ping=True)
else:
    raise RuntimeError("Motor de base de datos no permitido. Revisa DATABASE_URL.")

class Base(DeclarativeBase):
    pass

SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
