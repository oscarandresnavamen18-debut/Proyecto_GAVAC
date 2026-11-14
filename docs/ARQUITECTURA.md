# Arquitectura de GAVAC

## Vista general

GAVAC es un monorepositorio con una API FastAPI, una aplicación Flutter y un entorno local basado en Docker Compose.

```text
Aplicación Flutter
        | HTTP / JSON
        v
API FastAPI
        | SQLAlchemy / psycopg
        v
PostgreSQL
```

Docker Compose inicia PostgreSQL y la API para desarrollo local. La API ejecuta las migraciones de Alembic antes de iniciar Uvicorn.

## Backend

El backend está en `backend/`:

- `app/main.py` crea la aplicación FastAPI, configura CORS e incluye los routers.
- `app/core/` reúne la base técnica: configuración (`config.py`), sesión de base de datos (`db.py`), contraseñas y JWT (`security.py`), dependencias de FastAPI (`deps.py`: `current_user`, `require_admin`, `require_module(...)`) y permisos por módulo (`permissions.py`).
- `app/routers/` tiene un archivo por módulo: autenticación (`auth.py`, `social_auth.py`), usuarios, fincas, animales, eventos, sanidad (`health_records.py`), reproducción (`breeding.py`), producción, inventario y reportes. Cada endpoint de un módulo usa `require_module("<modulo>")`.
- `app/services/` contiene los servicios: correo (`mailer.py`), reCAPTCHA, proveedores de identidad de Google y Microsoft, y la generación de reportes en PDF (fpdf2) y Excel (openpyxl).
- `app/models.py` define los modelos SQLAlchemy y `app/schemas.py` los esquemas Pydantic.
- `alembic/versions/` contiene las migraciones de base de datos.
- `tests/` contiene pruebas automatizadas; usan SQLite en memoria y no deben conectarse a una base remota.

## Aplicación móvil

El cliente Flutter está en `mobile/`:

- `lib/core/`: lo compartido por todos los módulos.
  - `network/api_client.dart`: único punto que hace peticiones HTTP; convierte los errores en `ApiException`.
  - `routing/app_routes.dart`: rutas con nombre (`/login`, `/register`, `/dashboard`).
  - `session/app_session.dart`: token, rol, finca activa y permisos del usuario.
  - `theme/`, `utils/` (fechas, descarga de archivos) y `widgets/` comunes.
- `lib/features/<módulo>/`: un módulo por opción del menú (`auth`, `dashboard`, `animales`, `sanidad`, `reproduccion`, `produccion`, `insumos`, `reportes`, `administracion`), cada uno con:
  - `data/`: modelos y servicios. Cada servicio implementa una interfaz `...Repository` que las pruebas reemplazan por versiones falsas.
  - `presentation/`: pantallas (`screens/`) y componentes (`widgets/`).
- El dashboard solo coordina el menú lateral, la barra superior y la página del módulo seleccionado; el menú muestra únicamente los módulos permitidos y el backend vuelve a validar cada permiso.
- `test/` replica la estructura de `lib/`.

La aplicación usa Material 3 y estado local con `StatefulWidget`; no usa BLoC.

El cliente configura la URL de la API en `lib/core/network/api_client.dart`: usa `localhost:8001` en web y escritorio, `10.0.2.2:8001` en el emulador Android. En web se puede definir `API_BASE_URL` mediante `--dart-define`.

## Base de datos y migraciones

PostgreSQL es el motor usado por Docker Compose. Las migraciones se administran con Alembic en `backend/alembic/`; todo cambio de esquema debe incluir su migración y pruebas correspondientes.

## Validación

- Backend: `python -m pytest -q` desde `backend/`.
- Migraciones: `alembic heads` desde `backend/`.
- Flutter: `flutter analyze` y `flutter test` desde `mobile/`.

Los detalles de configuración local están en el [README principal](../README.md); los endpoints se documentan en el [contrato de API](CONTRATO_API.md).
