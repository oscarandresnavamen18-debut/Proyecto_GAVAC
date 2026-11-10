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
- `app/routers/` agrupa los endpoints por dominio: autenticación, fincas, animales, eventos y funcionalidades adicionales.
- `app/models.py` define los modelos SQLAlchemy.
- `app/schemas.py` define los esquemas Pydantic de entrada y salida.
- `app/config.py`, `app/db.py`, `app/deps.py` y `app/security.py` reúnen configuración, acceso a datos, dependencias y seguridad.
- `alembic/versions/` contiene las migraciones de base de datos.
- `tests/` contiene pruebas automatizadas; estas usan SQLite en memoria y no deben conectarse a una base remota.

La aplicación es un backend FastAPI único, organizado por módulos de dominio. La extracción de lógica de negocio a servicios separados puede hacerse gradualmente y acompañarse por pruebas.

## Aplicación móvil

El cliente Flutter está en `mobile/`:

- `lib/core/` contiene componentes compartidos, como tema, utilidades y cliente HTTP.
- `lib/features/` agrupa funcionalidades de administración, autenticación, dashboard, animales, inventario, fincas, sanidad, reproducción, producción y reportes.
- Cada funcionalidad mantiene sus pantallas, servicios y modelos dentro de su propio módulo.
- `test/` contiene pruebas de widgets.

La aplicación usa Material 3. No se debe asumir una arquitectura BLoC: el estado debe documentarse según la implementación real de cada funcionalidad.

El cliente configura la URL de la API en `lib/core/network/api_client.dart`: usa `localhost:8001` en web y escritorio, `10.0.2.2:8001` en el emulador Android. En web se puede definir `API_BASE_URL` mediante `--dart-define`.

## Base de datos y migraciones

PostgreSQL es el motor usado por Docker Compose. Las migraciones se administran con Alembic en `backend/alembic/`; todo cambio de esquema debe incluir su migración y pruebas correspondientes.

## Validación

- Backend: `python -m pytest -q` desde `backend/`.
- Migraciones: `alembic heads` desde `backend/`.
- Flutter: `flutter analyze` y `flutter test` desde `mobile/`.

Los detalles de configuración local están en el [README principal](../README.md); los endpoints se documentan en el [contrato de API](CONTRATO_API.md).
