import httpx
import pytest
from pydantic import SecretStr

from app.config import settings
from app.recaptcha import (
    RecaptchaRejectedError,
    RecaptchaUnavailableError,
    verify_recaptcha,
)


def test_recaptcha_fails_closed_without_server_secret(monkeypatch):
    monkeypatch.setattr(settings, "recaptcha_secret_key", SecretStr(""))

    with pytest.raises(RecaptchaUnavailableError):
        verify_recaptcha("token")


def test_recaptcha_rejects_unapproved_hostname(monkeypatch):
    class Response:
        def raise_for_status(self):
            pass

        def json(self):
            return {"success": True, "hostname": "attacker.example"}

    monkeypatch.setattr(settings, "recaptcha_secret_key", SecretStr("server-secret"))
    monkeypatch.setattr("app.recaptcha.httpx.post", lambda *args, **kwargs: Response())

    with pytest.raises(RecaptchaRejectedError):
        verify_recaptcha("token")


def test_recaptcha_reports_google_transport_failure(monkeypatch):
    monkeypatch.setattr(settings, "recaptcha_secret_key", SecretStr("server-secret"))

    def fail_request(*args, **kwargs):
        raise httpx.TimeoutException("timeout")

    monkeypatch.setattr("app.recaptcha.httpx.post", fail_request)
    with pytest.raises(RecaptchaUnavailableError):
        verify_recaptcha("token")
