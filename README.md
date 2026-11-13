# GAVAC — Gestión Ganadera

**Plataforma de gestión y administración ganadera**

GAVAC es una plataforma multiplataforma diseñada para facilitar la administración de la actividad ganadera mediante una API REST y una aplicación desarrollada en Flutter.

Su arquitectura utiliza FastAPI, PostgreSQL y Flutter, ofreciendo una base tecnológica para gestionar la información y las operaciones del negocio ganadero.

## Tecnologías

- **Backend:** Python 3.12 y FastAPI.
- **Base de datos:** PostgreSQL 16.
- **ORM:** SQLAlchemy 2.0.
- **Migraciones:** Alembic.
- **Aplicación:** Flutter y Dart 3.
- **Interfaz:** Material 3.
- **Contenedores:** Docker Compose.
- **Documentación API:** Swagger / OpenAPI.

## Estructura del proyecto

```text
GAVAC/
├── backend/                # API, modelos, autenticación y pruebas
├── mobile/                 # Aplicación multiplataforma Flutter
├── docs/                   # Documentación técnica
├── .github/                # Configuración de GitHub
├── docker-compose.yml      # Servicios locales
├── .env.example            # Plantilla de configuración
├── .gitignore
├── README.md
├── INSTRUCCIONES.md
└── CONTRIBUTING.md
```

## Requisitos

Antes de iniciar necesitas:

- Docker Desktop con Docker Compose.
- Flutter SDK compatible con Dart 3.
- Python 3.12 (para pruebas locales del backend).
- Git.

## Instalación y ejecución

### 1. Obtener el proyecto

```powershell
git clone URL_DEL_REPOSITORIO
cd Proyecto_GAVAC
```

### 2. Configurar variables de entorno

```powershell
Copy-Item .env.example .env
```

Edita `.env` y configura:

- Credenciales de PostgreSQL.
- `DATABASE_URL`.
- `JWT_SECRET_KEY` con una clave aleatoria de al menos 32 caracteres.

No compartas el archivo `.env` ni publiques sus credenciales.

### 3. Iniciar backend y base de datos

Desde la raíz del proyecto:

```powershell
docker compose up -d --build
```

Servicios locales:

| Servicio | Dirección |
| --- | --- |
| API REST | <http://localhost:8001> |
| Swagger | <http://localhost:8001/docs> |
| Health Check | <http://localhost:8001/health> |
| PostgreSQL | Puerto 5433 |

Las migraciones Alembic se aplican durante el inicio de la API, según la configuración de Docker.

### 4. Iniciar aplicación Flutter

Abre otra terminal:

```powershell
Set-Location mobile
flutter pub get
flutter run
```

La URL del backend se configura en:

`mobile/lib/core/network/api_client.dart`

Para Flutter Web puedes establecer otra dirección:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8001
```

## Validaciones

### Backend

Desde la raíz del proyecto:

```powershell
Set-Location backend
python -m pip install -r requirements-dev.txt
python -m pytest -q
alembic heads
```

### Flutter

```powershell
Set-Location mobile
flutter pub get
flutter analyze
flutter test
```

## Base de datos y registros

Docker Compose utiliza el volumen `postgres_api_data` para conservar los datos de PostgreSQL.

Consultar registros:

```powershell
docker compose logs -f api
```

Consultar servicios:

```powershell
docker compose ps
```

Detener los servicios:

```powershell
docker compose down
```

**Importante:** no ejecutes `docker compose down -v` si necesitas conservar la información almacenada en PostgreSQL.

## Documentación adicional

Consulta los siguientes documentos para conocer el funcionamiento interno de GAVAC:

- `INSTRUCCIONES.md`: configuración, desarrollo y despliegue.
- `CONTRIBUTING.md`: normas de colaboración y flujo de trabajo.
- `docs/ARQUITECTURA.md`: arquitectura general del sistema.
- `docs/CONTRATO_API.md`: endpoints y contratos de la API.
- `docs/CREAR_REPOSITORIO.md`: instrucciones para publicar el proyecto.

## Seguridad

- No publiques archivos `.env`.
- No compartas claves JWT ni contraseñas.
- Mantén las credenciales de producción en variables seguras.
- Ejecuta las pruebas antes de publicar cambios.
- No ejecutes migraciones de producción desde las pruebas locales.

---

**GAVAC — Gestión Ganadera**

*Tecnología para organizar, administrar y optimizar la gestión ganadera.*
