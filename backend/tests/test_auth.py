import pytest

from app import main as main_module


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

    monkeypatch.setattr(main_module, "verify_recaptcha", fail_if_recaptcha_is_checked)
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
