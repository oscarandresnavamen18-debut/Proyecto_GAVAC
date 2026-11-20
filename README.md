# GAVAC — Gestión Ganadera

Plataforma para la gestión ganadera con una API REST y una aplicación multiplataforma. El backend usa FastAPI y PostgreSQL; el cliente está desarrollado en Flutter.

## Estructura del repositorio

```text
backend/          API FastAPI
  app/core/       configuración, base de datos, seguridad, dependencias y permisos
  app/routers/    endpoints por módulo (auth, users, farms, animals, health_records,
                  breeding, production, inventory, reports...)
  app/services/   correo, reCAPTCHA, proveedores de identidad y reportes PDF/Excel
  alembic/        migraciones de la base de datos
  tests/          pruebas (SQLite en memoria)
mobile/           aplicación Flutter (web, Android, iOS y escritorio)
  lib/core/       cliente HTTP, rutas, sesión, tema y utilidades compartidas
  lib/features/   un módulo por opción del menú: auth, dashboard, animales, sanidad,
                  reproduccion, produccion, insumos, reportes y administracion
  test/           pruebas de widgets, con la misma estructura de lib/
docs/             arquitectura, contrato del API, despliegue y decisiones del proyecto
docker-compose.yml  entorno local con PostgreSQL y la API
```

El flujo de ramas y revisiones está en [CONTRIBUTING.md](CONTRIBUTING.md).

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

   En web el inicio de sesión exige reCAPTCHA v2: define `RECAPTCHA_SECRET_KEY` en `.env` y compila con la clave pública correspondiente, cuyo dominio debe incluir `localhost`:

   ```powershell
   flutter run -d chrome --web-port 8080 --dart-define=RECAPTCHA_SITE_KEY=<clave_publica>
   ```

## Primer uso

1. En la pantalla de inicio de sesión, elige **"¿No tienes cuenta? Regístrate aquí"**. Esa cuenta queda como **Administrador** junto con su primera finca.
2. Inicia sesión eligiendo el tipo de usuario **Administrador**.
3. En **Administración** crea más fincas y registra a los **veterinarios** y **trabajadores de campo**, con su finca y los módulos que pueden usar.
4. Cada usuario entra eligiendo su tipo de usuario y solo ve los módulos que tiene permitidos.

Los roles, permisos y endpoints están en el [contrato de la API](docs/CONTRATO_API.md).

## Actualizar después de traer cambios

Cuando lleguen cambios de `develop` con migraciones o dependencias nuevas:

```powershell
docker compose up -d --build   # reconstruye la API y aplica las migraciones
Set-Location mobile
flutter pub get
```

Fuera de Docker, aplica las migraciones con `alembic upgrade head` desde `backend/`.

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
## Datos locales

Docker Compose conserva la base en el volumen `postgres_api_data`. Evita `docker compose down -v` si necesitas conservar esos datos. Para revisar los registros de la API:

```powershell
docker compose logs -f api
```

## Documentación

- [Arquitectura](docs/ARQUITECTURA.md): diseño del sistema y organización del código.
- [Contrato del API](docs/CONTRATO_API.md): endpoints, roles y permisos.
- [Despliegue](docs/DESPLIEGUE.md): variables de entorno, Railway, reCAPTCHA, correo y migraciones.
- [Equipo y flujo de Git](docs/EQUIPO_Y_FLUJO_GIT.md), [visión y alcance](docs/VISION_Y_ALCANCE.md), [casos de uso](docs/CASOS_DE_USO.md) y [seguridad y datos](docs/SEGURIDAD_Y_DATOS.md).
- `docs/historico/`: documentos de las primeras etapas, conservados como referencia.
