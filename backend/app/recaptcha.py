import httpx

from app.config import settings


VERIFY_URL = "https://www.google.com/recaptcha/api/siteverify"


class RecaptchaRejectedError(Exception):
    pass


class RecaptchaUnavailableError(Exception):
    pass


def verify_recaptcha(token: str) -> None:
    secret = settings.recaptcha_secret_key.get_secret_value()
    if not secret:
        raise RecaptchaUnavailableError("RECAPTCHA_SECRET_KEY is not configured")

    try:
        response = httpx.post(
            VERIFY_URL,
            data={"secret": secret, "response": token},
            timeout=5.0,
        )
        response.raise_for_status()
        result = response.json()
    except (httpx.HTTPError, ValueError) as error:
        raise RecaptchaUnavailableError("Google reCAPTCHA verification failed") from error

    if not isinstance(result, dict):
        raise RecaptchaUnavailableError("Google returned an invalid reCAPTCHA response")

    hostname = result.get("hostname")
    if (
        result.get("success") is not True
        or not isinstance(hostname, str)
        or hostname.strip(".").lower() not in settings.allowed_recaptcha_hostnames
    ):
        raise RecaptchaRejectedError("Google rejected the reCAPTCHA token")



