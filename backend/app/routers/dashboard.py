from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.deps import current_user
from app.models import Farm, User
from app.schemas import DashboardSummary
from app.services.dashboard import build_dashboard_summary
from app.core.permissions import effective_permissions

router = APIRouter(prefix="/api/v1/dashboard", tags=["Dashboard"])


@router.get("", response_model=DashboardSummary)
def dashboard_summary(db: Session = Depends(get_db), user: User = Depends(current_user)):
    """Indicadores de la finca activa del usuario. Si no tiene finca, todo en cero."""
    farm = db.get(Farm, user.farm_id) if user.farm_id is not None else None
    if farm is None:
        return DashboardSummary()
    return build_dashboard_summary(db, farm, allowed_modules=set(effective_permissions(user)))
