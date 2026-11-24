from datetime import date, datetime, timezone
from enum import Enum
from typing import List, Optional
from sqlalchemy import (
    ForeignKeyConstraint, JSON, Boolean, CheckConstraint, Date, DateTime,
    ForeignKey, Index, Numeric, String, Text, UniqueConstraint, Enum as SQLEnum, func, text
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.db import Base


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class UserRole(str, Enum):
    DUENO = "DUENO"
    ADMIN = "ADMIN"
    VETERINARIO = "VETERINARIO"
    MAYORDOMO = "MAYORDOMO"


class CattleGender(str, Enum):
    MACHO = "MACHO"
    HEMBRA = "HEMBRA"


class CattleStatus(str, Enum):
    ACTIVO = "ACTIVO"
    VENDIDO = "VENDIDO"
    MUERTO = "MUERTO"
    TRASLADADO = "TRASLADADO"


class ExitType(str, Enum):
    VENTA = "VENTA"
    MUERTE = "MUERTE"


class EventType(str, Enum):
    VACUNACION = "VACUNACION"
    DESPARASITACION = "DESPARASITACION"
    PESAJE = "PESAJE"
    TRATAMIENTO = "TRATAMIENTO"


class User(Base):
    __tablename__ = "usuarios"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(150), unique=True, index=True, nullable=False)
    full_name: Mapped[str] = mapped_column(String(100), nullable=False)
    hashed_password: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    auth_provider: Mapped[str] = mapped_column(String(20), default="local", server_default="local", nullable=False)
    provider_subject: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    role: Mapped[UserRole] = mapped_column(
        SQLEnum(UserRole, native_enum=False), default=UserRole.MAYORDOMO, nullable=False
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default=text("true"))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, server_default=func.now(), nullable=False
    )
    token_version: Mapped[int] = mapped_column(default=0, server_default=text("0"), nullable=False)
    farm_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("fincas.id", ondelete="SET NULL"), nullable=True, index=True
    )
    alternate_email: Mapped[Optional[str]] = mapped_column(String(150), unique=True, nullable=True)
    alternate_email_verified_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    module_permissions: Mapped[Optional[list[str]]] = mapped_column(JSON, nullable=True)

    # Relaciones ORM
    farm: Mapped[Optional["Farm"]] = relationship("Farm", back_populates="users", foreign_keys=[farm_id])
    owned_farms: Mapped[List["Farm"]] = relationship("Farm", back_populates="owner", foreign_keys="[Farm.owner_id]")

    __table_args__ = (
        Index("ix_users_alternate_email", "alternate_email", unique=True),
        UniqueConstraint("auth_provider", "provider_subject", name="uq_user_provider_subject"),
    )


class Farm(Base):
    __tablename__ = "fincas"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    location: Mapped[Optional[str]] = mapped_column(String(150))
    owner_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id", ondelete="RESTRICT"), nullable=False, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, server_default=func.now(), nullable=False
    )

    # Relaciones ORM
    owner: Mapped["User"] = relationship("User", back_populates="owned_farms", foreign_keys=[owner_id])
    users: Mapped[List["User"]] = relationship("User", back_populates="farm", foreign_keys="[User.farm_id]")
    animals: Mapped[List["Animal"]] = relationship("Animal", back_populates="farm", cascade="all, delete-orphan")
    lots: Mapped[List["Lot"]] = relationship("Lot", back_populates="farm", cascade="all, delete-orphan")
    inventory_items: Mapped[List["InventoryItem"]] = relationship("InventoryItem", back_populates="farm", cascade="all, delete-orphan")


