from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, aliased

from app.core.db import get_db
from app.core.deps import require_module
from app.models import Animal, CattleStatus, Lot, LotMovement, User
from app.schemas import LotCreate, LotMovementRead, LotRead, LotUpdate, MoveAnimalsIn

router = APIRouter(prefix="/api/v1/lots", tags=["Potreros"])


def _require_farm(user: User) -> int:
    if user.farm_id is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No estás asociado a ninguna finca")
    return user.farm_id


def get_farm_lot(db: Session, farm_id: int, lot_id: int, active_only: bool = True) -> Lot:
    lot = db.get(Lot, lot_id)
    if lot is None or lot.farm_id != farm_id or (active_only and not lot.is_active):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Potrero no encontrado")
    return lot


def _active_counts(db: Session, farm_id: int) -> dict[int, int]:
    rows = db.execute(
        select(Animal.lote_id, func.count(Animal.id))
        .where(
            Animal.finca_id == farm_id,
            Animal.is_active.is_(True),
            Animal.status == CattleStatus.ACTIVO,
            Animal.lote_id.is_not(None),
        )
        .group_by(Animal.lote_id)
    ).all()
    return {lot_id: total for lot_id, total in rows}


def _lot_read(lot: Lot, count: int) -> LotRead:
    return LotRead(
        id=lot.id,
        name=lot.name,
        description=lot.description,
        area_hectares=float(lot.area_hectares) if lot.area_hectares is not None else None,
        is_active=lot.is_active,
        animal_count=count,
    )


def record_movement(db: Session, animal: Animal, to_lot_id: Optional[int], moved_at, notes, user: User) -> LotMovement:
    """Mueve el animal y deja el registro en el historial."""
    movement = LotMovement(
        animal_id=animal.id,
        from_lot_id=animal.lote_id,
        to_lot_id=to_lot_id,
        moved_at=moved_at,
        notes=notes,
        created_by=user.id,
    )
    db.add(movement)
    animal.lote_id = to_lot_id
    return movement


def movement_reads(
    db: Session,
    farm_id: int,
    *,
    ids: Optional[list[int]] = None,
    animal_id: Optional[int] = None,
    lot_id: Optional[int] = None,
    limit: int = 200,
) -> list[LotMovementRead]:
    origin, destination = aliased(Lot), aliased(Lot)
    query = (
        select(LotMovement, Animal.tag_id, origin.name, destination.name, User.full_name)
        .join(Animal, Animal.id == LotMovement.animal_id)
        .outerjoin(origin, origin.id == LotMovement.from_lot_id)
        .outerjoin(destination, destination.id == LotMovement.to_lot_id)
        .outerjoin(User, User.id == LotMovement.created_by)
        .where(Animal.finca_id == farm_id)
        .order_by(LotMovement.moved_at.desc(), LotMovement.id.desc())
        .limit(limit)
    )
    if ids is not None:
        query = query.where(LotMovement.id.in_(ids))
    if animal_id is not None:
        query = query.where(LotMovement.animal_id == animal_id)
    if lot_id is not None:
        query = query.where((LotMovement.from_lot_id == lot_id) | (LotMovement.to_lot_id == lot_id))
    return [
        LotMovementRead(
            id=m.id,
            animal_id=m.animal_id,
            animal_tag=tag,
            from_lot_id=m.from_lot_id,
            from_lot_name=from_name,
            to_lot_id=m.to_lot_id,
            to_lot_name=to_name,
            moved_at=m.moved_at,
            notes=m.notes,
            created_by_name=author,
        )
        for m, tag, from_name, to_name, author in db.execute(query).all()
    ]


@router.get("", response_model=list[LotRead])
def list_lots(
    incluir_inactivos: bool = Query(False),
    db: Session = Depends(get_db),
    user: User = Depends(require_module("registro")),
):
    if user.farm_id is None:
        return []
    query = select(Lot).where(Lot.farm_id == user.farm_id).order_by(Lot.name)
    if not incluir_inactivos:
        query = query.where(Lot.is_active.is_(True))
    counts = _active_counts(db, user.farm_id)
    return [_lot_read(lot, counts.get(lot.id, 0)) for lot in db.scalars(query).all()]


