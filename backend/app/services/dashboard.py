"""Indicadores del inicio del dashboard para la finca activa.

Solo devuelve totales, por eso está disponible para cualquier usuario de la
finca aunque no tenga permiso sobre cada módulo.
"""
from collections import Counter
from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Animal, CattleGender, CattleStatus, Farm, ProductionRecord
from app.routers.breeding import farm_breeding_records
from app.routers.health_records import farm_health_records, health_status, to_date, to_datetime
from app.routers.inventory import farm_inventory
from app.schemas import DashboardSummary

# Ventana para los promedios de producción y los partos próximos.
WINDOW_DAYS = 30


def _round(value: float) -> float:
    return round(value, 2)


def build_dashboard_summary(db: Session, farm: Farm, today: date | None = None) -> DashboardSummary:
    today = today or date.today()
    since = today - timedelta(days=WINDOW_DAYS)

    # Solo los animales que siguen en la finca (sin venta ni muerte registrada).
    animals = db.scalars(
        select(Animal).where(
            Animal.finca_id == farm.id,
            Animal.is_active.is_(True),
            Animal.status == CattleStatus.ACTIVO,
        )
    ).all()
    active_ids = {a.id for a in animals}
    genders = Counter(a.gender for a in animals)
    weights = [float(a.current_weight) for a in animals]

    # Sanidad: tratamientos en curso y estado de la última aplicación de cada
    # vacuna por animal (una vacuna renovada no debe seguir generando alertas).
    in_treatment: set[int] = set()
    latest_vaccines = {}
    for record, animal in farm_health_records(db, farm.id):
        if animal.id not in active_ids:
            continue
        if record.record_type == "TRATAMIENTO":
            if health_status(record, today) == "EN_TRATAMIENTO":
                in_treatment.add(animal.id)
            continue
        key = (animal.id, (record.diagnosis or "").strip().lower())
        current = latest_vaccines.get(key)
        if current is None or record.recorded_at > current.recorded_at:
            latest_vaccines[key] = record
    vaccine_status = Counter(health_status(r, today) for r in latest_vaccines.values())

    # Reproducción: vacas cuyo último evento es una preñez.
    latest_event = {}
    for record, animal in farm_breeding_records(db, farm.id):
        if animal.id not in active_ids:
            continue
        current = latest_event.get(animal.id)
        if current is None or record.recorded_at > current.recorded_at:
            latest_event[animal.id] = record
    pregnant = [r for r in latest_event.values() if r.record_type == "PRENEZ"]
    births_soon = sum(
        1 for r in pregnant
        if r.expected_at is not None and today <= to_date(r.expected_at) <= today + timedelta(days=WINDOW_DAYS)
    )

    # Producción de leche de los últimos 30 días.
    milk = [
        float(q) for q in db.scalars(
            select(ProductionRecord.quantity)
            .join(Animal, Animal.id == ProductionRecord.animal_id)
            .where(
                Animal.finca_id == farm.id,
                ProductionRecord.record_type == "MILK",
                ProductionRecord.recorded_at >= to_datetime(since),
            )
        ).all()
    ]

    low_stock = sum(1 for item, quantity in farm_inventory(db, farm.id)
                    if quantity < item.minimum_quantity)
    due_soon = vaccine_status.get("PROXIMO_A_VENCER", 0)
    overdue = vaccine_status.get("VENCIDO", 0)

    return DashboardSummary(
        farm_id=farm.id,
        farm_name=farm.name,
        total_animales=len(animals),
        hembras=genders.get(CattleGender.HEMBRA, 0),
        machos=genders.get(CattleGender.MACHO, 0),
        peso_promedio_kg=_round(sum(weights) / len(weights)) if weights else None,
        animales_en_tratamiento=len(in_treatment),
        vacunas_por_vencer=due_soon,
        vacunas_vencidas=overdue,
        vacas_gestantes=len(pregnant),
        partos_proximos=births_soon,
        leche_litros_30_dias=_round(sum(milk)),
        leche_promedio_ordeno=_round(sum(milk) / len(milk)) if milk else None,
        insumos_bajo_minimo=low_stock,
        alertas=due_soon + overdue + low_stock,
    )
