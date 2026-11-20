from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.deps import require_module
from app.models import Animal, AnimalExit, CattleStatus, ExitType, Lot, User
from app.schemas import AnimalExitCreate, AnimalExitRead

router = APIRouter(prefix="/api/v1/exits", tags=["Salidas de animales"])

STATUS_BY_EXIT = {ExitType.VENTA: CattleStatus.VENDIDO, ExitType.MUERTE: CattleStatus.MUERTO}


def farm_exits(db: Session, farm_id: int, exit_type: Optional[ExitType] = None,
               ids: Optional[list[int]] = None) -> list[AnimalExitRead]:
    """Salidas de la finca, de la más reciente a la más antigua."""
    query = (
        select(AnimalExit, Animal.tag_id, Animal.name, Lot.name, User.full_name)
        .join(Animal, Animal.id == AnimalExit.animal_id)
        .outerjoin(Lot, Lot.id == AnimalExit.lot_id)
        .outerjoin(User, User.id == AnimalExit.created_by)
        .where(Animal.finca_id == farm_id, Animal.is_active.is_(True))
        .order_by(AnimalExit.exit_date.desc(), AnimalExit.id.desc())
    )
    if exit_type is not None:
        query = query.where(AnimalExit.exit_type == exit_type)
    if ids is not None:
        query = query.where(AnimalExit.id.in_(ids))
    return [
        AnimalExitRead(
            id=e.id,
            animal_id=e.animal_id,
            animal_tag=tag,
            animal_name=name,
            exit_type=e.exit_type.value,
            exit_date=e.exit_date,
            price=float(e.price) if e.price is not None else None,
            buyer=e.buyer,
            cause=e.cause,
            notes=e.notes,
            lot_name=lot_name,
            created_by_name=author,
        )
        for e, tag, name, lot_name, author in db.execute(query).all()
    ]


def _farm_animal(db: Session, user: User, animal_id: int) -> Animal:
    if user.farm_id is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No estás asociado a ninguna finca")
    animal = db.get(Animal, animal_id)
    if animal is None or animal.finca_id != user.farm_id or not animal.is_active:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Animal no encontrado")
    return animal


@router.get("", response_model=list[AnimalExitRead])
def list_exits(
    tipo: Optional[ExitType] = Query(None),
    db: Session = Depends(get_db),
    user: User = Depends(require_module("registro")),
):
    if user.farm_id is None:
        return []
    return farm_exits(db, user.farm_id, tipo)


@router.post("", response_model=AnimalExitRead, status_code=status.HTTP_201_CREATED)
def register_exit(
    data: AnimalExitCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_module("registro")),
):
    """Registra la venta o la muerte de un animal: sale del inventario activo."""
    animal = _farm_animal(db, user, data.animal_id)
    if animal.status != CattleStatus.ACTIVO:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"El animal {animal.tag_id} ya tiene una salida registrada ({animal.status.value.lower()})",
        )
    if data.tipo == ExitType.MUERTE and not (data.causa or "").strip():
        raise HTTPException(422, "Indica la causa de la muerte.")

    exit_record = AnimalExit(
        animal_id=animal.id,
        exit_type=data.tipo,
        exit_date=data.fecha,
        price=data.precio if data.tipo == ExitType.VENTA else None,
        buyer=(data.comprador or "").strip() or None if data.tipo == ExitType.VENTA else None,
        cause=(data.causa or "").strip() or None if data.tipo == ExitType.MUERTE else None,
        notes=data.notas,
        lot_id=animal.lote_id,
        created_by=user.id,
    )
    db.add(exit_record)
    animal.status = STATUS_BY_EXIT[data.tipo]
    # Sale del potrero; el potrero queda guardado en la salida.
    animal.lote_id = None
    db.commit()
    return farm_exits(db, user.farm_id, ids=[exit_record.id])[0]


@router.delete("/{exit_id}", status_code=status.HTTP_204_NO_CONTENT)
def cancel_exit(
    exit_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_module("registro")),
):
    """Anula una salida registrada por error: el animal vuelve a estar activo."""
    exit_record = db.get(AnimalExit, exit_id)
    if exit_record is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Salida no encontrada")
    animal = _farm_animal(db, user, exit_record.animal_id)
    animal.status = CattleStatus.ACTIVO
    # Vuelve al potrero donde estaba, si sigue activo.
    lot = db.get(Lot, exit_record.lot_id) if exit_record.lot_id else None
    animal.lote_id = lot.id if lot is not None and lot.is_active else None
    db.delete(exit_record)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
