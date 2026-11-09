
from datetime import date, datetime, timezone
from enum import Enum
from typing import Optional
from sqlalchemy import Boolean, CheckConstraint, Date, DateTime, ForeignKey, Index, Numeric, String, Text, UniqueConstraint, func, text
from sqlalchemy.orm import Mapped, mapped_column
from app.db import Base


def utc_now():
    return datetime.now(timezone.utc).replace(tzinfo=None)


class UserRole(str, Enum):
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


class EventType(str, Enum):
    VACUNACION = "VACUNACION"
    DESPARASITACION = "DESPARASITACION"
    PESAJE = "PESAJE"
    TRATAMIENTO = "TRATAMIENTO"


class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    email: Mapped[str] = mapped_column(
        String(150), unique=True, index=True, nullable=False)
    full_name: Mapped[str] = mapped_column(String(100), nullable=False)
    hashed_password: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    auth_provider: Mapped[str] = mapped_column(String(20), default="local", server_default="local", nullable=False)
    provider_subject: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    role: Mapped[UserRole] = mapped_column(
        default=UserRole.MAYORDOMO, nullable=False)
    is_active: Mapped[bool] = mapped_column(
        Boolean, default=True, server_default=text("true"))
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=utc_now, server_default=func.now())
    token_version: Mapped[int] = mapped_column(
        default=0, server_default=text("0"), nullable=False)
    farm_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("farms.id", ondelete="SET NULL"), nullable=True)
    alternate_email: Mapped[Optional[str]] = mapped_column(
        String(150), unique=True, nullable=True)
    alternate_email_verified_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime, nullable=True)
    __table_args__ = (
        Index("ix_users_alternate_email", "alternate_email", unique=True),
        UniqueConstraint("auth_provider", "provider_subject", name="uq_user_provider_subject"),
    )


class Farm(Base):
    __tablename__ = "farms"
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    location: Mapped[Optional[str]] = mapped_column(String(150))
    owner_id: Mapped[int] = mapped_column(ForeignKey(
        "users.id", ondelete="RESTRICT"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=utc_now, server_default=func.now())


class Animal(Base):
    __tablename__ = "animals"
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    finca_id: Mapped[int] = mapped_column(ForeignKey(
        "farms.id", ondelete="RESTRICT"), nullable=False, index=True)
    tag_id: Mapped[str] = mapped_column(
        String(50), unique=True, index=True, nullable=False)
    name: Mapped[Optional[str]] = mapped_column(String(100))
    gender: Mapped[CattleGender] = mapped_column(nullable=False)
    birth_date: Mapped[date] = mapped_column(Date, nullable=False)
    breed: Mapped[str] = mapped_column(String(50), nullable=False)
    color: Mapped[Optional[str]] = mapped_column(String(50))
    current_weight: Mapped[float] = mapped_column(
        Numeric(6, 2), nullable=False)
    status: Mapped[CattleStatus] = mapped_column(
        default=CattleStatus.ACTIVO, server_default="ACTIVO", nullable=False)
    is_active: Mapped[bool] = mapped_column(
        Boolean, default=True, server_default=text("true"), index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=utc_now, server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=utc_now, onupdate=utc_now, server_default=func.now(), nullable=False)
    deleted_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime, nullable=True)
    __table_args__ = (
        Index("idx_animal_finca_active", "finca_id", "is_active"),
        Index("idx_animal_status_active", "status", "is_active"),
        Index("ix_animals_finca_status", "finca_id", "status"),
    )


class CattleEvent(Base):
    __tablename__ = "cattle_events"
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    animal_id: Mapped[int] = mapped_column(ForeignKey(
        "animals.id", ondelete="RESTRICT"), nullable=False, index=True)
    event_type: Mapped[EventType] = mapped_column(nullable=False)
    event_date: Mapped[date] = mapped_column(Date, nullable=False)
    weight: Mapped[Optional[float]] = mapped_column(Numeric(6, 2))
    description: Mapped[str] = mapped_column(String(255), nullable=False)
    withdrawal_days: Mapped[int] = mapped_column(
        default=0, server_default=text("0"))
    performed_by_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=utc_now, server_default=func.now(), nullable=False)
    __table_args__ = (
        Index("idx_events_animal_type", "animal_id", "event_type"),
        Index("ix_cattle_events_animal_fecha", "animal_id", "event_date"),
    )


class PasswordResetCode(Base):
    __tablename__ = "password_reset_codes"
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey(
        "users.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    code_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=utc_now, server_default=func.now(), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    failed_attempts: Mapped[int] = mapped_column(
        default=0, server_default=text("0"), nullable=False)


