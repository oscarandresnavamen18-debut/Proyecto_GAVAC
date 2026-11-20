from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.deps import current_user, require_module
from app.models import Animal, CattleStatus, User, utc_now
from app.routers.farms import get_authorized_farm
from app.routers.lots import get_farm_lot, record_movement
from app.schemas import AnimalCreate, AnimalPatch, AnimalRead

router = APIRouter(prefix="/api/v1/animals", tags=["Animales"])

@router.get("", response_model=list[AnimalRead])
def list_animals(
    estado: Literal["activos", "todos"] = Query(
        "activos", description="activos = en la finca; todos = incluye vendidos y muertos"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    user: User = Depends(current_user),
):
    if user.farm_id is None:
        return []
    query = (
        select(Animal)
        .where(Animal.finca_id == user.farm_id, Animal.is_active.is_(True))
        .order_by(Animal.id)
        .offset(skip)
        .limit(limit)
    )
    if estado == "activos":
        query = query.where(Animal.status == CattleStatus.ACTIVO)
    return db.scalars(query).all()


@router.post("", response_model=AnimalRead, status_code=status.HTTP_201_CREATED)
def create_animal(data: AnimalCreate, db: Session = Depends(get_db), user: User = Depends(require_module("registro"))):
    get_authorized_farm(db, user, data.farm_id)
    lot = get_farm_lot(db, data.farm_id, data.lote_id) if data.lote_id else None
    payload = data.model_dump(exclude={"farm_id", "lote_id"})
    # Todo animal entra activo; deja de estarlo solo al registrar una salida.
    payload["status"] = CattleStatus.ACTIVO
    animal = Animal(finca_id=data.farm_id, **payload)
    db.add(animal)
    try:
        db.flush()
        if lot is not None:
            record_movement(db, animal, lot.id, utc_now().date(), "Ingreso al potrero", user)
        db.commit()
        db.refresh(animal)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya existe un animal con ese identificador en la finca",
        )
    return animal


@router.get("/{animal_id}", response_model=AnimalRead)
def get_animal(animal_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    animal = db.get(Animal, animal_id)
    if animal is None or not animal.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Animal no encontrado")
    get_authorized_farm(db, user, animal.finca_id)
    return animal


@router.patch("/{animal_id}", response_model=AnimalRead)
def update_animal(animal_id: int, data: AnimalPatch, db: Session = Depends(get_db), user: User = Depends(require_module("registro"))):
    animal = db.get(Animal, animal_id)
    if animal is None or not animal.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Animal no encontrado")
    get_authorized_farm(db, user, animal.finca_id)
    for key, value in data.model_dump(exclude_unset=True).items():
        if value is None and key in ("tag_id", "breed", "gender", "birth_date"):
            continue  # Campos obligatorios: no se pueden vaciar.
        setattr(animal, key, value.strip() if isinstance(value, str) else value)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya existe un animal con ese identificador",
        )
    db.refresh(animal)
    return animal


@router.delete("/{animal_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_animal(animal_id: int, db: Session = Depends(get_db), user: User = Depends(require_module("registro"))):
    animal = db.get(Animal, animal_id)
    if animal is None or not animal.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Animal no encontrado")
    get_authorized_farm(db, user, animal.finca_id)
    # Borrado lógico: se conserva el historial sanitario, reproductivo y de
    # producción del animal para los reportes.
    animal.is_active = False
    animal.deleted_at = utc_now()
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