class Lot(Base):
    """Potrero o lote de una finca."""
    __tablename__ = "lotes"

    id: Mapped[int] = mapped_column(primary_key=True)
    farm_id: Mapped[int] = mapped_column(ForeignKey("fincas.id", ondelete="CASCADE"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(80), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(String(255))
    area_hectares: Mapped[Optional[float]] = mapped_column(Numeric(10, 2))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default=text("true"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, server_default=func.now(), nullable=False
    )

    # Relaciones ORM
    farm: Mapped["Farm"] = relationship("Farm", back_populates="lots")
    animals: Mapped[List["Animal"]] = relationship("Animal", back_populates="lot", foreign_keys="[Animal.lote_id]")

    __table_args__ = (
        CheckConstraint("area_hectares > 0", name="ck_lotes_area_positive"),
        UniqueConstraint("farm_id", "name", name="uq_lotes_finca_nombre"),
        UniqueConstraint("id", "farm_id", name="uq_lotes_id_farm"),
    )


class Animal(Base):
    __tablename__ = "animales"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    finca_id: Mapped[int] = mapped_column(ForeignKey("fincas.id", ondelete="RESTRICT"), nullable=False, index=True)
    tag_id: Mapped[str] = mapped_column(String(50), unique=True, index=True, nullable=False)
    name: Mapped[Optional[str]] = mapped_column(String(100))
    gender: Mapped[CattleGender] = mapped_column(SQLEnum(CattleGender, native_enum=False), nullable=False)
    birth_date: Mapped[date] = mapped_column(Date, nullable=False)
    breed: Mapped[str] = mapped_column(String(50), nullable=False)
    color: Mapped[Optional[str]] = mapped_column(String(50))
    current_weight: Mapped[float] = mapped_column(Numeric(6, 2), nullable=False)
    status: Mapped[CattleStatus] = mapped_column(
        SQLEnum(CattleStatus, native_enum=False), default=CattleStatus.ACTIVO, server_default="ACTIVO", nullable=False
    )
    lote_id: Mapped[Optional[int]] = mapped_column(ForeignKey("lotes.id", ondelete="SET NULL"), nullable=True, index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default=text("true"), index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now, server_default=func.now(), nullable=False
    )
    deleted_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    # Relaciones ORM
    farm: Mapped["Farm"] = relationship("Farm", back_populates="animals")
    lot: Mapped[Optional["Lot"]] = relationship("Lot", back_populates="animals", foreign_keys=[lote_id])
    events: Mapped[List["CattleEvent"]] = relationship("CattleEvent", back_populates="animal", cascade="all, delete-orphan")
    health_records: Mapped[List["HealthRecord"]] = relationship("HealthRecord", back_populates="animal", cascade="all, delete-orphan")
    breeding_records: Mapped[List["BreedingRecord"]] = relationship("BreedingRecord", back_populates="animal", foreign_keys="[BreedingRecord.animal_id]", cascade="all, delete-orphan")
    production_records: Mapped[List["ProductionRecord"]] = relationship("ProductionRecord", back_populates="animal", cascade="all, delete-orphan")
    exit_info: Mapped[Optional["AnimalExit"]] = relationship("AnimalExit", back_populates="animal", uselist=False, cascade="all, delete-orphan")

    __table_args__ = (
        ForeignKeyConstraint(
            ["lote_id", "finca_id"],
            ["lotes.id", "lotes.farm_id"],
            name="fk_animales_lote_finca",
            ondelete="RESTRICT",
        ),
        CheckConstraint("current_weight > 0", name="ck_animales_weight_positive"),
        Index("idx_animal_finca_active", "finca_id", "is_active"),
        Index("idx_animal_status_active", "status", "is_active"),
        Index("ix_animals_finca_status", "finca_id", "status"),
    )


class LotMovement(Base):
    """Paso de un animal de un potrero a otro."""
    __tablename__ = "movimientos_lote"

    id: Mapped[int] = mapped_column(primary_key=True)
    animal_id: Mapped[int] = mapped_column(ForeignKey("animales.id", ondelete="CASCADE"), nullable=False, index=True)
    from_lot_id: Mapped[Optional[int]] = mapped_column(ForeignKey("lotes.id", ondelete="SET NULL"), index=True)
    to_lot_id: Mapped[Optional[int]] = mapped_column(ForeignKey("lotes.id", ondelete="SET NULL"), index=True)
    moved_at: Mapped[date] = mapped_column(Date, nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text)
    created_by: Mapped[Optional[int]] = mapped_column(ForeignKey("usuarios.id", ondelete="SET NULL"), index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, server_default=func.now(), nullable=False
    )

    __table_args__ = (Index("ix_movimientos_lote_animal_fecha", "animal_id", "moved_at"),)


class AnimalExit(Base):
    """Salida de un animal de la finca (venta o muerte)."""
    __tablename__ = "salidas_animales"

    id: Mapped[int] = mapped_column(primary_key=True)
    animal_id: Mapped[int] = mapped_column(
        ForeignKey("animales.id", ondelete="CASCADE"), nullable=False, unique=True, index=True
    )
    exit_type: Mapped[ExitType] = mapped_column(SQLEnum(ExitType, native_enum=False), nullable=False)
    exit_date: Mapped[date] = mapped_column(Date, nullable=False)
    price: Mapped[Optional[float]] = mapped_column(Numeric(14, 2))
    buyer: Mapped[Optional[str]] = mapped_column(String(120))
    cause: Mapped[Optional[str]] = mapped_column(String(255))
    notes: Mapped[Optional[str]] = mapped_column(Text)
    lot_id: Mapped[Optional[int]] = mapped_column(ForeignKey("lotes.id", ondelete="SET NULL"), index=True)
    created_by: Mapped[Optional[int]] = mapped_column(ForeignKey("usuarios.id", ondelete="SET NULL"), index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, server_default=func.now(), nullable=False
    )

    # Relación ORM
    animal: Mapped["Animal"] = relationship("Animal", back_populates="exit_info")


class CattleEvent(Base):
    __tablename__ = "eventos_animales"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    animal_id: Mapped[int] = mapped_column(ForeignKey("animales.id", ondelete="RESTRICT"), nullable=False, index=True)
    event_type: Mapped[EventType] = mapped_column(SQLEnum(EventType, native_enum=False), nullable=False)
    event_date: Mapped[date] = mapped_column(Date, nullable=False)
    weight: Mapped[Optional[float]] = mapped_column(Numeric(6, 2))
    description: Mapped[str] = mapped_column(String(255), nullable=False)
    withdrawal_days: Mapped[int] = mapped_column(default=0, server_default=text("0"))
    performed_by_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id", ondelete="RESTRICT"), nullable=False, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, server_default=func.now(), nullable=False
    )

    # Relación ORM
    animal: Mapped["Animal"] = relationship("Animal", back_populates="events")

    __table_args__ = (
        CheckConstraint("weight > 0", name="ck_eventos_weight_positive"),
        Index("idx_events_animal_type", "animal_id", "event_type"),
        Index("ix_cattle_events_animal_fecha", "animal_id", "event_date"),
    )


class PasswordResetCode(Base):
    __tablename__ = "codigos_recuperacion_contrasena"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    code_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, server_default=func.now(), nullable=False
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    failed_attempts: Mapped[int] = mapped_column(default=0, server_default=text("0"), nullable=False)


class AlternateEmailVerificationCode(Base):
    __tablename__ = "codigos_verificacion_correo"

    user_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id", ondelete="CASCADE"), primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(150), nullable=False)
    code_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, server_default=func.now(), nullable=False
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    failed_attempts: Mapped[int] = mapped_column(default=0, server_default=text("0"), nullable=False)


class HealthRecord(Base):
    __tablename__ = "registros_sanitarios"

    id: Mapped[int] = mapped_column(primary_key=True)
    animal_id: Mapped[int] = mapped_column(ForeignKey("animales.id", ondelete="CASCADE"), nullable=False, index=True)
    created_by: Mapped[Optional[int]] = mapped_column(ForeignKey("usuarios.id", ondelete="SET NULL"), index=True)
    record_type: Mapped[str] = mapped_column(String(30), nullable=False)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    diagnosis: Mapped[Optional[str]] = mapped_column(String(500))
    treatment: Mapped[Optional[str]] = mapped_column(Text)
    dose: Mapped[Optional[str]] = mapped_column(String(60))
    veterinarian: Mapped[Optional[str]] = mapped_column(String(120))
    next_check_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    notes: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, server_default=func.now(), nullable=False
    )

    # Relación ORM
    animal: Mapped["Animal"] = relationship("Animal", back_populates="health_records")

    __table_args__ = (Index("ix_health_records_animal_date", "animal_id", "recorded_at"),)


