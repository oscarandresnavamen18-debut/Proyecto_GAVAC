from __future__ import annotations

from datetime import date, datetime, timezone
from enum import Enum
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models import CattleGender, CattleStatus, EventType, ExitType, UserRole


# AUTENTICACION

class RegisterIn(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    password: str = Field(..., min_length=8)
    role: UserRole = UserRole.ADMIN
    farm_id: Optional[int] = None


class LoginIn(BaseModel):
    email: EmailStr
    password: str
    captcha_token: Optional[str] = None
    # Tipo de usuario elegido en la pantalla de login. Opcional para mantener
    # compatibilidad con clientes anteriores; si se envía, debe coincidir.
    role: Optional[UserRole] = None


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: Optional[UserRole] = None


class ModuleName(str, Enum):
    REGISTRO = "registro"
    SANIDAD = "sanidad"
    REPRODUCCION = "reproduccion"
    PRODUCCION = "produccion"
    INSUMOS = "insumos"
    REPORTES = "reportes"


class StaffRole(str, Enum):
    VETERINARIO = "VETERINARIO"
    MAYORDOMO = "MAYORDOMO"


class UserRead(BaseModel):
    id: int
    email: EmailStr
    full_name: str
    role: str
    is_active: bool
    created_at: datetime
    farm_id: Optional[int] = None
    permissions: list[str] = []

    model_config = ConfigDict(from_attributes=True)


# ADMINISTRACION DE USUARIOS

class ManagedUserCreate(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    password: str = Field(..., min_length=8)
    role: StaffRole
    farm_id: int
    # None = permisos por defecto del rol.
    permisos: Optional[list[ModuleName]] = None


class ManagedUserUpdate(BaseModel):
    nombre: Optional[str] = Field(None, min_length=1, max_length=100)
    role: Optional[StaffRole] = None
    farm_id: Optional[int] = None
    permisos: Optional[list[ModuleName]] = None
    is_active: Optional[bool] = None
    password: Optional[str] = Field(None, min_length=8)


# FINCAS

class FarmCreate(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=100)
    ubicacion: Optional[str] = Field(None, max_length=150)


class FarmUpdate(BaseModel):
    nombre: Optional[str] = Field(None, min_length=1, max_length=100)
    ubicacion: Optional[str] = Field(None, max_length=150)


class FarmRead(BaseModel):
    id: int
    name: str
    location: Optional[str] = None
    owner_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class AlertRead(BaseModel):
    """Alarma calculada a partir de los datos de la finca."""
    # Identificador estable: tipo + registro, por ejemplo "vacuna_vencida:12".
    key: str
    # VACUNA_VENCIDA, VACUNA_POR_VENCER, PARTO_VENCIDO, PARTO_PROXIMO,
    # INSUMO_AGOTADO o INSUMO_BAJO_MINIMO.
    tipo: str
    # ALTA o MEDIA.
    severidad: str
    titulo: str
    detalle: str
    fecha: Optional[date] = None
    # Módulo donde se resuelve: sanidad, reproduccion o insumos.
    modulo: str


class DashboardSummary(BaseModel):
    """Indicadores del inicio para la finca activa (solo totales)."""
    farm_id: Optional[int] = None
    farm_name: Optional[str] = None
    total_animales: int = 0
    hembras: int = 0
    machos: int = 0
    peso_promedio_kg: Optional[float] = None
    animales_en_tratamiento: int = 0
    vacunas_por_vencer: int = 0
    vacunas_vencidas: int = 0
    vacas_gestantes: int = 0
    # Partos esperados en los próximos 30 días.
    partos_proximos: int = 0
    leche_litros_30_dias: float = 0
    leche_promedio_ordeno: Optional[float] = None
    insumos_bajo_minimo: int = 0
    # Vacunas vencidas o por vencer + insumos bajo el mínimo.
    alertas: int = 0


class FarmSummary(BaseModel):
    farm_id: int
    total_animales: int
    por_estado: dict[str, int]
    total_eventos: int


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
    # Potrero inicial (opcional).
    lote_id: Optional[int] = Field(None, gt=0)


class AnimalPatch(BaseModel):
    tag_id: Optional[str] = Field(None, min_length=1, max_length=50)
    breed: Optional[str] = Field(None, min_length=1, max_length=50)
    gender: Optional[CattleGender] = None
    birth_date: Optional[date] = None
    name: Optional[str] = Field(None, max_length=100)
    color: Optional[str] = Field(None, max_length=50)
    current_weight: Optional[float] = Field(None, gt=0)

    model_config = ConfigDict(extra="forbid")


class AnimalRead(AnimalBase):
    id: int
    finca_id: int
    lote_id: Optional[int] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# POTREROS Y SALIDAS

class LotCreate(BaseModel):
    nombre: str = Field(..., min_length=1, max_length=80)
    descripcion: Optional[str] = Field(None, max_length=255)
    area_hectareas: Optional[float] = Field(None, gt=0)


class LotUpdate(BaseModel):
    nombre: Optional[str] = Field(None, min_length=1, max_length=80)
    descripcion: Optional[str] = Field(None, max_length=255)
    area_hectareas: Optional[float] = Field(None, gt=0)
    is_active: Optional[bool] = None


class LotRead(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    area_hectares: Optional[float] = None
    is_active: bool
    # Animales activos que están hoy en el potrero.
    animal_count: int = 0


class MoveAnimalsIn(BaseModel):
    animal_ids: list[int] = Field(..., min_length=1, max_length=500)
    # Potrero de destino; null = sacar del potrero (sin asignar).
    lote_destino_id: Optional[int] = Field(None, gt=0)
    fecha: date = Field(default_factory=date.today)
    notas: Optional[str] = Field(None, max_length=2000)


class LotMovementRead(BaseModel):
    id: int
    animal_id: int
    animal_tag: str
    from_lot_id: Optional[int] = None
    from_lot_name: Optional[str] = None
    to_lot_id: Optional[int] = None
    to_lot_name: Optional[str] = None
    moved_at: date
    notes: Optional[str] = None
    created_by_name: Optional[str] = None


class AnimalExitCreate(BaseModel):
    animal_id: int = Field(..., gt=0)
    tipo: ExitType
    fecha: date = Field(default_factory=date.today)
    # Venta.
    precio: Optional[float] = Field(None, ge=0)
    comprador: Optional[str] = Field(None, max_length=120)
    # Muerte.
    causa: Optional[str] = Field(None, max_length=255)
    notas: Optional[str] = Field(None, max_length=2000)


class AnimalExitRead(BaseModel):
    id: int
    animal_id: int
    animal_tag: str
    animal_name: Optional[str] = None
    exit_type: str
    exit_date: date
    price: Optional[float] = None
    buyer: Optional[str] = None
    cause: Optional[str] = None
    notes: Optional[str] = None
    lot_name: Optional[str] = None
    created_by_name: Optional[str] = None


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


# SANIDAD

class HealthRecordType(str, Enum):
    VACUNA = "VACUNA"
    TRATAMIENTO = "TRATAMIENTO"


class HealthRecordCreate(BaseModel):
    animal_id: int = Field(..., gt=0)
    record_type: HealthRecordType
    # Nombre de la vacuna o diagnóstico del tratamiento.
    diagnosis: str = Field(..., min_length=1, max_length=500)
    # Medicamento aplicado (tratamientos).
    treatment: Optional[str] = Field(None, max_length=2000)
    dose: Optional[str] = Field(None, max_length=60)
    veterinarian: Optional[str] = Field(None, max_length=120)
    recorded_at: date = Field(default_factory=date.today)
    # Próxima dosis (vacunas) o fin del seguimiento (tratamientos).
    next_check_at: Optional[date] = None
    notes: Optional[str] = Field(None, max_length=2000)


class HealthRecordRead(BaseModel):
    id: int
    animal_id: int
    animal_tag: str
    animal_name: Optional[str] = None
    record_type: str
    diagnosis: Optional[str] = None
    treatment: Optional[str] = None
    dose: Optional[str] = None
    veterinarian: Optional[str] = None
    recorded_at: date
    next_check_at: Optional[date] = None
    notes: Optional[str] = None
    # VIGENTE, PROXIMO_A_VENCER, VENCIDO, EN_TRATAMIENTO o FINALIZADO.
    status: str


# REPRODUCCION

class BreedingRecordType(str, Enum):
    CELO = "CELO"
    INSEMINACION = "INSEMINACION"
    PRENEZ = "PRENEZ"
    PARTO = "PARTO"


class BreedingRecordCreate(BaseModel):
    animal_id: int = Field(..., gt=0)
    record_type: BreedingRecordType
    recorded_at: date = Field(default_factory=date.today)
    # Fecha esperada (por ejemplo, parto). En preñez se calcula si se omite.
    expected_at: Optional[date] = None
    notes: Optional[str] = Field(None, max_length=2000)


class BreedingRecordRead(BaseModel):
    id: int
    animal_id: int
    animal_tag: str
    animal_name: Optional[str] = None
    record_type: str
    recorded_at: date
    expected_at: Optional[date] = None
    notes: Optional[str] = None
    status: str


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
