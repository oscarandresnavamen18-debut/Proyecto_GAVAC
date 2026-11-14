import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session
from app.config import settings
from app.db import get_db
from app.models import User, UserRole
from app.permissions import has_module

bearer = HTTPBearer(auto_error=False)


def current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
) -> User:
    unauthorized = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Autenticación requerida",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if credentials is None:
        raise unauthorized
    try:
        payload = jwt.decode(
            credentials.credentials,
            settings.jwt_secret_key.get_secret_value(),
            algorithms=["HS256"],
        )
        user_id = int(payload.get("sub", ""))
        token_version = payload.get("ver", 0)
    except (jwt.PyJWTError, ValueError, TypeError):
        raise unauthorized
    user = db.get(User, user_id)
    if user is None or type(token_version) is not int or token_version != user.token_version:
        raise unauthorized
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tu cuenta está desactivada. Contacta al administrador.",
        )
    return user


def require_admin(user: User = Depends(current_user)) -> User:
    if user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el administrador puede realizar esta acción",
        )
    return user


def require_module(module: str):
    """Dependencia que exige permiso sobre un módulo (el administrador siempre lo tiene)."""

    def dependency(user: User = Depends(current_user)) -> User:
        if not has_module(user, module):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"No tienes permiso para el módulo de {module}",
            )
        return user

    return dependency
