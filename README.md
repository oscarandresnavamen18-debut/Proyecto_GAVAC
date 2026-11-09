# GAVAC - Sistema de Gestion Ganadera (Railway + Flutter Bloc)

Plataforma integral para el control de inventario bovino, eventos sanitarios, trazabilidad reproductiva y reportes de campo.

--------------------------------------------------------------------------------

## Stack Tecnológico Oficial

- Backend: Python 3.12+ / FastAPI / SQLAlchemy 2.0 / Alembic.
- Base de Datos: PostgreSQL 16 (Containerizado en Railway / Docker Compose).
- Mobile App: Flutter (Dart) con Material 3 y cliente HTTP adaptativo.
- Infraestructura: Docker Compose (Desarrollo local) y Railway (Despliegue de producción).

--------------------------------------------------------------------------------

## 🚀 Mejoras y Correcciones Recientes

1. **Corrección de Visibilidad en Pantalla de Registro (`register_screen.dart`)**:
   - Se añadió un estilo de texto explícito (`color: GavacColors.textPrimary`) en los campos de entrada (`TextFormField`), resolviendo el problema donde las letras typed se volvían invisibles (texto blanco sobre fondo claro).
   - Se integró `ApiClient.baseUrl` dinámico (`localhost:8001` para Web y `10.0.2.2:8001` para Emulador Android) evitando errores de tiempo de espera (`ERR_CONNECTION_TIMED_OUT`).

2. **Alineación de Modelos Backend y Pydantic (`FastAPI` + `SQLAlchemy`)**:
   - Corrección de consultas y mapeos en el modelo `Animal` (`finca_id` en lugar de `farm_id`).
   - Ajuste en los eventos sanitarios (`CattleEvent`) para requerir `event_date`, `performed_by_id` y evitar conflictos con nombres de columnas.
   - Corrección de la validación reCAPTCHA (`recaptcha.py`) reemplazando el string `'isinstance'` por la función nativa `isinstance()`.

3. **Suite de Pruebas Automatizadas (100% Verde)**:
   - Actualización de los payloads de prueba (`test_animals.py`, `test_events.py`, `test_extras.py`, `test_security_isolation.py`, `test_migrations.py`) para cumplir estrictamente con los esquemas Pydantic (`AnimalCreate`, `EventCreate`).
   - Resultado: **38/38 pruebas pasadas exitosamente con `pytest`**.

--------------------------------------------------------------------------------

## Reglas de Desarrollo y Arquitectura

1. Base de Datos Unificada: Toda la persistencia reside en la instancia PostgreSQL de Railway/Docker. Queda descartado el uso de Supabase.
2. Inmutabilidad y Trazabilidad (Pilar I): Ningún evento crítico (animales, pesajes, tratamientos) se elimina físicamente (DELETE). Se utiliza soft-delete (`deleted_at`) o registros de ajuste.
3. Móvil (Flutter):
   - Separación estricta entre capa de UI (Widgets), Lógica de Negocio y Repositorios (Data/API Provider).
4. Boveda de Documentos (Pilar II): Archivos sanitarios e impresiones de hierro se sirven mediante almacenamiento privado con enlaces firmados temporales.

--------------------------------------------------------------------------------

## Inicio Rápido (Entorno Local)

1. Crear la configuración local (no subir `.env` al repositorio):
   ```powershell
   Copy-Item .env.example .env
   ```
   Edita `.env`: establece `POSTGRES_PASSWORD` y asigna a `JWT_SECRET_KEY` una clave secreta de al menos 32 caracteres.

2. Construir y levantar los servicios:
   ```bash
   docker compose up -d --build
   ```
   - API FastAPI: http://localhost:8001/docs
   - PostgreSQL Local: localhost:5433 (usuario: `ganadero`, bd: `gestion_ganadera`).
   - El código de `backend/` está montado en el contenedor y Uvicorn usa recarga automática al guardar cambios.
   - Esta configuración usa el volumen nuevo `postgres_api_data`. La base antigua (puerto 5432 / volumen `postgres_data`) no se modifica ni se migra automáticamente.

3. Reconstruir y recrear los contenedores después de cambios en dependencias o en Docker:
   ```bash
   docker compose up -d --build --force-recreate
   ```
   Este comando conserva el volumen `postgres_api_data`. No uses `docker compose down -v`, porque eliminaría los datos de la base nueva. La base antigua se conserva aparte. Para revisar el inicio y los errores:
   ```bash
   docker compose logs -f api
   ```

4. Ejecutar Cliente Móvil (Flutter):
   ```bash
   cd mobile
   flutter pub get
   flutter run
   ```

--------------------------------------------------------------------------------

## Equipo y Responsabilidades

- Jorge Botero: Backend, API, Base de Datos y Estabilidad (FastAPI / PostgreSQL / Docker / Railway)
- Oscar Navarro: Lider / Modulo Cattle
- Juan Herrera: Modulo Auth & Testing
- Elian Martínez: Frontend / Adaptabilidad