class AlternateEmailVerificationCode(Base):
    __tablename__ = "alternate_email_verification_codes"
    user_id: Mapped[int] = mapped_column(ForeignKey(
        "users.id", ondelete="CASCADE"), primary_key=True)
    email: Mapped[str] = mapped_column(String(150), nullable=False)
    code_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=utc_now, server_default=func.now(), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    failed_attempts: Mapped[int] = mapped_column(
        default=0, server_default=text("0"), nullable=False)


class HealthRecord(Base):
    __tablename__ = "health_records"
    id: Mapped[int] = mapped_column(primary_key=True)
    animal_id: Mapped[int] = mapped_column(ForeignKey(
        "animals.id", ondelete="CASCADE"), nullable=False)
    created_by: Mapped[Optional[int]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"))
    record_type: Mapped[str] = mapped_column(String(30), nullable=False)
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False)
    diagnosis: Mapped[Optional[str]] = mapped_column(String(500))
    treatment: Mapped[Optional[str]] = mapped_column(Text)
    veterinarian: Mapped[Optional[str]] = mapped_column(String(120))
    next_check_at: Mapped[Optional[datetime]
                          ] = mapped_column(DateTime(timezone=True))
    notes: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False)
    __table_args__ = (Index("ix_health_records_animal_date",
                      "animal_id", "recorded_at"),)


class BreedingRecord(Base):
    __tablename__ = "breeding_records"
    id: Mapped[int] = mapped_column(primary_key=True)
    animal_id: Mapped[int] = mapped_column(ForeignKey(
        "animals.id", ondelete="CASCADE"), nullable=False)
    related_animal_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("animals.id", ondelete="SET NULL"))
    created_by: Mapped[Optional[int]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"))
    record_type: Mapped[str] = mapped_column(String(30), nullable=False)
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False)
    expected_at: Mapped[Optional[datetime]
                        ] = mapped_column(DateTime(timezone=True))
    notes: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False)
    __table_args__ = (Index("ix_breeding_records_animal_date",
                      "animal_id", "recorded_at"),)


class ProductionRecord(Base):
    __tablename__ = "production_records"
    id: Mapped[int] = mapped_column(primary_key=True)
    animal_id: Mapped[int] = mapped_column(ForeignKey(
        "animals.id", ondelete="CASCADE"), nullable=False)
    created_by: Mapped[Optional[int]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"))
    record_type: Mapped[str] = mapped_column(String(20), nullable=False)
    quantity: Mapped[float] = mapped_column(Numeric(12, 3), nullable=False)
    unit: Mapped[str] = mapped_column(String(20), nullable=False)
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False)
    __table_args__ = (
        CheckConstraint(
            "quantity > 0", name="ck_production_records_quantity_positive"),
        Index("ix_production_records_animal_date", "animal_id", "recorded_at"),
    )


class InventoryItem(Base):
    __tablename__ = "inventory_items"
    id: Mapped[int] = mapped_column(primary_key=True)
    farm_id: Mapped[int] = mapped_column(ForeignKey(
        "farms.id", ondelete="CASCADE"), nullable=False)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    category: Mapped[str] = mapped_column(String(40), nullable=False)
    sku: Mapped[Optional[str]] = mapped_column(String(60))
    unit: Mapped[str] = mapped_column(String(20), nullable=False)
    minimum_quantity: Mapped[float] = mapped_column(
        Numeric(12, 3), default=0, server_default=text("0"), nullable=False)
    is_active: Mapped[bool] = mapped_column(
        Boolean, default=True, server_default=text("true"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False)
    __table_args__ = (UniqueConstraint("farm_id", "sku",
                      name="uq_inventory_items_farm_sku"),)


class InventoryMovement(Base):
    __tablename__ = "inventory_movements"
    id: Mapped[int] = mapped_column(primary_key=True)
    item_id: Mapped[int] = mapped_column(ForeignKey(
        "inventory_items.id", ondelete="CASCADE"), nullable=False)
    animal_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("animals.id", ondelete="SET NULL"))
    created_by: Mapped[Optional[int]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"))
    movement_type: Mapped[str] = mapped_column(String(10), nullable=False)
    quantity: Mapped[float] = mapped_column(Numeric(12, 3), nullable=False)
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False)
    __table_args__ = (
        CheckConstraint(
            "quantity > 0", name="ck_inventory_movements_quantity_positive"),
        Index("ix_inventory_movements_item_date", "item_id", "recorded_at"),
    )


class AuditLog(Base):
    __tablename__ = "audit_logs"
    id: Mapped[int] = mapped_column(primary_key=True)
    farm_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("farms.id", ondelete="SET NULL"))
    actor_user_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"))
    action: Mapped[str] = mapped_column(String(60), nullable=False)
    entity_type: Mapped[str] = mapped_column(String(60), nullable=False)
    entity_id: Mapped[Optional[int]] = mapped_column()
    details: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False)
    __table_args__ = (
        Index("ix_audit_logs_farm_created_at", "farm_id", "created_at"),)


AnimalEvent = CattleEvent
