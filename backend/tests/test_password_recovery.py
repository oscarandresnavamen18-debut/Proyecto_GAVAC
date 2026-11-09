from datetime import datetime, timedelta, timezone

import jwt
from sqlalchemy import select

from app.config import settings
from app.models import PasswordResetCode, User
from app.security import create_access_token


EMAIL = "recover@ganadera.com"
OLD_PASSWORD = "Password123Secure!"
NEW_PASSWORD = "NewPassword456Secure!"


def test_access_token_expires_after_configured_session_duration():
    token = create_access_token(1)
    payload = jwt.decode(
        token,
        settings.jwt_secret_key.get_secret_value(),
        algorithms=["HS256"],
    )
    seconds_until_expiration = payload["exp"] - datetime.now(timezone.utc).timestamp()

    assert 59 * 60 <= seconds_until_expiration <= 60 * 60


def register_user(client):
    response = client.post(
        "/api/v1/auth/register",
        json={"nombre": "Usuario Recuperación", "email": EMAIL, "password": OLD_PASSWORD},
    )
    assert response.status_code == 201
    return response.json()["access_token"]


def request_code(client, monkeypatch):
    sent = []
    monkeypatch.setattr(
        "app.main.send_password_reset_email",
        lambda recipient, code: sent.append((recipient, code)),
    )
    response = client.post("/api/v1/auth/password-reset/request", json={"email": EMAIL})
    assert response.status_code == 202
    assert response.json() == {
        "detail": "Si el correo está registrado, recibirás instrucciones para recuperar tu contraseña."
    }
    assert len(sent) == 1
    assert sent[0][0] == EMAIL
    assert len(sent[0][1]) == 8 and sent[0][1].isdigit()
    return sent[0][1]


def test_password_reset_changes_password_and_revokes_existing_tokens(client, db_session, monkeypatch):
    old_token = register_user(client)
    code = request_code(client, monkeypatch)

    reset = db_session.get(PasswordResetCode, 1)
    assert reset is not None
    assert code not in reset.code_hash

    response = client.post(
        "/api/v1/auth/password-reset/confirm",
        json={"email": EMAIL, "code": code, "new_password": NEW_PASSWORD},
    )
    assert response.status_code == 204
    assert db_session.get(PasswordResetCode, 1) is None

    assert client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {old_token}"},
    ).status_code == 401
    assert client.post(
        "/api/v1/auth/login",
        json={
            "email": EMAIL,
            "password": OLD_PASSWORD,
            "captcha_token": "test-token",
        },
    ).status_code == 401
    assert client.post(
        "/api/v1/auth/login",
        json={
            "email": EMAIL,
            "password": NEW_PASSWORD,
            "captcha_token": "test-token",
        },
    ).status_code == 200
    assert client.post(
        "/api/v1/auth/password-reset/confirm",
        json={"email": EMAIL, "code": code, "new_password": OLD_PASSWORD},
    ).status_code == 400


def test_verified_alternate_email_can_receive_and_confirm_password_reset(client, db_session, monkeypatch):
    register_user(client)
    user = db_session.scalar(select(User).where(User.email == EMAIL))
    assert user is not None
    user.alternate_email = "respaldo@ganadera.com"
    user.alternate_email_verified_at = datetime.now(timezone.utc)
    db_session.commit()

    sent = []
    monkeypatch.setattr(
        "app.main.send_password_reset_email",
        lambda recipient, code: sent.append((recipient, code)),
    )
    response = client.post(
        "/api/v1/auth/password-reset/request",
        json={"email": "respaldo@ganadera.com"},
    )
    assert response.status_code == 202
    assert sent[0][0] == "respaldo@ganadera.com"

    confirmed = client.post(
        "/api/v1/auth/password-reset/confirm",
        json={
            "email": "respaldo@ganadera.com",
            "code": sent[0][1],
            "new_password": NEW_PASSWORD,
        },
    )
    assert confirmed.status_code == 204

    login = client.post(
        "/api/v1/auth/login",
        json={
            "email": "respaldo@ganadera.com",
            "password": NEW_PASSWORD,
            "captcha_token": "test-token",
        },
    )
    assert login.status_code == 200


def test_unverified_alternate_email_cannot_request_password_reset(client, db_session, monkeypatch):
    register_user(client)
    user = db_session.scalar(select(User).where(User.email == EMAIL))
    assert user is not None
    user.alternate_email = "pendiente@ganadera.com"
    db_session.commit()

    sent = []
    monkeypatch.setattr(
        "app.main.send_password_reset_email",
        lambda recipient, code: sent.append((recipient, code)),
    )
    response = client.post(
        "/api/v1/auth/password-reset/request",
        json={"email": "pendiente@ganadera.com"},
    )

    assert response.status_code == 202
    assert sent == []


