
"""Indicadores del inicio del dashboard para la finca activa."""
from collections import Counter
from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Animal, CattleGender, CattleStatus, Farm, ProductionRecord
from app.routers.breeding import farm_breeding_records
from app.routers.health_records import farm_health_records, health_status, to_date, to_datetime
from app.routers.inventory import farm_inventory
from app.schemas import DashboardSummary

WINDOW_DAYS = 30


def _round(value: float) -> float:
    return round(value, 2)


def build_dashboard_summary(
    db: Session,
    farm: Farm,
    today: date | None = None,
    allowed_modules: set[str] | frozenset[str] = frozenset(),
) -> DashboardSummary:
    today = today or date.today()
    since = today - timedelta(days=WINDOW_DAYS)

    animals = db.scalars(
        select(Animal).where(
            Animal.finca_id == farm.id,
            Animal.is_active.is_(True),
            Animal.status == CattleStatus.ACTIVO,
        )
    ).all()

    active_ids = {animal.id for animal in animals}
    genders = Counter(animal.gender for animal in animals)
    weights = [float(animal.current_weight) for animal in animals]

    due_soon = 0
    overdue = 0
    in_treatment = 0

    if "sanidad" in allowed_modules:
        latest_vaccines = {}
        treated_animals = set()

        for record, animal in farm_health_records(db, farm.id):
            if animal.id not in active_ids:
                continue

            if record.record_type == "TRATAMIENTO":
                if health_status(record, today) == "EN_TRATAMIENTO":
                    treated_animals.add(animal.id)
                continue

            key = (animal.id, (record.diagnosis or "").strip().lower())
            current = latest_vaccines.get(key)

            if current is None or record.recorded_at > current.recorded_at:
                latest_vaccines[key] = record

        vaccine_status = Counter(
            health_status(record, today)
            for record in latest_vaccines.values()
        )

        due_soon = vaccine_status.get("PROXIMO_A_VENCER", 0)
        overdue = vaccine_status.get("VENCIDO", 0)
        in_treatment = len(treated_animals)

    pregnant = []
    births_soon = 0

    if "reproduccion" in allowed_modules:
        latest_events = {}

        for record, animal in farm_breeding_records(db, farm.id):
            if animal.id not in active_ids:
                continue

            current = latest_events.get(animal.id)

            if current is None or record.recorded_at > current.recorded_at:
                latest_events[animal.id] = record

        pregnant = [
            record
            for record in latest_events.values()
            if record.record_type == "PRENEZ"
        ]

        births_soon = sum(
            1
            for record in pregnant
            if record.expected_at is not None
            and today <= to_date(record.expected_at) <= today + timedelta(days=WINDOW_DAYS)
        )

    milk = []

    if "produccion" in allowed_modules:
        milk = [
            float(quantity)
            for quantity in db.scalars(
                select(ProductionRecord.quantity)
                .join(Animal, Animal.id == ProductionRecord.animal_id)
                .where(
                    Animal.finca_id == farm.id,
                    ProductionRecord.record_type == "MILK",
                    ProductionRecord.recorded_at >= to_datetime(since),
                )
            ).all()
        ]

    low_stock = 0

    if "insumos" in allowed_modules:
        low_stock = sum(
            1
            for item, quantity in farm_inventory(db, farm.id)
            if quantity < item.minimum_quantity
        )

    return DashboardSummary(
        farm_id=farm.id,
        farm_name=farm.name,
        total_animales=len(animals),
        hembras=genders.get(CattleGender.HEMBRA, 0),
        machos=genders.get(CattleGender.MACHO, 0),
        peso_promedio_kg=_round(sum(weights) / len(weights)) if weights else None,
        animales_en_tratamiento=in_treatment,
        vacunas_por_vencer=due_soon,
        vacunas_vencidas=overdue,
        vacas_gestantes=len(pregnant),
        partos_proximos=births_soon,
        leche_litros_30_dias=_round(sum(milk)),
        leche_promedio_ordeno=_round(sum(milk) / len(milk)) if milk else None,
        insumos_bajo_minimo=low_stock,
        alertas=due_soon + overdue + low_stock,
    )
