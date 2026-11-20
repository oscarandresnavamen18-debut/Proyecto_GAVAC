
import httpx

from app.core.config import settings

VERIFY_URL = "https://www.google.com/recaptcha/api/siteverify"


class RecaptchaRejectedError(Exception):
    pass


class RecaptchaUnavailableError(Exception):
    pass


def verify_recaptcha(token: str) -> None:
    if not isinstance(token, str) or not token.strip():
        raise RecaptchaRejectedError("reCAPTCHA token is missing or invalid")

    if settings.environment.strip().lower() != "production":
        return

    secret = settings.recaptcha_secret_key.get_secret_value()
    if not secret:
        raise RecaptchaUnavailableError("RECAPTCHA_SECRET_KEY is not configured")

    allowed_hostnames = {
        hostname.strip().rstrip(".").lower()
        for hostname in settings.allowed_recaptcha_hostnames
        if isinstance(hostname, str) and hostname.strip()
    }

    if not allowed_hostnames:
        raise RecaptchaUnavailableError(
            "No allowed reCAPTCHA hostnames are configured"
        )

    try:
        response = httpx.post(
            VERIFY_URL,
            data={"secret": secret, "response": token.strip()},
            timeout=5.0,
        )
        response.raise_for_status()
        result = response.json()
    except (httpx.HTTPError, ValueError) as error:
        raise RecaptchaUnavailableError(
            "Google reCAPTCHA verification failed"
        ) from error

    if not isinstance(result, dict):
        raise RecaptchaUnavailableError(
            "Google returned an invalid reCAPTCHA response"
        )

    if result.get("success") is not True:
        raise RecaptchaRejectedError("Google rejected the reCAPTCHA token")

    hostname = result.get("hostname")

    if (
        not isinstance(hostname, str)
        or hostname.strip().rstrip(".").lower() not in allowed_hostnames
    ):
        raise RecaptchaRejectedError("reCAPTCHA hostname is not allowed")
