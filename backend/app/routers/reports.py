
from datetime import date
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.deps import current_user
from app.models import Farm, User, UserRole
from app.services.reports import (
    REPORTS,
    build_general,
    build_report,
    render_general_pdf,
    render_general_xlsx,
    render_pdf,
    render_xlsx,
)

router = APIRouter(prefix="/api/v1/reports", tags=["Reportes"])

MEDIA_TYPES = {
    "pdf": "application/pdf",
    "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
}


@router.get("/{report}")
def download_report(
    report: Literal["general", "animales", "potreros", "salidas", "sanidad", "reproduccion",
                    "produccion", "insumos"],
    formato: Literal["pdf", "xlsx"] = Query("pdf"),
    db: Session = Depends(get_db),
    user: User = Depends(current_user),
):
    """Exporta reportes PDF o Excel exclusivamente para administradores."""
    if user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Los reportes administrativos son exclusivos del administrador",
        )

    farm = db.get(Farm, user.farm_id) if user.farm_id is not None else None
    if farm is None:
        farm = db.scalar(
            Session.query(Farm).filter(Farm.owner_id == user.id)
        ) if False else None

    if farm is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No estás asociado a ninguna finca",
        )

    if report == "general":
        reports = build_general(db, farm.id, lambda module: True)
        if not reports:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No hay reportes disponibles",
            )
        content = (
            render_general_pdf(reports, farm.name)
            if formato == "pdf"
            else render_general_xlsx(reports, farm.name)
        )
    else:
        data = build_report(db, report, farm.id)
        content = (
            render_pdf(data, farm.name)
            if formato == "pdf"
            else render_xlsx(data, farm.name)
        )

    filename = f"gavac_{report}_{date.today().isoformat()}.{formato}"
    return Response(
        content=content,
        media_type=MEDIA_TYPES[formato],
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
