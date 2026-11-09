from datetime import datetime, timedelta, timezone
import hashlib
import hmac

import jwt
from pwdlib import PasswordHash
from app.config import settings

password_hash = PasswordHash.recommended()
ALGORITHM = "HS256"


def hash_password(password: str) -> str:
    return password_hash.hash(password)


def verify_password(password: str, hashed: str) -> bool:
    return password_hash.verify(password, hashed)


def create_access_token(user_id: int, token_version: int = 0) -> str:
    expires = datetime.now(timezone.utc) + timedelta(minutes=settings.jwt_expire_minutes)
    return jwt.encode(
        {"sub": str(user_id), "ver": token_version, "exp": expires},
        settings.jwt_secret_key.get_secret_value(),
        algorithm=ALGORITHM,
    )


def hash_password_reset_code(user_id: int, code: str) -> str:
    return hash_one_time_code("password-reset", user_id, code)


def hash_one_time_code(purpose: str, user_id: int, code: str) -> str:
    payload = f"{purpose}:{user_id}:{code}".encode()
    secret = settings.jwt_secret_key.get_secret_value().encode()
    return hmac.new(secret, payload, hashlib.sha256).hexdigest()
