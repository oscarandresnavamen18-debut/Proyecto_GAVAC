import smtplib
import ssl
from email.message import EmailMessage

from app.config import settings


def send_password_reset_email(recipient: str, code: str) -> None:
    if not settings.smtp_is_configured:
        raise RuntimeError("SMTP password reset delivery is not configured")

    message = EmailMessage()
    message["Subject"] = "Código para recuperar tu contraseña"
    message["From"] = settings.smtp_from_email
    message["To"] = recipient
    message.set_content(
        f"Tu código para recuperar la contraseña es: {code}\n\n"
        "El código vence en 10 minutos y solo puede utilizarse una vez. "
        "Si no solicitaste este cambio, ignora este correo."
    )

    context = ssl.create_default_context()
    with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=10) as server:
        server.ehlo()
        server.starttls(context=context)
        server.ehlo()
        server.login(settings.smtp_username, settings.smtp_password.get_secret_value())
        server.send_message(message)


def send_alternate_email_verification(recipient: str, code: str) -> None:
    if not settings.smtp_is_configured:
        raise RuntimeError("Alternate email verification is not configured")

    message = EmailMessage()
    message["Subject"] = "Verifica tu correo alternativo de GAVAC"
    message["From"] = settings.smtp_from_email
    message["To"] = recipient
    message.set_content(
        f"Tu código para verificar el correo alternativo es: {code}\n\n"
        "El código vence en 10 minutos y solo puede utilizarse una vez. "
        "Si no solicitaste esta verificación, ignora este correo."
    )

    context = ssl.create_default_context()
    with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=10) as server:
        server.ehlo()
        server.starttls(context=context)
        server.ehlo()
        server.login(settings.smtp_username, settings.smtp_password.get_secret_value())
        server.send_message(message)
