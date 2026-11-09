from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import current_user
from app.models import Animal, User
from app.routers.farms import get_authorized_farm
from app.schemas import AnimalCreate, AnimalPatch, AnimalRead

router = APIRouter(prefix="/api/v1/animals", tags=["Animales"])

@router.get("", response_model=list[AnimalRead])
def list_animals(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    user: User = Depends(current_user),
):
    if user.farm_id is None:
        return []
    query = select(Animal).where(Animal.finca_id == user.farm_id).order_by(
        Animal.id).offset(skip).limit(limit)
    return db.scalars(query).all()


@router.post("", response_model=AnimalRead, status_code=status.HTTP_201_CREATED)
def create_animal(data: AnimalCreate, db: Session = Depends(get_db), user: User = Depends(current_user)):
    get_authorized_farm(db, user, data.farm_id)
    payload = data.model_dump()
    finca_id = payload.pop("farm_id")
    animal = Animal(finca_id=finca_id, **payload)
    db.add(animal)
    try:
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
    if animal is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Animal no encontrado")
    get_authorized_farm(db, user, animal.finca_id)
    return animal


@router.patch("/{animal_id}", response_model=AnimalRead)
def update_animal(animal_id: int, data: AnimalPatch, db: Session = Depends(get_db), user: User = Depends(current_user)):
    animal = db.get(Animal, animal_id)
    if animal is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Animal no encontrado")
    get_authorized_farm(db, user, animal.finca_id)
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(animal, key, value)
    db.commit()
    db.refresh(animal)
    return animal
