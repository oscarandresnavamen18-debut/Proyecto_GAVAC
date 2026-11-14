"""Alarmas de la finca: vacunas, partos e insumos que requieren atención.

Se calculan con los datos actuales; desaparecen solas cuando se resuelven
(por ejemplo, al registrar la nueva dosis de una vacuna o al reponer un insumo).
"""
from datetime import date, timedelta
from typing import Callable

from sqlalchemy.orm import Session

from app.models import BreedingRecord, CattleStatus, HealthRecord
from app.routers.breeding import farm_breeding_records
from app.routers.health_records import farm_health_records, health_status, to_date
from app.routers.inventory import farm_inventory
from app.schemas import AlertRead

# Partos esperados dentro de esta ventana se avisan como próximos.
BIRTH_WINDOW_DAYS = 30

SEVERITY_ORDER = {"ALTA": 0, "MEDIA": 1}


def _days(n: int) -> str:
    return f"{n} {'día' if n == 1 else 'días'}"


def _fmt(value: date) -> str:
    return value.strftime("%d/%m/%Y")


def _vaccine_alerts(db: Session, farm_id: int, today: date) -> list[AlertRead]:
    # Solo la última aplicación de cada vacuna por animal: una vacuna renovada no avisa.
    latest: dict[tuple[int, str], tuple[HealthRecord, object]] = {}
    for record, animal in farm_health_records(db, farm_id):
        if record.record_type != "VACUNA" or animal.status != CattleStatus.ACTIVO:
            continue
        key = (animal.id, (record.diagnosis or "").strip().lower())
        if key not in latest or record.recorded_at > latest[key][0].recorded_at:
            latest[key] = (record, animal)

    alerts = []
    for record, animal in latest.values():
        status = health_status(record, today)
        due = to_date(record.next_check_at)
        if status == "VENCIDO":
            alerts.append(AlertRead(
                key=f"vacuna_vencida:{record.id}",
                tipo="VACUNA_VENCIDA",
                severidad="ALTA",
                titulo=f"Vacuna vencida: {record.diagnosis} · {animal.tag_id}",
                detalle=f"Venció el {_fmt(due)} (hace {_days((today - due).days)}).",
                fecha=due,
                modulo="sanidad",
            ))
        elif status == "PROXIMO_A_VENCER":
            left = (due - today).days
            alerts.append(AlertRead(
                key=f"vacuna_por_vencer:{record.id}",
                tipo="VACUNA_POR_VENCER",
                severidad="MEDIA",
                titulo=f"Vacuna por vencer: {record.diagnosis} · {animal.tag_id}",
                detalle=f"Vence el {_fmt(due)} ({'hoy' if left == 0 else 'en ' + _days(left)}).",
                fecha=due,
                modulo="sanidad",
            ))
    return alerts


def _birth_alerts(db: Session, farm_id: int, today: date) -> list[AlertRead]:
    # Vacas cuyo último evento es una preñez con fecha de parto estimada.
    latest: dict[int, tuple[BreedingRecord, object]] = {}
    for record, animal in farm_breeding_records(db, farm_id):
        if animal.status != CattleStatus.ACTIVO:
            continue
        if animal.id not in latest or record.recorded_at > latest[animal.id][0].recorded_at:
            latest[animal.id] = (record, animal)

    alerts = []
    for record, animal in latest.values():
        expected = to_date(record.expected_at)
        if record.record_type != "PRENEZ" or expected is None:
            continue
        if expected < today:
            alerts.append(AlertRead(
                key=f"parto_vencido:{record.id}",
                tipo="PARTO_VENCIDO",
                severidad="ALTA",
                titulo=f"Parto sin registrar · {animal.tag_id}",
                detalle=f"Se esperaba el {_fmt(expected)}. Verifica y registra el parto.",
                fecha=expected,
                modulo="reproduccion",
            ))
        elif expected <= today + timedelta(days=BIRTH_WINDOW_DAYS):
            left = (expected - today).days
            alerts.append(AlertRead(
                key=f"parto_proximo:{record.id}",
                tipo="PARTO_PROXIMO",
                severidad="MEDIA",
                titulo=f"Parto próximo · {animal.tag_id}",
                detalle=f"Fecha estimada: {_fmt(expected)} ({'hoy' if left == 0 else 'en ' + _days(left)}).",
                fecha=expected,
                modulo="reproduccion",
            ))
    return alerts


def _inventory_alerts(db: Session, farm_id: int, today: date) -> list[AlertRead]:
    alerts = []
    for item, quantity in farm_inventory(db, farm_id):
        if quantity <= 0:
            alerts.append(AlertRead(
                key=f"insumo_agotado:{item.id}",
                tipo="INSUMO_AGOTADO",
                severidad="ALTA",
                titulo=f"Insumo agotado: {item.name}",
                detalle="No quedan existencias.",
                modulo="insumos",
            ))
        elif quantity < item.minimum_quantity:
            alerts.append(AlertRead(
                key=f"insumo_bajo_minimo:{item.id}",
                tipo="INSUMO_BAJO_MINIMO",
                severidad="MEDIA",
                titulo=f"Insumo bajo el mínimo: {item.name}",
                detalle=f"Quedan {float(quantity):g} {item.unit}; el mínimo es "
                        f"{float(item.minimum_quantity):g}.",
                modulo="insumos",
            ))
    return alerts


# módulo de permiso -> generador de alarmas
SOURCES: dict[str, Callable[[Session, int, date], list[AlertRead]]] = {
    "sanidad": _vaccine_alerts,
    "reproduccion": _birth_alerts,
    "insumos": _inventory_alerts,
}


def build_alerts(
    db: Session, farm_id: int, allowed: Callable[[str], bool], today: date | None = None,
) -> list[AlertRead]:
    """Alarmas de los módulos permitidos: primero las de gravedad alta y las más antiguas."""
    today = today or date.today()
    alerts = [
        alert
        for module, source in SOURCES.items() if allowed(module)
        for alert in source(db, farm_id, today)
    ]
    return sorted(alerts, key=lambda a: (SEVERITY_ORDER[a.severidad], a.fecha or today, a.titulo))
