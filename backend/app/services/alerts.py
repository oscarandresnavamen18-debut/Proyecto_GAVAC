
"""Alarmas de la finca: vacunas, partos e insumos que requieren atención.

Se calculan con los datos actuales y desaparecen cuando se resuelven.
"""
from datetime import date, timedelta
from typing import Callable

from sqlalchemy.orm import Session

from app.models import Animal, BreedingRecord, CattleStatus, HealthRecord
from app.routers.breeding import farm_breeding_records
from app.routers.health_records import farm_health_records, health_status, to_date
from app.routers.inventory import farm_inventory
from app.schemas import AlertRead


BIRTH_WINDOW_DAYS = 30

SEVERITY_ORDER = {"ALTA": 0, "MEDIA": 1}


def _days(n: int) -> str:
    return f"{n} {'día' if n == 1 else 'días'}"


def _fmt(value: date) -> str:
    return value.strftime("%d/%m/%Y")


def _vaccine_alerts(
    db: Session,
    farm_id: int,
    today: date,
) -> list[AlertRead]:
    """Genera alarmas según la última aplicación de cada vacuna por animal."""
    latest: dict[tuple[int, str], tuple[HealthRecord, Animal]] = {}

    for record, animal in farm_health_records(db, farm_id):
        if record.record_type != "VACUNA" or animal.status != CattleStatus.ACTIVO:
            continue

        vaccine_name = (record.diagnosis or "").strip().lower()
        key = (animal.id, vaccine_name)

        if key not in latest:
            latest[key] = (record, animal)

    alerts = []

    for record, animal in latest.values():
        current_status = health_status(record, today)
        due = to_date(record.next_check_at)

        if due is None:
            continue

        if current_status == "VENCIDO":
            alerts.append(
                AlertRead(
                    key=f"vacuna_vencida:{record.id}",
                    tipo="VACUNA_VENCIDA",
                    severidad="ALTA",
                    titulo=f"Vacuna vencida: {record.diagnosis} · {animal.tag_id}",
                    detalle=f"Venció el {_fmt(due)} (hace {_days((today - due).days)}).",
                    fecha=due,
                    modulo="sanidad",
                )
            )
        elif current_status == "PROXIMO_A_VENCER":
            left = (due - today).days
            remaining = "hoy" if left == 0 else f"en {_days(left)}"

            alerts.append(
                AlertRead(
                    key=f"vacuna_por_vencer:{record.id}",
                    tipo="VACUNA_POR_VENCER",
                    severidad="MEDIA",
                    titulo=f"Vacuna por vencer: {record.diagnosis} · {animal.tag_id}",
                    detalle=f"Vence el {_fmt(due)} ({remaining}).",
                    fecha=due,
                    modulo="sanidad",
                )
            )

    return alerts


def _birth_alerts(
    db: Session,
    farm_id: int,
    today: date,
) -> list[AlertRead]:
    """Genera alarmas de partos vencidos o próximos."""
    latest: dict[int, tuple[BreedingRecord, Animal]] = {}

    for record, animal in farm_breeding_records(db, farm_id):
        if animal.status != CattleStatus.ACTIVO:
            continue

        if animal.id not in latest:
            latest[animal.id] = (record, animal)

    alerts = []

    for record, animal in latest.values():
        expected = to_date(record.expected_at)

        if record.record_type != "PRENEZ" or expected is None:
            continue

        if expected < today:
            alerts.append(
                AlertRead(
                    key=f"parto_vencido:{record.id}",
                    tipo="PARTO_VENCIDO",
                    severidad="ALTA",
                    titulo=f"Parto sin registrar · {animal.tag_id}",
                    detalle=f"Se esperaba el {_fmt(expected)}. Verifica y registra el parto.",
                    fecha=expected,
                    modulo="reproduccion",
                )
            )
        elif expected <= today + timedelta(days=BIRTH_WINDOW_DAYS):
            left = (expected - today).days
            remaining = "hoy" if left == 0 else f"en {_days(left)}"

            alerts.append(
                AlertRead(
                    key=f"parto_proximo:{record.id}",
                    tipo="PARTO_PROXIMO",
                    severidad="MEDIA",
                    titulo=f"Parto próximo · {animal.tag_id}",
                    detalle=f"Fecha estimada: {_fmt(expected)} ({remaining}).",
                    fecha=expected,
                    modulo="reproduccion",
                )
            )

    return alerts


def _inventory_alerts(
    db: Session,
    farm_id: int,
    today: date,
) -> list[AlertRead]:
    """Genera alarmas de insumos agotados o por debajo del mínimo."""
    alerts = []

    for item, quantity in farm_inventory(db, farm_id):
        if quantity <= 0:
            alerts.append(
                AlertRead(
                    key=f"insumo_agotado:{item.id}",
                    tipo="INSUMO_AGOTADO",
                    severidad="ALTA",
                    titulo=f"Insumo agotado: {item.name}",
                    detalle="No quedan existencias.",
                    modulo="insumos",
                )
            )
        elif quantity < item.minimum_quantity:
            alerts.append(
                AlertRead(
                    key=f"insumo_bajo_minimo:{item.id}",
                    tipo="INSUMO_BAJO_MINIMO",
                    severidad="MEDIA",
                    titulo=f"Insumo bajo el mínimo: {item.name}",
                    detalle=(
                        f"Quedan {float(quantity):g} {item.unit}; "
                        f"el mínimo es {float(item.minimum_quantity):g}."
                    ),
                    modulo="insumos",
                )
            )

    return alerts


SOURCES: dict[str, Callable[[Session, int, date], list[AlertRead]]] = {
    "sanidad": _vaccine_alerts,
    "reproduccion": _birth_alerts,
    "insumos": _inventory_alerts,
}


def build_alerts(
    db: Session,
    farm_id: int,
    allowed: Callable[[str], bool],
    today: date | None = None,
) -> list[AlertRead]:
    """Genera alarmas autorizadas y las ordena por gravedad y fecha."""
    current_date = today or date.today()

    alerts = [
        alert
        for module, source in SOURCES.items()
        if allowed(module)
        for alert in source(db, farm_id, current_date)
    ]

    return sorted(
        alerts,
        key=lambda alert: (
            SEVERITY_ORDER.get(alert.severidad, 99),
            alert.fecha or current_date,
            alert.titulo,
        ),
    )
