from datetime import datetime, timezone
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import case, func, select
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import current_user
from app.models import InventoryItem, InventoryMovement, User
from app.routers.farms import get_authorized_farm
from app.schemas import InventoryCreate, InventoryRead

router = APIRouter(prefix="/api/v1/inventory", tags=["Inventario"])


def _inventory_read(item: InventoryItem, quantity: Decimal | float) -> InventoryRead:
    return InventoryRead(
        id=item.id,
        name=item.name,
        category=item.category,
        unit=item.unit,
        quantity=float(quantity),
        minimum_quantity=float(item.minimum_quantity),
        is_active=item.is_active,
        created_at=item.created_at,
    )


@router.get("", response_model=list[InventoryRead])
def list_inventory(
    db: Session = Depends(get_db),
    user: User = Depends(current_user),
):
    if user.farm_id is None:
        return []

    quantity = func.coalesce(
        func.sum(
            case(
                (InventoryMovement.movement_type == "IN", InventoryMovement.quantity),
                (InventoryMovement.movement_type == "OUT", -InventoryMovement.quantity),
                else_=0,
            )
        ),
        0,
    )
    rows = db.execute(
        select(InventoryItem, quantity)
        .outerjoin(InventoryMovement, InventoryMovement.item_id == InventoryItem.id)
        .where(
            InventoryItem.farm_id == user.farm_id,
            InventoryItem.is_active.is_(True),
        )
        .group_by(InventoryItem.id)
        .order_by(InventoryItem.name)
    ).all()
    return [_inventory_read(item, current_quantity) for item, current_quantity in rows]


@router.post("", response_model=InventoryRead, status_code=status.HTTP_201_CREATED)
def create_inventory_item(
    data: InventoryCreate,
    db: Session = Depends(get_db),
    user: User = Depends(current_user),
):
    if user.farm_id is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No estás asociado a ninguna finca",
        )
    get_authorized_farm(db, user, user.farm_id)

    item = InventoryItem(
        farm_id=user.farm_id,
        name=data.name.strip(),
        category=data.category.strip().upper(),
        unit=data.unit.strip(),
        minimum_quantity=Decimal(str(data.minimum_quantity)),
    )
    db.add(item)
    db.flush()
    initial_movement = InventoryMovement(
        item_id=item.id,
        created_by=user.id,
        movement_type="IN",
        quantity=Decimal(str(data.quantity)),
        recorded_at=datetime.now(timezone.utc),
        notes="Saldo inicial",
    )
    db.add(initial_movement)
    db.commit()
    db.refresh(item)
    return _inventory_read(item, data.quantity)


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def deactivate_inventory_item(
    item_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(current_user),
):
    item = db.get(InventoryItem, item_id)
    if item is None or not item.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Insumo no encontrado",
        )
    get_authorized_farm(db, user, item.farm_id)
    item.is_active = False
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
