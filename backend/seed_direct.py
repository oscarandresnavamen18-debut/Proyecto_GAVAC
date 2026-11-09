from pydantic import BaseModel, ConfigDict, EmailStr, Field
from typing import Literal, Optional
from datetime import date, datetime



# AUTENTICACIÓN

class RegisterIn(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    password: str = Field(..., min_length=8)


class LoginIn(BaseModel):
    email: EmailStr
    password: str
    captcha_token: Optional[str] = None


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserRead(BaseModel):
    id: int
    email: EmailStr
    full_name: str
    role: str
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


# FINCAS

class FarmCreate(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=100)
    ubicacion: Optional[str] = Field(None, max_length=150)


class FarmRead(BaseModel):
    id: int
    name: str
    location: Optional[str] = None
    owner_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ANIMALES

class AnimalBase(BaseModel):
    tag_id: str = Field(..., min_length=1, max_length=50)
    name: Optional[str] = Field(None, max_length=100)
    gender: Literal["MACHO", "HEMBRA"]
    birth_date: date
    breed: str = Field(..., min_length=1, max_length=50)
    color: Optional[str] = Field(None, max_length=50)
    current_weight: float = Field(..., gt=0)
    status: Literal["ACTIVO", "VENDIDO", "MUERTO", "TRASLADADO"] = "ACTIVO"


class AnimalCreate(AnimalBase):
    farm_id: int = Field(..., gt=0)


class AnimalPatch(BaseModel):
    name: Optional[str] = Field(None, max_length=100)
    color: Optional[str] = Field(None, max_length=50)
    current_weight: Optional[float] = Field(None, gt=0)
    status: Optional[Literal["ACTIVO", "VENDIDO",
                             "MUERTO", "TRASLADADO"]] = None

    model_config = ConfigDict(extra="forbid")


class AnimalRead(AnimalBase):
    id: int
    finca_id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# EVENTOS

class EventBase(BaseModel):
    event_type: Literal[
        "VACUNACION",
        "DESPARASITACION",
        "PESAJE",
        "TRATAMIENTO",
    ]
    event_date: date
    weight: Optional[float] = Field(None, gt=0)
    description: str = Field(..., min_length=1, max_length=255)
    withdrawal_days: int = Field(0, ge=0)


class EventCreate(EventBase):
    pass


class EventRead(EventBase):
    id: int
    animal_id: int
    performed_by_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


# RECUPERACIÓN DE CONTRASEÑA

class PasswordResetRequest(BaseModel):
    email: EmailStr


class PasswordResetConfirm(BaseModel):
    email: EmailStr
    code: str = Field(..., min_length=6, max_length=6)
    new_password: str = Field(..., min_length=8)


# CORREO ALTERNATIVO

class AlternateEmailRequest(BaseModel):
    email: EmailStr


class AlternateEmailConfirm(BaseModel):
    email: EmailStr
    code: str = Field(..., min_length=6, max_length=6)


class AlternateEmailStatus(BaseModel):
    alternate_email: Optional[EmailStr] = None
    alternate_email_verified: bool = False



