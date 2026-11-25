import os
import sys
from datetime import date, datetime, timezone

from app.core.db import SessionLocal
from app.core.security import hash_password
from app.models import Animal, Farm, InventoryItem, InventoryMovement, Lot, User


def _config():
    """Lee la configuración del seed desde variables de entorno.

    En desarrollo usa credenciales de prueba. En producción exige una
    contraseña explícita y una confirmación, y no carga datos de ejemplo.
    """
    production = os.getenv("ENVIRONMENT", "development").lower() == "production"
    admin_email = os.getenv("SEED_ADMIN_EMAIL", "admin@ganadera.com")
    admin_password = os.getenv("SEED_ADMIN_PASSWORD")
    worker_password = os.getenv("SEED_WORKER_PASSWORD")

    if production:
        if os.getenv("ALLOW_SEED_IN_PRODUCTION") != "1":
            sys.exit("Seed bloqueado en produccion. Define ALLOW_SEED_IN_PRODUCTION=1 para continuar.")
        if not admin_password or len(admin_password) < 12:
            sys.exit("En produccion define SEED_ADMIN_PASSWORD (minimo 12 caracteres).")
    else:
        admin_password = admin_password or "Password123Secure!"
        worker_password = worker_password or "Password123Secure!"

    return {
        "production": production,
        "admin_email": admin_email,
        "admin_password": admin_password,
        "worker_password": worker_password,
    }


def seed():
    cfg = _config()
    db = SessionLocal()
    try:
        print("🌱 Iniciando inserción de datos de prueba...")

        # 1. Crear / Obtener Usuario Admin primero (para usar su ID como owner_id de la finca)
        admin = db.query(User).filter(User.email == cfg["admin_email"]).first()
        if not admin:
            admin = User(
                email=cfg["admin_email"],
                full_name="Administrador GAVAC",
                hashed_password=hash_password(cfg["admin_password"]),
                role="ADMIN",
                farm_id=None,
                is_active=True,
            )
            db.add(admin)
            db.commit()
            db.refresh(admin)
            print(f"✅ Usuario ADMIN creado: {cfg['admin_email']}")

        # 2. Crear Finca de prueba vinculada al admin como dueño
        farm = db.query(Farm).filter(Farm.name == "Hacienda El Paraíso").first()
        if not farm:
            farm = Farm(
                name="Hacienda El Paraíso",
                location="Vía Principal Km 5",
                owner_id=admin.id,
            )
            db.add(farm)
            db.commit()
            db.refresh(farm)
            print(f"✅ Finca creada: {farm.name} (ID: {farm.id})")
        else:
            print(f"ℹ️ Finca ya existe: {farm.name} (ID: {farm.id})")

        # Vincular la finca al usuario admin si no la tiene asignada
        if admin.farm_id != farm.id:
            admin.farm_id = farm.id
            db.commit()

        if cfg["production"]:
            print("🎉 Datos base listos (admin y finca). No se cargan datos de ejemplo en produccion.")
            return

        # 3. Crear Usuario Trabajador
        worker = db.query(User).filter(User.email == "worker@ganadera.com").first()
        if not worker:
            worker = User(
                email="worker@ganadera.com",
                full_name="Trabajador de Campo",
                hashed_password=hash_password(cfg["worker_password"]),
                role="MAYORDOMO",
                farm_id=farm.id,
                is_active=True,
            )
            db.add(worker)
            db.commit()
            print("✅ Usuario Trabajador creado: worker@ganadera.com")

        # 4. Crear Potreros (Lotes) - Al menos 2
        lotes_nombres = ["Lote Norte", "Lote Sur"]
        lote_objs = []
        for nombre in lotes_nombres:
            lote = db.query(Lot).filter(Lot.farm_id == farm.id, Lot.name == nombre).first()
            if not lote:
                lote = Lot(
                    farm_id=farm.id,
                    name=nombre,
                    description=f"Potrero de prueba {nombre}",
                    area_hectares=10.5,
                    is_active=True,
                )
                db.add(lote)
                db.commit()
                db.refresh(lote)
                print(f"✅ Potrero creado: {nombre}")
            lote_objs.append(lote)

        # 5. Crear Animales - Al menos 2
        animales_data = [
            {"tag_id": "B-001", "name": "Margarita", "gender": "HEMBRA", "breed": "Holstein", "weight": 420.0, "lote_id": lote_objs[0].id},
            {"tag_id": "B-002", "name": "El Rayo", "gender": "MACHO", "breed": "Brahman", "weight": 510.0, "lote_id": lote_objs[1].id},
        ]
        animal_objs = []
        for data in animales_data:
            animal = db.query(Animal).filter(Animal.finca_id == farm.id, Animal.tag_id == data["tag_id"]).first()
            if not animal:
                animal = Animal(
                    finca_id=farm.id,
                    tag_id=data["tag_id"],
                    name=data["name"],
                    gender=data["gender"],
                    birth_date=date(2022, 1, 15),
                    breed=data["breed"],
                    color="Blanco",
                    current_weight=data["weight"],
                    status="ACTIVO",
                    lote_id=data["lote_id"],
                )
                db.add(animal)
                db.commit()
                db.refresh(animal)
                print(f"✅ Animal creado: {data['name']} ({data['tag_id']})")
            animal_objs.append(animal)

        # 6. Crear Insumos / Inventario - Al menos 2
        insumos_data = [
            {"name": "Sal Mineralizada", "category": "Suplementos", "quantity": 10.0, "unit": "bultos"},
            {"name": "Vacuna Aftosa", "category": "Medicamentos", "quantity": 50.0, "unit": "dosis"},
        ]
        for ins in insumos_data:
            item = db.query(InventoryItem).filter(InventoryItem.farm_id == farm.id, InventoryItem.name == ins["name"]).first()
            if not item:
                item = InventoryItem(
                    farm_id=farm.id,
                    name=ins["name"],
                    category=ins["category"],
                    unit=ins["unit"],
                    minimum_quantity=5.0,
                    is_active=True,
                )
                db.add(item)
                db.commit()
                db.refresh(item)

                movimiento = InventoryMovement(
                    item_id=item.id,
                    movement_type="IN",
                    quantity=ins["quantity"],
                    recorded_at=datetime.now(timezone.utc),
                    notes="Carga inicial de prueba",
                )
                db.add(movimiento)
                db.commit()
                print(f"✅ Insumo creado: {ins['name']} ({ins['quantity']} {ins['unit']})")

        print("🎉 ¡Datos de prueba insertados con éxito en cada sección!")
    except Exception as e:
        db.rollback()
        print(f"❌ Error al insertar datos: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed()
