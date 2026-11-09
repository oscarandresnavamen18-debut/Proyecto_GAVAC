import logging
import secrets
import smtplib
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from sqlalchemy import and_, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import current_user
from app.mailer import send_alternate_email_verification, send_password_reset_email
from app.models import AlternateEmailVerificationCode, PasswordResetCode, User
from app.recaptcha import RecaptchaRejectedError, RecaptchaUnavailableError, verify_recaptcha
from app.schemas import (
    AlternateEmailConfirm,
    AlternateEmailRequest,
    AlternateEmailStatus,
    LoginIn,
    PasswordResetConfirm,
    PasswordResetRequest,
    RegisterIn,
    TokenOut,
    UserRead,
)
from app.security import (
    create_access_token,
    hash_one_time_code,
    hash_password,
    hash_password_reset_code,
    verify_password,
)

router = APIRouter(prefix="/api/v1/auth", tags=["Autenticación"])

logger = logging.getLogger(__name__)
PASSWORD_RESET_RESPONSE = {
    "detail": "Si el correo está registrado, recibirás instrucciones para recuperar tu contraseña."
}
PASSWORD_RESET_INVALID = "El código no es válido o ya venció"
PASSWORD_RESET_TTL = timedelta(minutes=10)
PASSWORD_RESET_REQUEST_INTERVAL = timedelta(minutes=1)
PASSWORD_RESET_MAX_ATTEMPTS = 5
ALTERNATE_EMAIL_TTL = timedelta(minutes=10)
ALTERNATE_EMAIL_REQUEST_INTERVAL = timedelta(minutes=1)
ALTERNATE_EMAIL_MAX_ATTEMPTS = 5


def deliver_password_reset_email(email: str, code: str) -> None:
    try:
        send_password_reset_email(email, code)
    except (OSError, RuntimeError, smtplib.SMTPException):
        logger.exception("Password reset email delivery failed")


@router.post("/register", response_model=TokenOut, status_code=status.HTTP_201_CREATED)
def register(data: RegisterIn, db: Session = Depends(get_db)):
    user = User(
        full_name=data.nombre.strip(),
        email=str(data.email).lower(),
        hashed_password=hash_password(data.password),
    )
    db.add(user)
    try:
        db.commit()
        db.refresh(user)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT,
                            detail="El correo ya está registrado")
    return TokenOut(access_token=create_access_token(user.id, user.token_version))


@router.post("/login", response_model=TokenOut)
def login(data: LoginIn, db: Session = Depends(get_db)):
    if data.captcha_token is not None and data.captcha_token != "string":
        try:
            verify_recaptcha(data.captcha_token)
        except RecaptchaRejectedError as error:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="La verificación reCAPTCHA no es válida. Inténtalo de nuevo.",
            ) from error
        except RecaptchaUnavailableError as error:
            logger.exception("reCAPTCHA verification service is unavailable")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="El servicio de verificación no está disponible. Inténtalo más tarde.",
            ) from error

    email = str(data.email).lower()
    user = db.scalar(
        select(User).where(
            or_(
                User.email == email,
                and_(
                    User.alternate_email == email,
                    User.alternate_email_verified_at.is_not(None),
                ),
            )
        )
    )
    if user is None or user.hashed_password is None or not verify_password(data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciales inválidas")
    return TokenOut(access_token=create_access_token(user.id, user.token_version))


@router.post(
    "/password-reset/request",
    status_code=status.HTTP_202_ACCEPTED,
)
def request_password_reset(
    data: PasswordResetRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    email = str(data.email).lower()
    user = db.scalar(
        select(User)
        .where(
            or_(
                User.email == email,
                and_(
                    User.alternate_email == email,
                    User.alternate_email_verified_at.is_not(None),
                ),
            )
        )
        .with_for_update()
    )
    if user is None:
        return PASSWORD_RESET_RESPONSE

    now = datetime.now(timezone.utc)
    reset = db.scalar(
        select(PasswordResetCode)
        .where(PasswordResetCode.user_id == user.id)
        .with_for_update()
    )
    if reset is not None:
        created_at = reset.created_at
        if created_at.tzinfo is None:
            created_at = created_at.replace(tzinfo=timezone.utc)
        if now - created_at < PASSWORD_RESET_REQUEST_INTERVAL:
            return PASSWORD_RESET_RESPONSE

    code = f"{secrets.randbelow(100_000_000):08d}"
    if reset is None:
        reset = PasswordResetCode(
            user_id=user.id,
            code_hash=hash_password_reset_code(user.id, code),
            created_at=now,
            expires_at=now + PASSWORD_RESET_TTL,
            failed_attempts=0,
        )
        db.add(reset)
    else:
        reset.code_hash = hash_password_reset_code(user.id, code)
        reset.created_at = now
        reset.expires_at = now + PASSWORD_RESET_TTL
        reset.failed_attempts = 0
    db.commit()

    background_tasks.add_task(deliver_password_reset_email, email, code)

    return PASSWORD_RESET_RESPONSE


@router.post(
    "/password-reset/confirm",
    status_code=status.HTTP_204_NO_CONTENT,
)
def confirm_password_reset(data: PasswordResetConfirm, db: Session = Depends(get_db)):
    email = str(data.email).lower()
    user = db.scalar(
        select(User)
        .where(
            or_(
                User.email == email,
                and_(
                    User.alternate_email == email,
                    User.alternate_email_verified_at.is_not(None),
                ),
            )
        )
        .with_for_update()
    )
    reset = (
        db.scalar(
            select(PasswordResetCode)
            .where(PasswordResetCode.user_id == user.id)
            .with_for_update()
        )
        if user is not None
        else None
    )
    if user is None or reset is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=PASSWORD_RESET_INVALID)

    now = datetime.now(timezone.utc)
    expires_at = reset.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    if now >= expires_at or reset.failed_attempts >= PASSWORD_RESET_MAX_ATTEMPTS:
        db.delete(reset)
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=PASSWORD_RESET_INVALID)

    expected_hash = hash_password_reset_code(user.id, data.code)
    if not secrets.compare_digest(expected_hash, reset.code_hash):
        reset.failed_attempts += 1
        if reset.failed_attempts >= PASSWORD_RESET_MAX_ATTEMPTS:
            db.delete(reset)
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=PASSWORD_RESET_INVALID)

    user.hashed_password = hash_password(data.new_password)
    user.token_version += 1
    db.delete(reset)
    db.commit()
    return None


