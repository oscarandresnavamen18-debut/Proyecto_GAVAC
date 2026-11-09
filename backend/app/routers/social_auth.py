from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.auth_providers import InvalidProviderToken, ProviderIdentity, verify_google, verify_microsoft
from app.db import get_db
from app.models import User
from app.schemas import TokenOut
from app.security import create_access_token

router = APIRouter(prefix="/api/v1/auth", tags=["Autenticación social"])


class SocialLoginIn(BaseModel):
    id_token: str = Field(min_length=20, max_length=8192)


def verify_provider_token(provider: str, id_token: str) -> ProviderIdentity:
    if provider == "google":
        return verify_google(id_token)
    if provider == "microsoft":
        return verify_microsoft(id_token)
    raise InvalidProviderToken("Proveedor no permitido")


def _login_or_create(db: Session, provider: str, id_token: str) -> User:
    try:
        identity = verify_provider_token(provider, id_token)
    except InvalidProviderToken as error:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token de identidad inválido") from error

    user = db.scalar(select(User).where(User.auth_provider == identity.provider, User.provider_subject == identity.subject))
    if user is not None:
        if not user.is_active:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "La cuenta está desactivada")
        return user

    if not identity.email:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "El proveedor no proporcionó un correo")
    email = identity.email.strip().lower()
    if db.scalar(select(User).where(User.email == email)) is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, "Ya existe una cuenta con ese correo. Inicia sesión con tu método original")

    user = User(
        full_name=(identity.name or email.split("@")[0])[:100],
        email=email,
        hashed_password=None,
        auth_provider=identity.provider,
        provider_subject=identity.subject,
    )
    db.add(user)
    try:
        db.commit()
        db.refresh(user)
    except IntegrityError as error:
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, "No se pudo crear la cuenta") from error
    return user


@router.post("/google", response_model=TokenOut)
def login_google(data: SocialLoginIn, db: Session = Depends(get_db)):
    user = _login_or_create(db, "google", data.id_token)
    return TokenOut(access_token=create_access_token(user.id, user.token_version))


@router.post("/microsoft", response_model=TokenOut)
def login_microsoft(data: SocialLoginIn, db: Session = Depends(get_db)):
    user = _login_or_create(db, "microsoft", data.id_token)
    return TokenOut(access_token=create_access_token(user.id, user.token_version))
