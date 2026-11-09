from datetime import datetime, timedelta, timezone
import logging
import secrets
import smtplib

from fastapi import BackgroundTasks, Depends, FastAPI, HTTPException, status, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import and_, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from app.routers import extras, social_auth

from app.config import settings
from app.db import get_db
from app.models import (
    AlternateEmailVerificationCode,
    Animal,
    AnimalEvent,
    Farm,
    PasswordResetCode,
    User,
)
from app.schemas import (
    AlternateEmailConfirm,
    AlternateEmailRequest,
    AlternateEmailStatus,
    RegisterIn,
    LoginIn,
    PasswordResetRequest,
    PasswordResetConfirm,
    TokenOut,
    UserRead,
    FarmCreate,
    FarmRead,
    AnimalCreate,
    AnimalPatch,
    AnimalRead,
    EventCreate,
    EventRead,
)
from app.security import (
    hash_one_time_code,
    hash_password,
    hash_password_reset_code,
    verify_password,
    create_access_token,
)
from app.deps import current_user
from app.mailer import send_alternate_email_verification, send_password_reset_email
from app.recaptcha import RecaptchaRejectedError, RecaptchaUnavailableError, verify_recaptcha


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


app = FastAPI(title="Gestión Ganadera API")

print("allowed_cors_origins =", settings.allowed_cors_origins)
print("type =", type(settings.allowed_cors_origins))
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_cors_origins or ["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["Salud"])
def health():
    return {"status": "ok", "service": "gestion-ganadera-api"}


@app.post("/api/v1/auth/register", response_model=TokenOut, status_code=status.HTTP_201_CREATED, tags=["Autenticación"])
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


@app.post("/api/v1/auth/login", response_model=TokenOut, tags=["Autenticación"])
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


@app.post(
    "/api/v1/auth/password-reset/request",
    status_code=status.HTTP_202_ACCEPTED,
    tags=["Autenticación"],
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


@app.post(
    "/api/v1/auth/password-reset/confirm",
    status_code=status.HTTP_204_NO_CONTENT,
    tags=["Autenticación"],
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


@app.get(
    "/api/v1/auth/alternate-email",
    response_model=AlternateEmailStatus,
    tags=["Autenticación"],
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


@app.post(
    "/api/v1/auth/alternate-email/request",
    status_code=status.HTTP_202_ACCEPTED,
    tags=["Autenticación"],
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


@app.post(
    "/api/v1/auth/alternate-email/confirm",
    response_model=AlternateEmailStatus,
    tags=["Autenticación"],
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


@app.get("/api/v1/auth/me", response_model=UserRead, tags=["Autenticación"])
def get_me(user: User = Depends(current_user)):
    return user


def get_authorized_farm(db: Session, user: User, farm_id: int) -> Farm:
    farm = db.get(Farm, farm_id)
    if farm is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Finca no encontrada")
    if user.farm_id is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                            detail="No estás asociado a ninguna finca")
    if user.farm_id != farm_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                            detail="No tienes acceso a esta finca")
    return farm


@app.get("/api/v1/farms", response_model=list[FarmRead], tags=["Fincas"])
def list_farms(db: Session = Depends(get_db), user: User = Depends(current_user)):
    if user.farm_id is None:
        return []
    query = select(Farm).where(Farm.id == user.farm_id).order_by(Farm.id)
    return db.scalars(query).all()


@app.post("/api/v1/farms", response_model=FarmRead, status_code=status.HTTP_201_CREATED, tags=["Fincas"])
def create_farm(data: FarmCreate, db: Session = Depends(get_db), user: User = Depends(current_user)):
    if user.farm_id is not None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                            detail="Ya tienes una finca asignada")

    farm = Farm(
        name=data.nombre.strip(),
        location=data.ubicacion,
        owner_id=user.id,
    )

    db.add(farm)
    db.flush()
    user.farm_id = farm.id
    db.commit()
    db.refresh(farm)
    return farm


@app.get("/api/v1/animals", response_model=list[AnimalRead], tags=["Animales"])
def list_animals(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    user: User = Depends(current_user),
):
    if user.farm_id is None:
        return []
    query = select(Animal).where(Animal.finca_id == user.farm_id).order_by(
        Animal.id).offset(skip).limit(limit)
    return db.scalars(query).all()


@app.post("/api/v1/animals", response_model=AnimalRead, status_code=status.HTTP_201_CREATED, tags=["Animales"])
def create_animal(data: AnimalCreate, db: Session = Depends(get_db), user: User = Depends(current_user)):
    get_authorized_farm(db, user, data.farm_id)
    payload = data.model_dump()
    finca_id = payload.pop("farm_id")
    animal = Animal(finca_id=finca_id, **payload)
    db.add(animal)
    try:
        db.commit()
        db.refresh(animal)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya existe un animal con ese identificador en la finca",
        )
    return animal


@app.get("/api/v1/animals/{animal_id}", response_model=AnimalRead, tags=["Animales"])
def get_animal(animal_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    animal = db.get(Animal, animal_id)
    if animal is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Animal no encontrado")
    get_authorized_farm(db, user, animal.finca_id)
    return animal


@app.patch("/api/v1/animals/{animal_id}", response_model=AnimalRead, tags=["Animales"])
def update_animal(animal_id: int, data: AnimalPatch, db: Session = Depends(get_db), user: User = Depends(current_user)):
    animal = db.get(Animal, animal_id)
    if animal is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Animal no encontrado")
    get_authorized_farm(db, user, animal.finca_id)
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(animal, key, value)
    db.commit()
    db.refresh(animal)
    return animal


@app.get("/api/v1/animals/{animal_id}/events", response_model=list[EventRead], tags=["Eventos"])
def list_events(
    animal_id: int,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    user: User = Depends(current_user),
):
    animal = db.get(Animal, animal_id)
    if animal is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Animal no encontrado")
    get_authorized_farm(db, user, animal.finca_id)
    query = (
        select(AnimalEvent)
        .where(AnimalEvent.animal_id == animal_id)
        .order_by(AnimalEvent.event_date.desc())
        .offset(skip)
        .limit(limit)
    )
    return db.scalars(query).all()


@app.post("/api/v1/animals/{animal_id}/events", response_model=EventRead, status_code=status.HTTP_201_CREATED, tags=["Eventos"])
def create_event(animal_id: int, data: EventCreate, db: Session = Depends(get_db), user: User = Depends(current_user)):
    animal = db.get(Animal, animal_id)
    if animal is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Animal no encontrado")
    get_authorized_farm(db, user, animal.finca_id)
    event = AnimalEvent(animal_id=animal_id, performed_by_id=user.id, **data.model_dump())
    db.add(event)
    db.commit()
    db.refresh(event)
    return event


app.include_router(extras.router)
app.include_router(social_auth.router)
