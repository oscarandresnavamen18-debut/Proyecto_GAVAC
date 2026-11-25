import smtplib
import ssl
from email.message import EmailMessage

from app.core.config import settings


def _send_email(recipient: str, subject: str, code: str, purpose: str) -> None:
    if not settings.smtp_is_configured:
        raise RuntimeError(f"{purpose} email delivery is not configured")

    message = EmailMessage()
    message["Subject"] = f"GAVAC — {subject}"
    message["From"] = settings.smtp_from_email
    message["To"] = recipient
    message.set_content(
        "========================================\n"
        "   GAVAC - Gestión Ganadera Inteligente\n"
        "========================================\n\n"
        "Hola,\n\n"
        f"Has solicitado un código de verificación ({purpose}) para tu cuenta en GAVAC.\n\n"
        f"Tu código de seguridad es: {code}\n\n"
        "Este código vence en 10 minutos y solo puede utilizarse una vez.\n"
        "Si no solicitaste esta operación, por favor ignora este mensaje.\n\n"
        "Atentamente,\n"
        "Equipo de Soporte y Operaciones GAVAC\n"
        "https://proyecto-gavac.vercel.app"
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
        "Recuperación de Contraseña",
        code,
        "Recuperación de contraseña",
    )


def send_alternate_email_verification(recipient: str, code: str) -> None:
    _send_email(
        recipient,
        "Verificación de Correo Alternativo",
        code,
        "Verificación de correo alternativo",
    )
