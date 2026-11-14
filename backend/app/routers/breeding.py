from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import require_module
from app.models import Animal, BreedingRecord, CattleGender, User
from app.routers.farms import get_authorized_farm
from app.routers.health_records import get_farm_animal, to_date, to_datetime
from app.schemas import BreedingRecordCreate, BreedingRecordRead

router = APIRouter(prefix="/api/v1/breeding-records", tags=["Reproducción"])

# Gestación bovina promedio.
GESTATION_DAYS = 283


def breeding_status(record: BreedingRecord, today: date | None = None) -> str:
    today = today or date.today()
    expected = to_date(record.expected_at)
    match record.record_type:
        case "CELO":
            return "En celo"
        case "INSEMINACION":
            return "Inseminada, pendiente confirmar preñez"
        case "PRENEZ":
            if expected is None:
                return "Gestante"
            days = (expected - today).days
            if days < 0:
                return "Parto vencido, verificar"
            return f"Gestante, parto en {days} días"
        case _:
            return "Parto registrado"


def breeding_read(record: BreedingRecord, animal: Animal) -> BreedingRecordRead:
    return BreedingRecordRead(
        id=record.id,
        animal_id=animal.id,
        animal_tag=animal.tag_id,
        animal_name=animal.name,
        record_type=record.record_type,
        recorded_at=to_date(record.recorded_at),
        expected_at=to_date(record.expected_at),
        notes=record.notes,
        status=breeding_status(record),
    )


def farm_breeding_records(db: Session, farm_id: int) -> list[tuple[BreedingRecord, Animal]]:
    return db.execute(
        select(BreedingRecord, Animal)
        .join(Animal, Animal.id == BreedingRecord.animal_id)
        .where(Animal.finca_id == farm_id)
        .order_by(BreedingRecord.recorded_at.desc(), BreedingRecord.id.desc())
    ).all()


@router.get("", response_model=list[BreedingRecordRead])
def list_breeding_records(
    db: Session = Depends(get_db),
    user: User = Depends(require_module("reproduccion")),
):
    if user.farm_id is None:
        return []
    return [breeding_read(record, animal) for record, animal in farm_breeding_records(db, user.farm_id)]


@router.post("", response_model=BreedingRecordRead, status_code=status.HTTP_201_CREATED)
def create_breeding_record(
    data: BreedingRecordCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_module("reproduccion")),
):
    animal = get_farm_animal(db, user, data.animal_id)
    if animal.gender != CattleGender.HEMBRA:
        raise HTTPException(
            422, "Los eventos reproductivos solo se registran en hembras.")
    if data.recorded_at > date.today():
        raise HTTPException(422, "La fecha del evento no puede ser futura.")

    expected_at = data.expected_at
    if expected_at is None and data.record_type == "PRENEZ":
        expected_at = data.recorded_at + timedelta(days=GESTATION_DAYS)

    record = BreedingRecord(
        animal_id=animal.id,
        created_by=user.id,
        record_type=data.record_type,
        recorded_at=to_datetime(data.recorded_at),
        expected_at=to_datetime(expected_at) if expected_at else None,
        notes=data.notes,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return breeding_read(record, animal)


@router.delete("/{record_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_breeding_record(
    record_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_module("reproduccion")),
):
    record = db.get(BreedingRecord, record_id)
    animal = db.get(Animal, record.animal_id) if record is not None else None
    if record is None or animal is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Registro reproductivo no encontrado")
    get_authorized_farm(db, user, animal.finca_id)
    db.delete(record)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