class BreedingRecord(Base):
    __tablename__ = "registros_reproductivos"

    id: Mapped[int] = mapped_column(primary_key=True)
    animal_id: Mapped[int] = mapped_column(ForeignKey("animales.id", ondelete="CASCADE"), nullable=False, index=True)
    related_animal_id: Mapped[Optional[int]] = mapped_column(ForeignKey("animales.id", ondelete="SET NULL"), index=True)
    created_by: Mapped[Optional[int]] = mapped_column(ForeignKey("usuarios.id", ondelete="SET NULL"), index=True)
    record_type: Mapped[str] = mapped_column(String(30), nullable=False)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    expected_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    notes: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, server_default=func.now(), nullable=False
    )

    # Relación ORM
    animal: Mapped["Animal"] = relationship("Animal", back_populates="breeding_records", foreign_keys=[animal_id])
    related_animal: Mapped[Optional["Animal"]] = relationship("Animal", foreign_keys=[related_animal_id])

    __table_args__ = (Index("ix_breeding_records_animal_date", "animal_id", "recorded_at"),)


class ProductionRecord(Base):
    __tablename__ = "registros_produccion"

    id: Mapped[int] = mapped_column(primary_key=True)
    animal_id: Mapped[int] = mapped_column(ForeignKey("animales.id", ondelete="CASCADE"), nullable=False, index=True)
    created_by: Mapped[Optional[int]] = mapped_column(ForeignKey("usuarios.id", ondelete="SET NULL"), index=True)
    record_type: Mapped[str] = mapped_column(String(20), nullable=False)
    quantity: Mapped[float] = mapped_column(Numeric(12, 3), nullable=False)
    unit: Mapped[str] = mapped_column(String(20), nullable=False)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, server_default=func.now(), nullable=False
    )

    # Relación ORM
    animal: Mapped["Animal"] = relationship("Animal", back_populates="production_records")

    __table_args__ = (
        CheckConstraint("quantity > 0", name="ck_production_records_quantity_positive"),
        Index("ix_production_records_animal_date", "animal_id", "recorded_at"),
    )


