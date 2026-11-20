
import hashlib
import hmac
from datetime import datetime, timedelta, timezone

import jwt
from pwdlib import PasswordHash
from app.core.config import settings

password_hash = PasswordHash.recommended()
ALGORITHM = "HS256"


def _get_jwt_secret() -> str:
    secret = settings.jwt_secret_key.get_secret_value()
    if not secret:
        raise RuntimeError("JWT_SECRET_KEY no está configurada.")
    return secret


def hash_password(password: str) -> str:
    return password_hash.hash(password)


def verify_password(password: str, hashed: str) -> bool:
    return password_hash.verify(password, hashed)


def create_access_token(user_id: int, token_version: int = 0) -> str:
    if user_id <= 0:
        raise ValueError("El identificador del usuario no es válido.")
    expires = datetime.now(timezone.utc) + timedelta(
        minutes=settings.jwt_expire_minutes
    )
    return jwt.encode(
        {"sub": str(user_id), "ver": token_version, "exp": expires},
        _get_jwt_secret(),
        algorithm=ALGORITHM,
    )


def hash_password_reset_code(user_id: int, code: str) -> str:
    return hash_one_time_code("password-reset", user_id, code)


def hash_one_time_code(purpose: str, user_id: int, code: str) -> str:
    if not purpose or not code or user_id <= 0:
        raise ValueError("Los datos del código de un solo uso no son válidos.")
    payload = f"{purpose}:{user_id}:{code}".encode()
    secret = _get_jwt_secret().encode()
    return hmac.new(secret, payload, hashlib.sha256).hexdigest()
