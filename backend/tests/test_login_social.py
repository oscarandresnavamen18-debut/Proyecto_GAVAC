import pytest

from app.auth_providers import InvalidProviderToken, ProviderIdentity
from app.routers import social_auth


def _fake_identity(provider, id_token):
    if id_token != "token-de-prueba-valido-0123456789":
        raise InvalidProviderToken("Token inválido")
    return ProviderIdentity(provider, f"{provider}-subject-1", f"{provider}@test.com", "Persona de prueba")


@pytest.mark.parametrize("provider", ["google", "microsoft"])
def test_login_social_crea_usuario(client, monkeypatch, provider):
    monkeypatch.setattr(social_auth, "verify_provider_token", _fake_identity)
    response = client.post(f"/api/v1/auth/{provider}", json={"id_token": "token-de-prueba-valido-0123456789"})
    assert response.status_code == 200
    token = response.json()["access_token"]
    profile = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert profile.status_code == 200
    assert profile.json()["email"] == f"{provider}@test.com"


def test_segundo_login_social_reutiliza_usuario(client, monkeypatch):
    monkeypatch.setattr(social_auth, "verify_provider_token", _fake_identity)
    payload = {"id_token": "token-de-prueba-valido-0123456789"}
    first = client.post("/api/v1/auth/google", json=payload).json()["access_token"]
    second = client.post("/api/v1/auth/google", json=payload).json()["access_token"]
    headers = {"Authorization": f"Bearer {first}"}
    other_headers = {"Authorization": f"Bearer {second}"}
    first_user = client.get("/api/v1/auth/me", headers=headers).json()
    second_user = client.get("/api/v1/auth/me", headers=other_headers).json()
    assert first_user["id"] == second_user["id"]


def test_token_social_invalido_devuelve_401(client, monkeypatch):
    monkeypatch.setattr(social_auth, "verify_provider_token", _fake_identity)
    response = client.post("/api/v1/auth/google", json={"id_token": "token-de-prueba-invalido-0123456789"})
    assert response.status_code == 401


def test_no_vincula_automaticamente_correo_existente(client, monkeypatch):
    registration = client.post("/api/v1/auth/register", json={"nombre": "Cuenta local", "email": "google@test.com", "password": "clave-segura-123"})
    assert registration.status_code == 201
    monkeypatch.setattr(social_auth, "verify_provider_token", _fake_identity)
    response = client.post("/api/v1/auth/google", json={"id_token": "token-de-prueba-valido-0123456789"})
    assert response.status_code == 409


def test_usuario_social_no_inicia_sesion_con_contrasena(client, monkeypatch):
    monkeypatch.setattr(social_auth, "verify_provider_token", _fake_identity)
    client.post("/api/v1/auth/google", json={"id_token": "token-de-prueba-valido-0123456789"})
    response = client.post("/api/v1/auth/login", json={"email": "google@test.com", "password": "clave-segura-123"})
    assert response.status_code == 401
