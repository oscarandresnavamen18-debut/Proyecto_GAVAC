
import os
from dataclasses import dataclass

import jwt
from jwt import PyJWKClient

GOOGLE_JWKS_URL = "https://www.googleapis.com/oauth2/v3/certs"
MICROSOFT_JWKS_URL = "https://login.microsoftonline.com/common/discovery/v2.0/keys"
GOOGLE_ISSUERS = ("https://accounts.google.com", "accounts.google.com")
REQUIRED_CLAIMS = ["exp", "iat", "iss", "aud", "sub"]

_google_jwks = PyJWKClient(GOOGLE_JWKS_URL, cache_keys=True)
_microsoft_jwks = PyJWKClient(MICROSOFT_JWKS_URL, cache_keys=True)


class InvalidProviderToken(Exception):
    pass


@dataclass
class ProviderIdentity:
    provider: str
    subject: str
    email: str | None
    name: str | None


def _client_ids(variable: str) -> list[str]:
    return [
        value.strip()
        for value in os.environ.get(variable, "").split(",")
        if value.strip()
    ]


def _validate_identity(payload: dict) -> tuple[str, str | None, str | None]:
    subject = payload.get("sub")
    if not isinstance(subject, str) or not subject.strip():
        raise InvalidProviderToken("Identificador de usuario inválido")

    email = payload.get("email")
    if not isinstance(email, str) or not email.strip():
        email = None
    else:
        email = email.strip().lower()

    name = payload.get("name")
    if not isinstance(name, str) or not name.strip():
        name = None
    else:
        name = name.strip()

    return subject, email, name


def verify_google(id_token: str) -> ProviderIdentity:
    audiences = _client_ids("GOOGLE_CLIENT_IDS")
    if not audiences:
        raise InvalidProviderToken("Google no está configurado")

    try:
        key = _google_jwks.get_signing_key_from_jwt(id_token).key
        payload = jwt.decode(
            id_token,
            key,
            algorithms=["RS256"],
            audience=audiences,
            options={"require": REQUIRED_CLAIMS},
        )
    except (jwt.PyJWTError, OSError) as error:
        raise InvalidProviderToken("Token de Google inválido") from error

    if (
        payload.get("iss") not in GOOGLE_ISSUERS
        or payload.get("email_verified") is not True
    ):
        raise InvalidProviderToken("Identidad de Google no verificada")

    subject, email, name = _validate_identity(payload)
    if email is None:
        raise InvalidProviderToken("Google no proporcionó un correo verificado")

    return ProviderIdentity("google", subject, email, name)


def verify_microsoft(id_token: str) -> ProviderIdentity:
    audience = os.environ.get("MICROSOFT_CLIENT_ID", "").strip()
    if not audience:
        raise InvalidProviderToken("Microsoft no está configurado")

    try:
        key = _microsoft_jwks.get_signing_key_from_jwt(id_token).key
        payload = jwt.decode(
            id_token,
            key,
            algorithms=["RS256"],
            audience=audience,
            options={"require": REQUIRED_CLAIMS},
        )
    except (jwt.PyJWTError, OSError) as error:
        raise InvalidProviderToken("Token de Microsoft inválido") from error

    tenant = payload.get("tid")
    issuer = payload.get("iss")
    if (
        not isinstance(tenant, str)
        or not tenant.strip()
        or issuer != f"https://login.microsoftonline.com/{tenant}/v2.0"
    ):
        raise InvalidProviderToken("Emisor de Microsoft inválido")

    subject, email, name = _validate_identity(payload)
    if email is None:
        email = payload.get("preferred_username")
        if not isinstance(email, str) or not email.strip():
            raise InvalidProviderToken("Microsoft no proporcionó un correo")
        email = email.strip().lower()

    return ProviderIdentity("microsoft", subject, email, name)