def test_authenticated_user_must_verify_alternate_email_before_use(client, monkeypatch):
    token = register_user(client)
    headers = {"Authorization": f"Bearer {token}"}
    sent = []
    monkeypatch.setattr(
        "app.main.send_alternate_email_verification",
        lambda recipient, code: sent.append((recipient, code)),
    )

    requested = client.post(
        "/api/v1/auth/alternate-email/request",
        json={"email": "respaldo@ganadera.com"},
        headers=headers,
    )
    assert requested.status_code == 202
    assert sent[0][0] == "respaldo@ganadera.com"

    status_response = client.get("/api/v1/auth/alternate-email", headers=headers)
    assert status_response.json() == {
        "email": None,
        "verified": False,
        "pending_email": "respaldo@ganadera.com",
    }
    confirmed = client.post(
        "/api/v1/auth/alternate-email/confirm",
        json={"code": sent[0][1]},
        headers=headers,
    )
    assert confirmed.status_code == 200
    assert confirmed.json()["verified"] is True

    alternate_login = client.post(
        "/api/v1/auth/login",
        json={
            "email": "respaldo@ganadera.com",
            "password": OLD_PASSWORD,
            "captcha_token": "test-token",
        },
    )
    assert alternate_login.status_code == 200


def test_alternate_email_verification_limits_invalid_codes(client, monkeypatch):
    token = register_user(client)
    headers = {"Authorization": f"Bearer {token}"}
    monkeypatch.setattr("app.main.send_alternate_email_verification", lambda *_: None)
    client.post(
        "/api/v1/auth/alternate-email/request",
        json={"email": "respaldo@ganadera.com"},
        headers=headers,
    )

    for _ in range(5):
        response = client.post(
            "/api/v1/auth/alternate-email/confirm",
            json={"code": "00000000"},
            headers=headers,
        )
    assert response.status_code == 400
    assert client.get("/api/v1/auth/alternate-email", headers=headers).json()["verified"] is False


def test_password_reset_request_does_not_disclose_unknown_accounts(client, monkeypatch):
    register_user(client)
    sent = []
    monkeypatch.setattr(
        "app.main.send_password_reset_email",
        lambda recipient, code: sent.append((recipient, code)),
    )

    known = client.post("/api/v1/auth/password-reset/request", json={"email": EMAIL})
    unknown = client.post(
        "/api/v1/auth/password-reset/request",
        json={"email": "unknown@ganadera.com"},
    )

    assert known.status_code == unknown.status_code == 202
    assert known.json() == unknown.json()
    assert len(sent) == 1


def test_password_reset_request_is_throttled_per_account(client, monkeypatch):
    register_user(client)
    sent = []
    monkeypatch.setattr(
        "app.main.send_password_reset_email",
        lambda recipient, code: sent.append((recipient, code)),
    )

    first = client.post("/api/v1/auth/password-reset/request", json={"email": EMAIL})
    assert first.status_code == 202
    assert len(sent) == 1

    second = client.post("/api/v1/auth/password-reset/request", json={"email": EMAIL})

    assert second.status_code == 202
    assert len(sent) == 1
    assert client.post(
        "/api/v1/auth/password-reset/confirm",
        json={"email": EMAIL, "code": sent[0][1], "new_password": NEW_PASSWORD},
    ).status_code == 204


def test_password_reset_expires_and_locks_after_five_wrong_attempts(client, db_session, monkeypatch):
    register_user(client)
    code = request_code(client, monkeypatch)
    wrong_code = "00000000" if code != "00000000" else "00000001"

    for _ in range(5):
        response = client.post(
            "/api/v1/auth/password-reset/confirm",
            json={"email": EMAIL, "code": wrong_code, "new_password": NEW_PASSWORD},
        )
        assert response.status_code == 400

    assert db_session.get(PasswordResetCode, 1) is None
    assert client.post(
        "/api/v1/auth/password-reset/confirm",
        json={"email": EMAIL, "code": code, "new_password": NEW_PASSWORD},
    ).status_code == 400


def test_expired_password_reset_code_is_rejected(client, db_session, monkeypatch):
    register_user(client)
    code = request_code(client, monkeypatch)
    reset = db_session.get(PasswordResetCode, 1)
    assert reset is not None
    reset.expires_at = datetime.now(timezone.utc) - timedelta(seconds=1)
    db_session.commit()

    response = client.post(
        "/api/v1/auth/password-reset/confirm",
        json={"email": EMAIL, "code": code, "new_password": NEW_PASSWORD},
    )

    assert response.status_code == 400
    assert db_session.get(PasswordResetCode, 1) is None


def test_email_delivery_failure_is_logged_and_reset_request_remains_generic(
    client, db_session, monkeypatch, caplog
):
    register_user(client)

    def fail_delivery(_recipient, _code):
        raise RuntimeError("SMTP unavailable")

    monkeypatch.setattr("app.main.send_password_reset_email", fail_delivery)
    response = client.post("/api/v1/auth/password-reset/request", json={"email": EMAIL})

    assert response.status_code == 202
    assert "Password reset email delivery failed" in caplog.text
    user = db_session.scalar(select(User).where(User.email == EMAIL))
    assert user is not None
    assert db_session.get(PasswordResetCode, user.id) is not None
