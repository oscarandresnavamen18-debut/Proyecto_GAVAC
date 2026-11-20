from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.deps import current_user
from app.core.permissions import has_module
from app.models import User
from app.schemas import AlertRead
from app.services.alerts import build_alerts

router = APIRouter(prefix="/api/v1/alerts", tags=["Alarmas"])


@router.get("", response_model=list[AlertRead])
def list_alerts(db: Session = Depends(get_db), user: User = Depends(current_user)):
    """Alarmas de la finca activa, solo de los módulos que el usuario tiene permitidos."""
    if user.farm_id is None:
        return []
    return build_alerts(db, user.farm_id, lambda module: has_module(user, module))
