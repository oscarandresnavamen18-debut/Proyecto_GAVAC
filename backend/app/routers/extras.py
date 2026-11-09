from fastapi import APIRouter, Depends, HTTPException, Response, status
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import current_user
from app.models import Animal, AnimalEvent, Farm, User
from app.schemas import FarmRead

router = APIRouter(prefix="/api/v1", tags=["Extras"])


class FarmSummary(BaseModel):
    farm_id: int
    total_animales: int
    por_estado: dict[str, int]
    total_eventos: int


def _farm_autorizada(db: Session, user: User, farm_id: int) -> Farm:
    farm = db.get(Farm, farm_id)
    if farm is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Finca no encontrada")
    if user.farm_id is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No estás asociado a ninguna finca")
    if user.farm_id != farm_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No tienes acceso a esta finca")
    return farm


def _animal_autorizado(db: Session, user: User, animal_id: int) -> Animal:
    animal = db.get(Animal, animal_id)
    if animal is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Animal no encontrado")
    _farm_autorizada(db, user, animal.finca_id)
    return animal


@router.get("/farms/{farm_id}", response_model=FarmRead)
def get_farm(farm_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    return _farm_autorizada(db, user, farm_id)


@router.get("/farms/{farm_id}/summary", response_model=FarmSummary)
def farm_summary(farm_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    _farm_autorizada(db, user, farm_id)

    filas = db.execute(
        select(Animal.status, func.count(Animal.id))
        .where(Animal.finca_id == farm_id)
        .group_by(Animal.status)
    ).all()
    por_estado = {status_val: total for status_val, total in filas}

    total_eventos = db.scalar(
        select(func.count(AnimalEvent.id))
        .join(Animal, Animal.id == AnimalEvent.animal_id)
        .where(Animal.finca_id == farm_id)
    ) or 0

    return FarmSummary(
        farm_id=farm_id,
        total_animales=sum(por_estado.values()),
        por_estado=por_estado,
        total_eventos=total_eventos,
    )


@router.delete("/animals/{animal_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_animal(animal_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    animal = _animal_autorizado(db, user, animal_id)
    db.delete(animal)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("/animals/{animal_id}/events/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_event(animal_id: int, event_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    _animal_autorizado(db, user, animal_id)
    event = db.get(AnimalEvent, event_id)
    if event is None or event.animal_id != animal_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Evento no encontrado")
    db.delete(event)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
