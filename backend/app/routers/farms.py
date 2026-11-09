from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import current_user
from app.models import Farm, User
from app.schemas import FarmCreate, FarmRead

router = APIRouter(prefix="/api/v1/farms", tags=["Fincas"])

def get_authorized_farm(db: Session, user: User, farm_id: int) -> Farm:
    farm = db.get(Farm, farm_id)
    if farm is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Finca no encontrada")
    if user.farm_id is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                            detail="No estás asociado a ninguna finca")
    if user.farm_id != farm_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                            detail="No tienes acceso a esta finca")
    return farm


@router.get("", response_model=list[FarmRead])
def list_farms(db: Session = Depends(get_db), user: User = Depends(current_user)):
    if user.farm_id is None:
        return []
    query = select(Farm).where(Farm.id == user.farm_id).order_by(Farm.id)
    return db.scalars(query).all()


@router.post("", response_model=FarmRead, status_code=status.HTTP_201_CREATED)
def create_farm(data: FarmCreate, db: Session = Depends(get_db), user: User = Depends(current_user)):
    if user.farm_id is not None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                            detail="Ya tienes una finca asignada")

    farm = Farm(
        name=data.nombre.strip(),
        location=data.ubicacion,
        owner_id=user.id,
    )

    db.add(farm)
    db.flush()
    user.farm_id = farm.id
    db.commit()
    db.refresh(farm)
    return farm
