from datetime import timezone
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import current_user
from app.models import Animal, ProductionRecord, User
from app.routers.farms import get_authorized_farm
from app.schemas import ProductionCreate, ProductionRead

router = APIRouter(prefix="/api/v1/production", tags=["Producción"])


def _production_read(record: ProductionRecord, animal: Animal) -> ProductionRead:
    return ProductionRead(
        id=record.id,
        animal_id=animal.id,
        animal_tag=animal.tag_id,
        record_type=record.record_type,
        quantity=float(record.quantity),
        unit=record.unit,
        recorded_at=record.recorded_at,
        notes=record.notes,
    )


@router.get("", response_model=list[ProductionRead])
def list_production(
    db: Session = Depends(get_db),
    user: User = Depends(current_user),
):
    if user.farm_id is None:
        return []

    rows = db.execute(
        select(ProductionRecord, Animal)
        .join(Animal, Animal.id == ProductionRecord.animal_id)
        .where(Animal.finca_id == user.farm_id)
        .order_by(ProductionRecord.recorded_at.desc(), ProductionRecord.id.desc())
    ).all()
    return [_production_read(record, animal) for record, animal in rows]


@router.post("", response_model=list[ProductionRead], status_code=status.HTTP_201_CREATED)
def create_production(
    data: ProductionCreate,
    db: Session = Depends(get_db),
    user: User = Depends(current_user),
):
    if data.milk_liters is None and data.weight_kg is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Registra al menos litros de leche o peso.",
        )

    animal = db.get(Animal, data.animal_id)
    if animal is None or not animal.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Animal no encontrado",
        )
    get_authorized_farm(db, user, animal.finca_id)

    recorded_at = data.recorded_at
    if recorded_at.tzinfo is None:
        recorded_at = recorded_at.replace(tzinfo=timezone.utc)

    records = []
    if data.milk_liters is not None:
        records.append(
            ProductionRecord(
                animal_id=animal.id,
                created_by=user.id,
                record_type="MILK",
                quantity=Decimal(str(data.milk_liters)),
                unit="L",
                recorded_at=recorded_at,
                notes=data.notes,
            )
        )
    if data.weight_kg is not None:
        records.append(
            ProductionRecord(
                animal_id=animal.id,
                created_by=user.id,
                record_type="WEIGHT",
                quantity=Decimal(str(data.weight_kg)),
                unit="kg",
                recorded_at=recorded_at,
                notes=data.notes,
            )
        )

    db.add_all(records)
    db.commit()
    for record in records:
        db.refresh(record)
    return [_production_read(record, animal) for record in records]


@router.delete("/{record_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_production(
    record_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(current_user),
):
    row = db.execute(
        select(ProductionRecord, Animal)
        .join(Animal, Animal.id == ProductionRecord.animal_id)
        .where(ProductionRecord.id == record_id)
    ).first()
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Registro de producción no encontrado",
        )
    record, animal = row
    get_authorized_farm(db, user, animal.finca_id)
    db.delete(record)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
