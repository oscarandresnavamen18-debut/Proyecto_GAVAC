# Arquitectura Oficial del Sistema GAVAC

## 1. Visión General
GAVAC es una plataforma moderna para la gestión de inventario ganadero, eventos sanitarios, pesajes y trazabilidad en fincas. La solución está diseñada bajo una arquitectura desacoplada con backend RESTful y frontend multiplataforma (Mobile & Web).

```
+-------------------------------------------------------------------+
|                        CLIENTES GAVAC                             |
|    Flutter (Android / Web / iOS / Desktop) - BLoC + Material 3    |
+-------------------------------------------------------------------+
                                  |
                           HTTP / REST JSON
                                  v
+-------------------------------------------------------------------+
|                        BACKEND FASTAPI                            |
|  Python 3.12 + Pydantic v2 + SQLAlchemy 2.0 (ORM) + Auth JWT      |
+-------------------------------------------------------------------+
                                  |
                      Driver psycopg3 / Connection Pool
                                  v
+-------------------------------------------------------------------+
|                      BASE DE DATOS POSTGRESQL                     |
|            PostgreSQL 16 en Railway / Docker Compose              |
+-------------------------------------------------------------------+
```

---

## 2. Componentes y Capas

### Backend (Python / FastAPI)
* **API Routers (`app/main.py` y `app/routers/ extras.py`)**: Manejo de rutas REST, inyección de dependencias (`Depends`), validación con Pydantic y autorización RBAC por finca.
* **Modelos Pydantic (`app/schemas.py`)**: Validación estricta de esquemas de entrada y salida (`RegisterIn`, `LoginIn`, `FarmCreate`, `AnimalCreate`, `AnimalPatch`, `EventCreate`, `FarmSummary`).
* **Modelos SQLAlchemy (`app/models.py`)**: Definición del esquema PostgreSQL (`users`, `farms`, `animals`, `cattle_events`, `password_reset_codes`).
* **Seguridad y Token (`app/security.py` & `deps.py`)**: Hashing con Argon2, autenticación JWT Bearer y aislamiento muti-inquilino estricto por finca.

### Frontend (Flutter / Dart)
* **Módulos de Presentación (`lib/features/`)**:
  - `auth`: Inicio de sesión (`login_screen.dart`), registro (`register_screen.dart`), recuperación de contraseña y reCAPTCHA.
  - `animals`: Inventario de ganado, registro de animales (`animales_screen.dart`) y consumo de API (`animal_api_service.dart`).
  - `sanidad`: Control de vacunas, tratamientos y pesajes (`sanidad_screen.dart`).
  - `dashboard`: Resumen de métricas y acceso rápido (`dashboard_screen.dart`).
* **Capa de Red (`lib/core/network/api_client.dart`)**:
  - Configuración automática de `baseUrl` adaptativa (`kIsWeb` -> `localhost:8001`, `Platform.isAndroid` -> `10.0.2.2:8001`, Producción -> Railway).

---

## 3. Seguridad e Invariantes
1. **Aislamiento Multi-inquilino**: Las consultas de animales y eventos imponen la restricción de que el `finca_id` pertenezca al `farm_id` del usuario autenticado.
2. **Contraseñas**: Almacenadas usando hashing criptográfico con Argon2id.
3. **Persistencia y Resiliencia DB**: Conexión a PostgreSQL con `pool_pre_ping=True` y manejo estricto de transacciones ACID (`autocommit=False` con `commit()` y `rollback()`).