@router.post("", response_model=LotRead, status_code=status.HTTP_201_CREATED)
def create_lot(data: LotCreate, db: Session = Depends(get_db), user: User = Depends(require_module("registro"))):
    farm_id = _require_farm(user)
    lot = Lot(
        farm_id=farm_id,
        name=data.nombre.strip(),
        description=data.descripcion,
        area_hectares=data.area_hectareas,
    )
    db.add(lot)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, "Ya existe un potrero con ese nombre")
    db.refresh(lot)
    return _lot_read(lot, 0)


@router.patch("/{lot_id}", response_model=LotRead)
def update_lot(
    lot_id: int,
    data: LotUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_module("registro")),
):
    farm_id = _require_farm(user)
    lot = get_farm_lot(db, farm_id, lot_id, active_only=False)
    counts = _active_counts(db, farm_id)
    if data.is_active is False and counts.get(lot.id, 0) > 0:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "El potrero tiene animales; muévelos a otro potrero antes de desactivarlo",
        )
    if data.nombre is not None:
        lot.name = data.nombre.strip()
    if "descripcion" in data.model_fields_set:
        lot.description = data.descripcion
    if "area_hectareas" in data.model_fields_set:
        lot.area_hectares = data.area_hectareas
    if data.is_active is not None:
        lot.is_active = data.is_active
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, "Ya existe un potrero con ese nombre")
    db.refresh(lot)
    return _lot_read(lot, counts.get(lot.id, 0))


@router.post("/move", response_model=list[LotMovementRead], status_code=status.HTTP_201_CREATED)
def move_animals(
    data: MoveAnimalsIn,
    db: Session = Depends(get_db),
    user: User = Depends(require_module("registro")),
):
    """Mueve uno o varios animales activos a un potrero (o los deja sin potrero)."""
    farm_id = _require_farm(user)
    destination = get_farm_lot(db, farm_id, data.lote_destino_id) if data.lote_destino_id else None
    ids = list(dict.fromkeys(data.animal_ids))
    animals = db.scalars(select(Animal).where(Animal.id.in_(ids))).all()
    by_id = {a.id: a for a in animals}
    for animal_id in ids:
        animal = by_id.get(animal_id)
        if animal is None or animal.finca_id != farm_id or not animal.is_active:
            raise HTTPException(status.HTTP_404_NOT_FOUND, f"Animal {animal_id} no encontrado")
        if animal.status != CattleStatus.ACTIVO:
            raise HTTPException(
                422, f"El animal {animal.tag_id} ya no está en la finca ({animal.status.value.lower()})")

    if data.fecha > date.today():
        raise HTTPException(422, "La fecha del movimiento no puede ser futura.")
    last_moves = dict(db.execute(
        select(LotMovement.animal_id, func.max(LotMovement.moved_at))
        .where(LotMovement.animal_id.in_(ids))
        .group_by(LotMovement.animal_id)
    ).all())
    for animal_id, last in last_moves.items():
        if last is not None and data.fecha < last:
            raise HTTPException(
                422,
                f"El animal {by_id[animal_id].tag_id} tiene un movimiento del "
                f"{last.strftime('%d/%m/%Y')}; la fecha no puede ser anterior.",
            )

    target_id = destination.id if destination else None
    # Los que ya están en el potrero de destino no generan movimiento.
    movements = [
        record_movement(db, by_id[i], target_id, data.fecha, data.notas, user)
        for i in ids if by_id[i].lote_id != target_id
    ]
    db.commit()
    if not movements:
        return []
    return movement_reads(db, farm_id, ids=[m.id for m in movements], limit=len(movements))


@router.get("/movements", response_model=list[LotMovementRead])
def list_movements(
    animal_id: Optional[int] = Query(None),
    lot_id: Optional[int] = Query(None),
    limit: int = Query(200, ge=1, le=1000),
    db: Session = Depends(get_db),
    user: User = Depends(require_module("registro")),
):
    """Historial de movimientos de la finca, del más reciente al más antiguo."""
    if user.farm_id is None:
        return []
    return movement_reads(db, user.farm_id, animal_id=animal_id, lot_id=lot_id, limit=limit)