class InventoryItem(Base):
    __tablename__ = "insumos"

    id: Mapped[int] = mapped_column(primary_key=True)
    farm_id: Mapped[int] = mapped_column(ForeignKey("fincas.id", ondelete="CASCADE"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    category: Mapped[str] = mapped_column(String(40), nullable=False)
    sku: Mapped[Optional[str]] = mapped_column(String(60))
    unit: Mapped[str] = mapped_column(String(20), nullable=False)
    minimum_quantity: Mapped[float] = mapped_column(Numeric(12, 3), default=0, server_default=text("0"), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default=text("true"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, server_default=func.now(), nullable=False
    )

    # Relaciones ORM
    farm: Mapped["Farm"] = relationship("Farm", back_populates="inventory_items")
    movements: Mapped[List["InventoryMovement"]] = relationship("InventoryMovement", back_populates="item", cascade="all, delete-orphan")

    __table_args__ = (UniqueConstraint("farm_id", "sku", name="uq_inventory_items_farm_sku"),)


class InventoryMovement(Base):
    __tablename__ = "movimientos_insumos"

    id: Mapped[int] = mapped_column(primary_key=True)
    item_id: Mapped[int] = mapped_column(ForeignKey("insumos.id", ondelete="CASCADE"), nullable=False, index=True)
    animal_id: Mapped[Optional[int]] = mapped_column(ForeignKey("animales.id", ondelete="SET NULL"), index=True)
    created_by: Mapped[Optional[int]] = mapped_column(ForeignKey("usuarios.id", ondelete="SET NULL"), index=True)
    movement_type: Mapped[str] = mapped_column(String(10), nullable=False)
    quantity: Mapped[float] = mapped_column(Numeric(12, 3), nullable=False)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, server_default=func.now(), nullable=False
    )

    # Relación ORM
    item: Mapped["InventoryItem"] = relationship("InventoryItem", back_populates="movements")

    __table_args__ = (
        CheckConstraint("quantity > 0", name="ck_inventory_movements_quantity_positive"),
        Index("ix_inventory_movements_item_date", "item_id", "recorded_at"),
    )


class AuditLog(Base):
    __tablename__ = "auditoria"

    id: Mapped[int] = mapped_column(primary_key=True)
    farm_id: Mapped[Optional[int]] = mapped_column(ForeignKey("fincas.id", ondelete="SET NULL"), index=True)
    actor_user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("usuarios.id", ondelete="SET NULL"), index=True)
    action: Mapped[str] = mapped_column(String(60), nullable=False)
    entity_type: Mapped[str] = mapped_column(String(60), nullable=False)
    entity_id: Mapped[Optional[int]] = mapped_column(index=True)
    details: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, server_default=func.now(), nullable=False
    )

    __table_args__ = (Index("ix_audit_logs_farm_created_at", "farm_id", "created_at"),)


AnimalEvent = CattleEvent
