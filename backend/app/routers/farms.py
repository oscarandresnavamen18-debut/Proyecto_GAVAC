from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.deps import current_user, require_admin
from app.models import Animal, AnimalEvent, Farm, User, UserRole
from app.schemas import FarmCreate, FarmRead, FarmSummary, FarmUpdate

router = APIRouter(prefix="/api/v1/farms", tags=["Fincas"])


def get_authorized_farm(db: Session, user: User, farm_id: int) -> Farm:
    farm = db.get(Farm, farm_id)
    if farm is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Finca no encontrada")
    # El dueño o administrador puede operar en cualquiera de las fincas de las que es dueño.
    if user.role in (UserRole.DUENO, UserRole.ADMIN) and farm.owner_id == user.id:
        return farm
    if user.farm_id is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                            detail="No estás asociado a ninguna finca")
    if user.farm_id != farm_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                            detail="No tienes acceso a esta finca")
    return farm


def get_owned_farm(db: Session, admin: User, farm_id: int) -> Farm:
    farm = db.get(Farm, farm_id)
    if farm is None or farm.owner_id != admin.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Finca no encontrada")
    return farm


@router.get("", response_model=list[FarmRead])
def list_farms(db: Session = Depends(get_db), user: User = Depends(current_user)):
    if user.role in (UserRole.DUENO, UserRole.ADMIN):
        query = select(Farm).where(Farm.owner_id == user.id).order_by(Farm.id)
        return db.scalars(query).all()
    if user.farm_id is None:
        return []
    query = select(Farm).where(Farm.id == user.farm_id).order_by(Farm.id)
    return db.scalars(query).all()


@router.get("/public", response_model=list[FarmRead])
def list_public_farms(db: Session = Depends(get_db)):
    """Lista todas las fincas disponibles para selección al registrarse."""
    query = select(Farm).order_by(Farm.id)
    return db.scalars(query).all()


@router.post("", response_model=FarmRead, status_code=status.HTTP_201_CREATED)
def create_farm(data: FarmCreate, db: Session = Depends(get_db), user: User = Depends(require_admin)):
    farm = Farm(
        name=data.nombre.strip(),
        location=data.ubicacion,
        owner_id=user.id,
    )

    db.add(farm)
    db.flush()
    # La primera finca del administrador queda como su finca activa.
    if user.farm_id is None:
        user.farm_id = farm.id
    db.commit()
    db.refresh(farm)
    return farm


@router.patch("/{farm_id}", response_model=FarmRead)
def update_farm(
    farm_id: int,
    data: FarmUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_admin),
):
    farm = get_owned_farm(db, user, farm_id)
    if data.nombre is not None:
        farm.name = data.nombre.strip()
    if "ubicacion" in data.model_fields_set:
        farm.location = data.ubicacion
    db.commit()
    db.refresh(farm)
    return farm


@router.post("/{farm_id}/activate", response_model=FarmRead)
def activate_farm(farm_id: int, db: Session = Depends(get_db), user: User = Depends(require_admin)):
    """Cambia la finca con la que trabaja el administrador (dashboard y módulos)."""
    farm = get_owned_farm(db, user, farm_id)
    user.farm_id = farm.id
    db.commit()
    db.refresh(farm)
    return farm


@router.get("/{farm_id}", response_model=FarmRead)
def get_farm(farm_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    return get_authorized_farm(db, user, farm_id)


@router.get("/{farm_id}/summary", response_model=FarmSummary)
def farm_summary(farm_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    """Animales activos por estado y total de eventos de la finca."""
    get_authorized_farm(db, user, farm_id)

    filas = db.execute(
        select(Animal.status, func.count(Animal.id))
        .where(Animal.finca_id == farm_id, Animal.is_active.is_(True))
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
