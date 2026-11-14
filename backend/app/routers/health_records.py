from datetime import date, datetime, time, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.deps import require_module
from app.models import Animal, HealthRecord, User
from app.routers.farms import get_authorized_farm
from app.schemas import HealthRecordCreate, HealthRecordRead

router = APIRouter(prefix="/api/v1/health-records", tags=["Sanidad"])

# Días antes del vencimiento en que una vacuna pasa a "próxima a vencer".
VACCINE_WARNING_DAYS = 15


def to_datetime(value: date) -> datetime:
    return datetime.combine(value, time.min, tzinfo=timezone.utc)


def to_date(value: datetime | None) -> date | None:
    return value.date() if value is not None else None


def get_farm_animal(db: Session, user: User, animal_id: int) -> Animal:
    animal = db.get(Animal, animal_id)
    if animal is None or not animal.is_active:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Animal no encontrado")
    get_authorized_farm(db, user, animal.finca_id)
    return animal


def health_status(record: HealthRecord, today: date | None = None) -> str:
    today = today or date.today()
    due = to_date(record.next_check_at)
    if record.record_type == "VACUNA":
        if due is None:
            return "VIGENTE"
        if due < today:
            return "VENCIDO"
        if due <= today + timedelta(days=VACCINE_WARNING_DAYS):
            return "PROXIMO_A_VENCER"
        return "VIGENTE"
    if due is not None and due < today:
        return "FINALIZADO"
    return "EN_TRATAMIENTO"


def health_read(record: HealthRecord, animal: Animal) -> HealthRecordRead:
    return HealthRecordRead(
        id=record.id,
        animal_id=animal.id,
        animal_tag=animal.tag_id,
        animal_name=animal.name,
        record_type=record.record_type,
        diagnosis=record.diagnosis,
        treatment=record.treatment,
        dose=record.dose,
        veterinarian=record.veterinarian,
        recorded_at=to_date(record.recorded_at),
        next_check_at=to_date(record.next_check_at),
        notes=record.notes,
        status=health_status(record),
    )


def farm_health_records(db: Session, farm_id: int) -> list[tuple[HealthRecord, Animal]]:
    return db.execute(
        select(HealthRecord, Animal)
        .join(Animal, Animal.id == HealthRecord.animal_id)
        .where(Animal.finca_id == farm_id)
        .order_by(HealthRecord.recorded_at.desc(), HealthRecord.id.desc())
    ).all()


@router.get("", response_model=list[HealthRecordRead])
def list_health_records(
    db: Session = Depends(get_db),
    user: User = Depends(require_module("sanidad")),
):
    if user.farm_id is None:
        return []
    return [health_read(record, animal) for record, animal in farm_health_records(db, user.farm_id)]


@router.post("", response_model=HealthRecordRead, status_code=status.HTTP_201_CREATED)
def create_health_record(
    data: HealthRecordCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_module("sanidad")),
):
    animal = get_farm_animal(db, user, data.animal_id)
    if data.next_check_at is not None and data.next_check_at < data.recorded_at:
        raise HTTPException(
            422,
            "La próxima fecha no puede ser anterior a la fecha de aplicación.",
        )
    record = HealthRecord(
        animal_id=animal.id,
        created_by=user.id,
        record_type=data.record_type,
        diagnosis=data.diagnosis.strip(),
        treatment=data.treatment,
        dose=data.dose,
        # Si no se indica, se registra el nombre de quien hace el registro.
        veterinarian=(data.veterinarian or "").strip() or user.full_name,
        recorded_at=to_datetime(data.recorded_at),
        next_check_at=to_datetime(data.next_check_at) if data.next_check_at else None,
        notes=data.notes,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return health_read(record, animal)


@router.delete("/{record_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_health_record(
    record_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_module("sanidad")),
):
    record = db.get(HealthRecord, record_id)
    animal = db.get(Animal, record.animal_id) if record is not None else None
    if record is None or animal is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Registro sanitario no encontrado")
    get_authorized_farm(db, user, animal.finca_id)
    db.delete(record)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
