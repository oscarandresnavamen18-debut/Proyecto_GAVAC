
import smtplib
import ssl
from email.message import EmailMessage

from app.core.config import settings


def _send_email(recipient: str, subject: str, code: str, purpose: str) -> None:
    if not settings.smtp_is_configured:
        raise RuntimeError(f"{purpose} email delivery is not configured")

    message = EmailMessage()
    message["Subject"] = subject
    message["From"] = settings.smtp_from_email
    message["To"] = recipient
    message.set_content(
        f"Tu código es: {code}\n\n"
        "El código vence en 10 minutos y solo puede utilizarse una vez. "
        "Si no solicitaste esta operación, ignora este correo."
    )

    context = ssl.create_default_context()

    with smtplib.SMTP(
        settings.smtp_host,
        settings.smtp_port,
        timeout=10,
    ) as server:
        server.ehlo()
        server.starttls(context=context)
        server.ehlo()
        server.login(
            settings.smtp_username,
            settings.smtp_password.get_secret_value(),
        )
        server.send_message(message)


def send_password_reset_email(recipient: str, code: str) -> None:
    _send_email(
        recipient,
        "Código para recuperar tu contraseña",
        code,
        "Password reset",
    )


def send_alternate_email_verification(recipient: str, code: str) -> None:
    _send_email(
        recipient,
        "Verifica tu correo alternativo de GAVAC",
        code,
        "Alternate email verification",
    )
