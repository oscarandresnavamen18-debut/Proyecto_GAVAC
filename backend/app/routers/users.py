from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.deps import require_admin
from app.models import Farm, User, UserRole
from app.routers.auth import user_read
from app.routers.farms import get_owned_farm
from app.schemas import ManagedUserCreate, ManagedUserUpdate, UserRead
from app.core.security import hash_password

router = APIRouter(prefix="/api/v1/users", tags=["Administración de usuarios"])


def _managed_user(db: Session, admin: User, user_id: int) -> User:
    """Veterinario o trabajador asignado a una finca del administrador."""
    user = db.get(User, user_id)
    farm = db.get(Farm, user.farm_id) if user is not None and user.farm_id else None
    if user is None or user.id == admin.id or farm is None or farm.owner_id != admin.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    return user


@router.get("", response_model=list[UserRead])
def list_users(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    query = (
        select(User)
        .join(Farm, User.farm_id == Farm.id)
        .where(Farm.owner_id == admin.id, User.id != admin.id)
        .order_by(User.id)
    )
    return [user_read(user) for user in db.scalars(query).all()]


@router.post("", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def create_user(
    data: ManagedUserCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    farm = get_owned_farm(db, admin, data.farm_id)
    user = User(
        full_name=data.nombre.strip(),
        email=str(data.email).lower(),
        hashed_password=hash_password(data.password),
        role=UserRole(data.role),
        farm_id=farm.id,
        module_permissions=[p.value for p in data.permisos] if data.permisos is not None else None,
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT,
                            detail="El correo ya está registrado")
    db.refresh(user)
    return user_read(user)


@router.patch("/{user_id}", response_model=UserRead)
def update_user(
    user_id: int,
    data: ManagedUserUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    user = _managed_user(db, admin, user_id)
    if data.nombre is not None:
        user.full_name = data.nombre.strip()
    if data.role is not None:
        user.role = UserRole(data.role)
    if data.farm_id is not None:
        user.farm_id = get_owned_farm(db, admin, data.farm_id).id
    if "permisos" in data.model_fields_set:
        user.module_permissions = [p.value for p in data.permisos] if data.permisos is not None else None
    if data.is_active is not None:
        user.is_active = data.is_active
    if data.password is not None:
        user.hashed_password = hash_password(data.password)
        # Cierra las sesiones abiertas con la contraseña anterior.
        user.token_version += 1
    db.commit()
    db.refresh(user)
    return user_read(user)
