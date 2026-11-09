from pydantic import SecretStr

from app.config import settings
from app.mailer import send_password_reset_email


def test_reset_email_uses_authenticated_starttls(monkeypatch):
    calls = []

    class FakeSMTP:
        def __init__(self, host, port, timeout):
            calls.append(("connect", host, port, timeout))

        def __enter__(self):
            return self

        def __exit__(self, *_args):
            return False

        def ehlo(self):
            calls.append(("ehlo",))

        def starttls(self, context):
            calls.append(("starttls", context))

        def login(self, username, password):
            calls.append(("login", username, password))

        def send_message(self, message):
            calls.append(("send", message))

    monkeypatch.setattr(settings, "smtp_host", "smtp.test")
    monkeypatch.setattr(settings, "smtp_port", 587)
    monkeypatch.setattr(settings, "smtp_username", "mailer")
    monkeypatch.setattr(settings, "smtp_password", SecretStr("mail-secret"))
    monkeypatch.setattr(settings, "smtp_from_email", "noreply@test.invalid")
    monkeypatch.setattr("app.mailer.smtplib.SMTP", FakeSMTP)

    send_password_reset_email("user@test.invalid", "01234567")

    assert calls[0] == ("connect", "smtp.test", 587, 10)
    assert sum(call[0] == "starttls" for call in calls) == 1
    assert ("login", "mailer", "mail-secret") in calls
    message = next(call[1] for call in calls if call[0] == "send")
    assert message["To"] == "user@test.invalid"
    assert "01234567" in message.get_content()
