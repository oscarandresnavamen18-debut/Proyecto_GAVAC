import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db import Base, get_db
from app.main import app


@pytest.fixture()
def client_extra():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    Session = sessionmaker(bind=engine, autoflush=False, autocommit=False)

    def override_get_db():
        db = Session()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    yield TestClient(app)
    app.dependency_overrides.clear()


def _registrar(client, email):
    r = client.post(
        "/api/v1/auth/register",
        json={"nombre": "Usuario Test", "email": email, "password": "clave-segura-123"},
    )
    assert r.status_code == 201
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _crear_finca_y_animal(client, headers, identificador="A-001"):
    farm = client.post("/api/v1/farms", json={"nombre": "La Esperanza"}, headers=headers).json()
    animal = client.post(
        "/api/v1/animals",
        json={
            "farm_id": farm["id"],
            "tag_id": identificador,
            "gender": "HEMBRA",
            "birth_date": "2023-01-01",
            "breed": "Holstein",
            "current_weight": 400.0,
            "status": "ACTIVO",
        },
        headers=headers,
    ).json()
    return farm, animal


def test_summary_cuenta_animales_y_eventos(client_extra):
    h = _registrar(client_extra, "a@test.com")
    farm, animal = _crear_finca_y_animal(client_extra, h)
    client_extra.post(
        f"/api/v1/animals/{animal['id']}/events",
        json={
            "event_type": "VACUNACION",
            "event_date": "2026-01-10",
            "description": "Vacuna aftosa",
        },
        headers=h,
    )
    r = client_extra.get(f"/api/v1/farms/{farm['id']}/summary", headers=h)
    assert r.status_code == 200
    assert r.json() == {
        "farm_id": farm["id"],
        "total_animales": 1,
        "por_estado": {"ACTIVO": 1},
        "total_eventos": 1,
    }


def test_eliminar_animal(client_extra):
    h = _registrar(client_extra, "a@test.com")
    _, animal = _crear_finca_y_animal(client_extra, h)
    assert client_extra.delete(f"/api/v1/animals/{animal['id']}", headers=h).status_code == 204
    assert client_extra.get(f"/api/v1/animals/{animal['id']}", headers=h).status_code == 404


def test_otro_usuario_no_puede_eliminar(client_extra):
    h1 = _registrar(client_extra, "a@test.com")
    h2 = _registrar(client_extra, "b@test.com")
    _, animal = _crear_finca_y_animal(client_extra, h1)
    client_extra.post("/api/v1/farms", json={"nombre": "Otra finca"}, headers=h2)
    r = client_extra.delete(f"/api/v1/animals/{animal['id']}", headers=h2)
    assert r.status_code == 403