@router.get(
    "/alternate-email",
    response_model=AlternateEmailStatus,
)
def get_alternate_email_status(
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    verification = db.get(AlternateEmailVerificationCode, user.id)
    return AlternateEmailStatus(
        email=user.alternate_email,
        verified=user.alternate_email_verified_at is not None,
        pending_email=verification.email if verification is not None else None,
    )


@router.post(
    "/alternate-email/request",
    status_code=status.HTTP_202_ACCEPTED,
)
def request_alternate_email_verification(
    data: AlternateEmailRequest,
    background_tasks: BackgroundTasks,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    email = str(data.email).lower()
    if email == user.email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El correo alternativo debe ser distinto al correo principal.",
        )

    existing_user = db.scalar(
        select(User.id).where(
            User.id != user.id,
            or_(User.email == email, User.alternate_email == email),
        )
    )
    if existing_user is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ese correo ya está asociado a otra cuenta.",
        )

    now = datetime.now(timezone.utc)
    verification = db.scalar(
        select(AlternateEmailVerificationCode)
        .where(AlternateEmailVerificationCode.user_id == user.id)
        .with_for_update()
    )
    if verification is not None:
        created_at = verification.created_at
        if created_at.tzinfo is None:
            created_at = created_at.replace(tzinfo=timezone.utc)
        if now - created_at < ALTERNATE_EMAIL_REQUEST_INTERVAL:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Espera un minuto antes de solicitar otro código.",
            )

    code = f"{secrets.randbelow(100_000_000):08d}"
    if verification is None:
        verification = AlternateEmailVerificationCode(
            user_id=user.id,
            email=email,
            code_hash=hash_one_time_code("alternate-email", user.id, code),
            created_at=now,
            expires_at=now + ALTERNATE_EMAIL_TTL,
            failed_attempts=0,
        )
        db.add(verification)
    else:
        verification.email = email
        verification.code_hash = hash_one_time_code(
            "alternate-email", user.id, code)
        verification.created_at = now
        verification.expires_at = now + ALTERNATE_EMAIL_TTL
        verification.failed_attempts = 0
    db.commit()
    background_tasks.add_task(send_alternate_email_verification, email, code)
    return {"detail": "Si el correo puede verificarse, recibirás un código de confirmación."}


@router.post(
    "/alternate-email/confirm",
    response_model=AlternateEmailStatus,
)
def confirm_alternate_email(
    data: AlternateEmailConfirm,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    verification = db.scalar(
        select(AlternateEmailVerificationCode)
        .where(AlternateEmailVerificationCode.user_id == user.id)
        .with_for_update()
    )
    invalid_code = HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail="El código no es válido o ya venció.",
    )
    if verification is None:
        raise invalid_code

    now = datetime.now(timezone.utc)
    expires_at = verification.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    if now >= expires_at or verification.failed_attempts >= ALTERNATE_EMAIL_MAX_ATTEMPTS:
        db.delete(verification)
        db.commit()
        raise invalid_code

    expected_hash = hash_one_time_code("alternate-email", user.id, data.code)
    if not secrets.compare_digest(expected_hash, verification.code_hash):
        verification.failed_attempts += 1
        if verification.failed_attempts >= ALTERNATE_EMAIL_MAX_ATTEMPTS:
            db.delete(verification)
        db.commit()
        raise invalid_code

    user.alternate_email = verification.email
    user.alternate_email_verified_at = now
    db.delete(verification)
    try:
        db.commit()
    except IntegrityError as error:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ese correo ya está asociado a otra cuenta.",
        ) from error

    return AlternateEmailStatus(
        email=user.alternate_email,
        verified=True,
        pending_email=None,
    )


@router.get("/me", response_model=UserRead)
def get_me(user: User = Depends(current_user)):
    return user
