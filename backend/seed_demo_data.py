import os
import sys
from datetime import date, datetime, timezone

from app.core.db import SessionLocal
from app.core.security import hash_password
from app.models import Animal, Farm, InventoryItem, InventoryMovement, Lot, User, CattleGender, CattleStatus, UserRole


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
feat/seed-seguro
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

        print("🌱 Iniciando inserción de datos enriquecidos (Fincas, Administradores, Lotes y Ganado)...")

        # 1. Crear Administradores y Trabajadores
        usuarios_data = [
            {"email": "admin@ganadera.com", "full_name": "Administrador GAVAC", "role": UserRole.ADMIN, "password": "Password123Secure!"},
            {"email": "veterinario@ganadera.com", "full_name": "Dra. Sofía Martínez", "role": UserRole.VETERINARIO, "password": "Password123Secure!"},
            {"email": "mayordomo@ganadera.com", "full_name": "Carlos Pérez (Mayordomo)", "role": UserRole.MAYORDOMO, "password": "Password123Secure!"},
        ]

        users_map = {}
        for u_data in usuarios_data:
            user = db.query(User).filter(User.email == u_data["email"]).first()
            if not user:
                user = User(
                    email=u_data["email"],
                    full_name=u_data["full_name"],
                    hashed_password=hash_password(u_data["password"]),
                    role=u_data["role"], main
                    is_active=True,
                )
                db.add(user)
                db.commit()
                db.refresh(user)
                print(f"✅ Usuario creado: {user.email} ({user.role})")
            users_map[user.email] = user

        admin_user = users_map["admin@ganadera.com"]

        # 2. Crear Fincas Múltiples
        fincas_data = [
            {"name": "Hacienda El Paraíso", "location": "Vía Principal Km 5, Valle del Cauca", "owner_id": admin_user.id},
            {"name": "Finca San José", "location": "Sector Alto Bonito, Antioquia", "owner_id": admin_user.id},
            {"name": "Agropecuaria La Esperanza", "location": "Kilómetro 12 Vía al Mar, Córdoba", "owner_id": admin_user.id},
        ]

        farm_objs = []
        for f_data in fincas_data:
            farm = db.query(Farm).filter(Farm.name == f_data["name"]).first()
            if not farm:
                farm = Farm(
                    name=f_data["name"],
                    location=f_data["location"],
                    owner_id=f_data["owner_id"],
                )
                db.add(farm)
                db.commit()
                db.refresh(farm)
                print(f"✅ Finca creada: {farm.name} (ID: {farm.id})")
            farm_objs.append(farm)

        # Asignar finca por defecto al admin
        if not admin_user.farm_id:
            admin_user.farm_id = farm_objs[0].id
            db.commit()

        # 3. Crear Lotes (Potreros) por cada Finca
        lotes_por_finca = {
            "Hacienda El Paraíso": [
                {"name": "Lote Norte - Pasto Brachiaria", "description": "Potrero principal de rotación", "area": 15.0},
                {"name": "Lote Sur - Banco de Proteína", "description": "Zona de descanso con matarratón", "area": 8.5},
            ],
            "Finca San José": [
                {"name": "Potrero El Descanso", "description": "Lote montañoso con pendiente moderada", "area": 20.0},
                {"name": "Potrero La Vega", "description": "Lote plano cercano al río", "area": 12.0},
            ],
            "Agropecuaria La Esperanza": [
                {"name": "Lote A - Ganadería de Leche", "description": "Pastura estrella africana", "area": 25.0},
                {"name": "Lote B - Levante", "description": "Potrero de cría y levante", "area": 30.0},
            ]
        }

        lote_map = {}
        for farm in farm_objs:
            lotes_data = lotes_por_finca.get(farm.name, [])
            for l_data in lotes_data:
                lote = db.query(Lot).filter(Lot.farm_id == farm.id, Lot.name == l_data["name"]).first()
                if not lote:
                    lote = Lot(
                        farm_id=farm.id,
                        name=l_data["name"],
                        description=l_data["description"],
                        area_hectares=l_data["area"],
                        is_active=True,
                    )
                    db.add(lote)
                    db.commit()
                    db.refresh(lote)
                    print(f"✅ Potrero creado: {lote.name} en {farm.name}")
                lote_map[(farm.id, lote.name)] = lote

        # 4. Crear Ganado (Animales) variados
        ganado_data = [
            # Hacienda El Paraíso
            {"farm": "Hacienda El Paraíso", "tag": "PAR-001", "name": "Margarita", "gender": CattleGender.HEMBRA, "breed": "Holstein", "weight": 450.0, "lote": "Lote Norte - Pasto Brachiaria", "status": CattleStatus.ACTIVO},
            {"farm": "Hacienda El Paraíso", "tag": "PAR-002", "name": "Sultán", "gender": CattleGender.MACHO, "breed": "Brahman", "weight": 520.0, "lote": "Lote Norte - Pasto Brachiaria", "status": CattleStatus.ACTIVO},
            {"farm": "Hacienda El Paraíso", "tag": "PAR-003", "name": "Lucero", "gender": CattleGender.HEMBRA, "breed": "Jersey", "weight": 380.0, "lote": "Lote Sur - Banco de Proteína", "status": CattleStatus.ACTIVO},

            # Finca San José
            {"farm": "Finca San José", "tag": "SJ-101", "name": "Gitana", "gender": CattleGender.HEMBRA, "breed": "Gyr", "weight": 410.0, "lote": "Potrero El Descanso", "status": CattleStatus.ACTIVO},
            {"farm": "Finca San José", "tag": "SJ-102", "name": "Centauro", "gender": CattleGender.MACHO, "breed": "Angus", "weight": 560.0, "lote": "Potrero La Vega", "status": CattleStatus.ACTIVO},

            # Agropecuaria La Esperanza
            {"farm": "Agropecuaria La Esperanza", "tag": "ESP-201", "name": "Rosilla", "gender": CattleGender.HEMBRA, "breed": "Pardo Suizo", "weight": 470.0, "lote": "Lote A - Ganadería de Leche", "status": CattleStatus.ACTIVO},
            {"farm": "Agropecuaria La Esperanza", "tag": "ESP-202", "name": "Cacique", "gender": CattleGender.MACHO, "breed": "Simmental", "weight": 600.0, "lote": "Lote B - Levante", "status": CattleStatus.ACTIVO},
        ]

        for animal_info in ganado_data:
            # Encontrar finca ID
            farm_obj = next((f for f in farm_objs if f.name == animal_info["farm"]), None)
            if not farm_obj:
                continue

            # Encontrar lote ID
            lote_obj = lote_map.get((farm_obj.id, animal_info["lote"]))
            lote_id = lote_obj.id if lote_obj else None

            existing_animal = db.query(Animal).filter(Animal.tag_id == animal_info["tag"]).first()
            if not existing_animal:
                animal = Animal(
                    finca_id=farm_obj.id,
                    tag_id=animal_info["tag"],
                    name=animal_info["name"],
                    gender=animal_info["gender"],
                    birth_date=date(2021, 6, 10),
                    breed=animal_info["breed"],
                    color="overo / blanco",
                    current_weight=animal_info["weight"],
                    status=animal_info["status"],
                    lote_id=lote_id,
                    is_active=True,
                )
                db.add(animal)
                db.commit()
                print(f"✅ Animal registrado: {animal.name} (Tag: {animal.tag_id}) en {farm_obj.name}")

        # 5. Crear Insumos por Finca
        for farm in farm_objs:
            insumo_existente = db.query(InventoryItem).filter(InventoryItem.farm_id == farm.id, InventoryItem.sku == f"SAL-{farm.id}").first()
            if not insumo_existente:
                item = InventoryItem(
                    farm_id=farm.id,
                    name="Sal Mineralizada Premium",
                    category="Suplementos",
                    sku=f"SAL-{farm.id}",
                    unit="bultos",
                    minimum_quantity=5.0,
                    is_active=True,
                )
                db.add(item)
                db.commit()
                db.refresh(item)

                mov = InventoryMovement(
                    item_id=item.id,
                    movement_type="IN",
                    quantity=20.0,
                    recorded_at=datetime.now(timezone.utc),
                    notes="Inventario inicial automático",
                )
                db.add(mov)
                db.commit()
                print(f"✅ Insumo creado para {farm.name}: Sal Mineralizada")

        print("🎉 ¡Datos enriquecidos (Administradores, Fincas, Lotes y Ganado) insertados con éxito!")
    except Exception as e:
        db.rollback()
        print(f"❌ Error al insertar datos enriquecidos: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed()
