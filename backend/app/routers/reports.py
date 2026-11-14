from datetime import date
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.deps import require_module
from app.models import Farm, User
from app.core.permissions import has_module
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
    report: Literal["general", "animales", "sanidad", "reproduccion", "produccion", "insumos"],
    formato: Literal["pdf", "xlsx"] = Query("pdf"),
    db: Session = Depends(get_db),
    user: User = Depends(require_module("reportes")),
):
    """Exporta en PDF o Excel un módulo, o el resumen general de la finca activa.

    El resumen general incluye solo los módulos que el usuario tiene habilitados.
    """
    farm = db.get(Farm, user.farm_id) if user.farm_id is not None else None
    if farm is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "No estás asociado a ninguna finca")

    if report == "general":
        reports = build_general(db, farm.id, lambda module: has_module(user, module))
        if not reports:
            raise HTTPException(
                status.HTTP_403_FORBIDDEN, "No tienes módulos habilitados para el resumen")
        content = (render_general_pdf(reports, farm.name) if formato == "pdf"
                   else render_general_xlsx(reports, farm.name))
    else:
        module = REPORTS[report][0]
        if not has_module(user, module):
            raise HTTPException(
                status.HTTP_403_FORBIDDEN, f"No tienes permiso para el módulo de {module}")
        data = build_report(db, report, farm.id)
        content = render_pdf(data, farm.name) if formato == "pdf" else render_xlsx(data, farm.name)

    filename = f"gavac_{report}_{date.today().isoformat()}.{formato}"
    return Response(
        content=content,
        media_type=MEDIA_TYPES[formato],
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
