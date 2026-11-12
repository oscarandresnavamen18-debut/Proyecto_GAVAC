from datetime import date, datetime, timezone
from typing import Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models import CattleGender, CattleStatus, EventType


# AUTENTICACION

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
    gender: CattleGender
    birth_date: date
    breed: str = Field(..., min_length=1, max_length=50)
    color: Optional[str] = Field(None, max_length=50)
    current_weight: float = Field(..., gt=0)
    status: CattleStatus = CattleStatus.ACTIVO


class AnimalCreate(AnimalBase):
    farm_id: int = Field(..., gt=0)


class AnimalPatch(BaseModel):
    name: Optional[str] = Field(None, max_length=100)
    color: Optional[str] = Field(None, max_length=50)
    current_weight: Optional[float] = Field(None, gt=0)
    status: Optional[CattleStatus] = None

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
    event_type: EventType
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


# PRODUCCION

class ProductionCreate(BaseModel):
    animal_id: int = Field(..., gt=0)
    milk_liters: Optional[float] = Field(None, gt=0)
    weight_kg: Optional[float] = Field(None, gt=0)
    recorded_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc))
    notes: Optional[str] = Field(None, max_length=2000)


class ProductionRead(BaseModel):
    id: int
    animal_id: int
    animal_tag: str
    record_type: str
    quantity: float
    unit: str
    recorded_at: datetime
    notes: Optional[str] = None


# INVENTARIO

class InventoryCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=120)
    category: str = Field("GENERAL", min_length=1, max_length=40)
    unit: str = Field("unidad", min_length=1, max_length=20)
    quantity: float = Field(..., gt=0)
    minimum_quantity: float = Field(0, ge=0)


class InventoryRead(BaseModel):
    id: int
    name: str
    category: str
    unit: str
    quantity: float
    minimum_quantity: float
    is_active: bool
    created_at: datetime


# RECUPERACION DE CONTRASENA

class PasswordResetRequest(BaseModel):
    email: EmailStr


class PasswordResetConfirm(BaseModel):
    email: EmailStr
    code: str = Field(..., min_length=8, max_length=8, pattern=r"^[0-9]{8}$")
    new_password: str = Field(..., min_length=8)


# CORREO ALTERNATIVO

class AlternateEmailRequest(BaseModel):
    email: EmailStr


class AlternateEmailConfirm(BaseModel):
    code: str = Field(..., min_length=8, max_length=8, pattern=r"^[0-9]{8}$")


class AlternateEmailStatus(BaseModel):
    email: Optional[EmailStr] = None
    verified: bool = False
    pending_email: Optional[EmailStr] = None
