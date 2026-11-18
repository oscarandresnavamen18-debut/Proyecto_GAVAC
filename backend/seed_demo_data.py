from app.core.db import SessionLocal
from app.models import Farm, User, Animal, Lot, InventoryItem
from app.core.security import hash_password
from datetime import date

def seed():
    db = SessionLocal()
    try:
        print("🌱 Iniciando inserción de datos de prueba...")

        # 1. Crear Finca de prueba
        farm = db.query(Farm).filter(Farm.name == "Hacienda El Paraíso").first()
        if not farm:
            farm = Farm(name="Hacienda El Paraíso", location="Vía Principal Km 5")
            db.add(farm)
            db.commit()
            db.refresh(farm)
            print(f"✅ Finca creada: {farm.name} (ID: {farm.id})")
        else:
            print(f"ℹ️ Finca ya existe: {farm.name} (ID: {farm.id})")

        # 2. Crear Usuarios de prueba (Admin y Trabajador)
        admin = db.query(User).filter(User.email == "admin@ganadera.com").first()
        if not admin:
            admin = User(
                email="admin@ganadera.com",
                full_name="Administrador GAVAC",
                hashed_password=hash_password("Password123Secure!"),
                role="ADMIN",
                farm_id=farm.id,
                is_active=True
            )
            db.add(admin)
            print("✅ Usuario ADMIN creado: admin@ganadera.com / Password123Secure!")

        worker = db.query(User).filter(User.email == "worker@ganadera.com").first()
        if not worker:
            worker = User(
                email="worker@ganadera.com",
                full_name="Trabajador de Campo",
                hashed_password=hash_password("Password123Secure!"),
                role="MAYORDOMO",
                farm_id=farm.id,
                is_active=True
            )
            db.add(worker)
            print("✅ Usuario Trabajador creado: worker@ganadera.com / Password123Secure!")

        db.commit()

        # 3. Crear Potreros (Lotes) - Al menos 2
        lotes_nombres = ["Lote Norte", "Lote Sur"]
        lote_objs = []
        for nombre in lotes_nombres:
            lote = db.query(Lot).filter(Lot.farm_id == farm.id, Lot.name == nombre).first()
            if not lote:
                lote = Lot(farm_id=farm.id, name=nombre, description=f"Potrero de prueba {nombre}", area_hectares=10.5, is_active=True)
                db.add(lote)
                db.commit()
                db.refresh(lote)
                print(f"✅ Potrero creado: {nombre}")
            lote_objs.append(lote)

        # 4. Crear Animales - Al menos 2
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
                    lote_id=data["lote_id"]
                )
                db.add(animal)
                db.commit()
                db.refresh(animal)
                print(f"✅ Animal creado: {data['name']} ({data['tag_id']})")
            animal_objs.append(animal)

        # 5. Crear Insumos / Inventario - Al menos 2
        insumos_data = [
            {"name": "Sal Mineralizada", "quantity": 10.0, "unit": "bultos"},
            {"name": "Vacuna Aftosa", "quantity": 50.0, "unit": "dosis"},
        ]
        for ins in insumos_data:
            existente = db.query(InventoryItem).filter(InventoryItem.farm_id == farm.id, InventoryItem.name == ins["name"]).first()
            if not existente:
                item = InventoryItem(
                    farm_id=farm.id,
                    name=ins["name"],
                    quantity=ins["quantity"],
                    unit=ins["unit"],
                    min_stock=5.0
                )
                db.add(item)
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
