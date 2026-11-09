from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import current_user
from app.models import Animal, AnimalEvent, User
from app.routers.farms import get_authorized_farm
from app.schemas import EventCreate, EventRead

router = APIRouter(
    prefix="/api/v1/animals/{animal_id}/events",
    tags=["Eventos"],
)

@router.get("", response_model=list[EventRead])
def list_events(
    animal_id: int,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    user: User = Depends(current_user),
):
    animal = db.get(Animal, animal_id)
    if animal is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Animal no encontrado")
    get_authorized_farm(db, user, animal.finca_id)
    query = (
        select(AnimalEvent)
        .where(AnimalEvent.animal_id == animal_id)
        .order_by(AnimalEvent.event_date.desc())
        .offset(skip)
        .limit(limit)
    )
    return db.scalars(query).all()


@router.post("", response_model=EventRead, status_code=status.HTTP_201_CREATED)
def create_event(animal_id: int, data: EventCreate, db: Session = Depends(get_db), user: User = Depends(current_user)):
    animal = db.get(Animal, animal_id)
    if animal is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Animal no encontrado")
    get_authorized_farm(db, user, animal.finca_id)
    event = AnimalEvent(animal_id=animal_id, performed_by_id=user.id, **data.model_dump())
    db.add(event)
    db.commit()
    db.refresh(event)
    return event
