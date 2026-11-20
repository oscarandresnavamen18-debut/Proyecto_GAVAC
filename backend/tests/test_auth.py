import pytest

from app.routers import auth as auth_router


def test_register_and_login(client):
    reg_payload = {
        "nombre": "Jorge Botero",
        "email": "jorge@ganadera.com",
        "password": "Password123Secure!",
    }
    reg_res = client.post("/api/v1/auth/register", json=reg_payload)
    assert reg_res.status_code == 201
    assert "access_token" in reg_res.json()
    token = reg_res.json()["access_token"]

    dup_res = client.post("/api/v1/auth/register", json=reg_payload)
    assert dup_res.status_code == 409

    login_res = client.post(
        "/api/v1/auth/login",
        json={
            "email": "jorge@ganadera.com",
            "password": "Password123Secure!",
            "captcha_token": "test-token",
        },
    )
    assert login_res.status_code == 200
    assert "access_token" in login_res.json()

    me_res = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert me_res.status_code == 200
    assert me_res.json()["email"] == "jorge@ganadera.com"


def test_native_login_does_not_require_recaptcha(client, monkeypatch):
    def fail_if_recaptcha_is_checked(_token):
        pytest.fail("Native login must not require reCAPTCHA")

    monkeypatch.setattr(auth_router, "verify_recaptcha", fail_if_recaptcha_is_checked)
    registration = client.post(
        "/api/v1/auth/register",
        json={
            "nombre": "Jorge Botero",
            "email": "jorge@ganadera.com",
            "password": "Password123Secure!",
        },
    )
    assert registration.status_code == 201

    login = client.post(
        "/api/v1/auth/login",
        json={"email": "jorge@ganadera.com", "password": "Password123Secure!"},
    )

    assert login.status_code == 200


def _register_admin(client):
    response = client.post(
        "/api/v1/auth/register",
        json={
            "nombre": "Admin Finca",
            "email": "admin@ganadera.com",
            "password": "Password123Secure!",
        },
    )
    assert response.status_code == 201
    assert response.json()["role"] == "ADMIN"


def test_login_with_matching_role(client):
    _register_admin(client)
    response = client.post(
        "/api/v1/auth/login",
        json={
            "email": "admin@ganadera.com",
            "password": "Password123Secure!",
            "role": "ADMIN",
        },
    )
    assert response.status_code == 200
    assert response.json()["role"] == "ADMIN"


@pytest.mark.parametrize("role", ["VETERINARIO", "MAYORDOMO"])
def test_login_rejects_mismatched_role(client, role):
    _register_admin(client)
    response = client.post(
        "/api/v1/auth/login",
        json={
            "email": "admin@ganadera.com",
            "password": "Password123Secure!",
            "role": role,
        },
    )
    assert response.status_code == 403


def test_login_role_check_does_not_bypass_password(client):
    _register_admin(client)
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@ganadera.com", "password": "incorrecta", "role": "VETERINARIO"},
    )
    assert response.status_code == 401


def test_login_rejects_unknown_role(client):
    _register_admin(client)
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@ganadera.com", "password": "Password123Secure!", "role": "DUEÑO"},
    )
    assert response.status_code == 422
