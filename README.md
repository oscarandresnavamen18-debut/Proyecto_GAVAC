# GAVAC — Gestión Ganadera

Plataforma para la gestión ganadera con una API REST y una aplicación multiplataforma. El backend usa FastAPI y PostgreSQL; el cliente está desarrollado en Flutter.

## Componentes

- `backend/`: API, modelos, esquemas, autenticación, migraciones Alembic y pruebas.
- `mobile/`: aplicación Flutter para Android, iOS, web y escritorio.
- `docs/`: arquitectura, alcance, casos de uso, contrato de API y decisiones del proyecto.
- `docker-compose.yml`: entorno local para PostgreSQL y la API.
- `CONTRIBUTING.md`: flujo de ramas, revisiones y validaciones.

## Requisitos

- Docker Compose.
- Flutter 3.47 o posterior, con Dart 3.13 o posterior.
- Python 3.12 para ejecutar las pruebas del backend fuera de Docker.

## Inicio rápido

1. Crea la configuración local:

   ```powershell
   Copy-Item .env.example .env
   ```

2. Edita `.env`. Establece una contraseña para PostgreSQL y un `JWT_SECRET_KEY` aleatorio de al menos 32 caracteres. No compartas ni confirmes el archivo `.env`.

3. Inicia la base de datos y la API:

   ```powershell
   docker compose up -d --build
   ```

   La API está disponible en <http://localhost:8001/docs> y PostgreSQL en el puerto `5433`. Las migraciones se aplican al iniciar la API.

4. Inicia el cliente Flutter en otra terminal:

   ```powershell
   Set-Location mobile
   flutter pub get
   flutter run
   ```

   La URL de la API se configura en [api_client.dart](mobile/lib/core/network/api_client.dart). En Flutter Web puede reemplazarse con `--dart-define=API_BASE_URL=http://localhost:8001`.

## Validación

Backend:

```powershell
Set-Location backend
python -m pip install -r requirements-dev.txt
python -m pytest -q
alembic heads
```

Aplicación móvil:

```powershell
Set-Location mobile
flutter pub get
flutter analyze
flutter test
```
<!-- flutter run -d chrome --web-hostname localhost --web-port 5173 --dart-define=API_BASE_URL=https://proyectogavac-gavac-staging.up.railway.app -->
## Datos locales

Docker Compose conserva la base en el volumen `postgres_api_data`. Evita `docker compose down -v` si necesitas conservar esos datos. Para revisar los registros de la API:

```powershell
docker compose logs -f api
```

Consulta [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md) para el diseño del sistema y [docs/CONTRATO_API.md](docs/CONTRATO_API.md) para el contrato de la API.
Para publicar el proyecto en un repositorio nuevo, revisa [docs/CREAR_REPOSITORIO.md](docs/CREAR_REPOSITORIO.md).
