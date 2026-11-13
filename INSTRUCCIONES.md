# PROYECTO_GAVAC

## Plataforma de Gestión Ganadera

**Documentación técnica | Instalación, configuración y ejecución**

PROYECTO_GAVAC es una plataforma para la gestión y administración de actividades ganaderas. Su arquitectura integra una API backend, una aplicación Flutter y una base de datos PostgreSQL.

Este documento explica cómo preparar el entorno, ejecutar el proyecto, realizar pruebas y configurar los servicios necesarios para trabajar en desarrollo y producción.

---

## 1. Tecnologías utilizadas

| Componente | Tecnología |
| --- | --- |
| Backend | Python 3.12 y FastAPI |
| ORM | SQLAlchemy 2.0 |
| Validación | Pydantic v2 |
| Autenticación | JWT y Argon2 |
| Base de datos | PostgreSQL 16 |
| Migraciones | Alembic |
| Aplicación móvil | Flutter y Dart |
| Interfaz | Material 3 |
| Contenedores | Docker y Docker Compose |
| Documentación API | Swagger / OpenAPI |

## 2. Requisitos previos

Antes de iniciar, instala:

- Python 3.12.
- Flutter SDK.
- Git.
- Docker Desktop.
- PostgreSQL 16 (opcional si utilizas Docker).
- Visual Studio Code o un IDE compatible.

Verifica las instalaciones:

```powershell
python --version
flutter --version
git --version
docker --version
```

## 3. Configuración del proyecto

Clona el repositorio y entra en su carpeta:

```powershell
git clone URL_DEL_REPOSITORIO
cd Proyecto_GAVAC
```

Crea el archivo de configuración:

```powershell
Copy-Item .env.example .env
```

Genera una clave JWT segura:

```powershell
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

Copia el resultado en `JWT_SECRET_KEY` dentro de `.env`.

**Importante:** utiliza claves diferentes para desarrollo y producción. Nunca publiques el archivo `.env` en GitHub.

## 4. Configuración de la base de datos

El proyecto utiliza PostgreSQL 16.

Para trabajar con Docker Compose, configura `DATABASE_URL` con el nombre del servicio de PostgreSQL definido en `docker-compose.yml`.

Ejemplo:

```env
DATABASE_URL=postgresql+psycopg://usuario:clave@db:5432/Proyecto_GAVAC
```

Verifica que el nombre del servicio, usuario, contraseña y base de datos coincidan con la configuración real de Docker.

No utilices la dirección `db` desde una aplicación ejecutada fuera de Docker. En ese caso debes utilizar el host y puerto correspondientes a tu instalación local.

## 5. Ejecutar el proyecto con Docker

Desde la raíz del repositorio:

```powershell
docker compose up --build -d
```

Consultar los contenedores:

```powershell
docker compose ps
```

Consultar los registros:

```powershell
docker compose logs -f
```

Detener los servicios:

```powershell
docker compose down
```

La API debe estar disponible en:

- API: `http://localhost:8001`
- Swagger: `http://localhost:8001/docs`
- Salud: `http://localhost:8001/health`

Comprueba la API:

```powershell
Invoke-RestMethod http://localhost:8001/health
```

## 6. Ejecutar el backend sin Docker

Si deseas trabajar directamente con Python, prepara el entorno virtual desde la raíz:

```powershell
python -m venv backend\.venv
.\backend\.venv\Scripts\Activate.ps1
Set-Location backend
python -m pip install -r requirements-dev.txt
```

Inicia el servidor utilizando el módulo de entrada configurado en el proyecto. Por ejemplo, si el punto de entrada es `app.main:app`:

```powershell
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8001
```

La ruta del módulo debe coincidir con la estructura real del backend.

## 7. Ejecutar la aplicación Flutter

Abre una segunda terminal y entra en la carpeta móvil:

```powershell
cd mobile
flutter pub get
flutter doctor
flutter run
```

Para compilar la versión web con la clave pública de reCAPTCHA:

```powershell
flutter build web --dart-define=RECAPTCHA_SITE_KEY=CLAVE_PUBLICA
```

La clave secreta de reCAPTCHA nunca debe incluirse en Flutter.

## 8. Autenticación y seguridad

La plataforma contempla los siguientes mecanismos:

### Inicio de sesión

- Autenticación mediante correo y contraseña.
- Sesiones mediante JWT.
- Inicio de sesión con Google.
- Inicio de sesión con Microsoft, si está habilitado en la configuración.

La duración configurada para la sesión JWT es de 60 minutos.

### reCAPTCHA

Para proteger el inicio de sesión web se utiliza Google reCAPTCHA v2.

Variables necesarias en el backend:

```env
RECAPTCHA_SECRET_KEY=
RECAPTCHA_ALLOWED_HOSTNAMES=
```

Variable pública para Flutter Web:

```text
RECAPTCHA_SITE_KEY
```

La clave pública se entrega mediante `--dart-define`; la clave secreta permanece exclusivamente en el backend.

La aplicación móvil nativa no presenta CAPTCHA por defecto. Si se requiere protección obligatoria para todos los clientes, debe implementarse una verificación adicional confiable del lado del servidor.

### Recuperación de contraseña

El sistema contempla códigos de recuperación enviados por correo electrónico.

Características:

- Código de verificación de un solo uso.
- Vigencia de 10 minutos.
- Control de intentos.
- Validación antes de permitir el cambio de contraseña.

### Correo alternativo

El correo alternativo debe registrarse desde una sesión autenticada.

Su verificación se realiza mediante un código enviado al buzón, con vigencia de 10 minutos y límite de intentos.

Una vez verificado, puede utilizarse para iniciar sesión y recuperar el acceso a la cuenta.

## 9. Configuración del correo electrónico

Para habilitar los mensajes de recuperación configura estas variables en el entorno del backend:

```env
SMTP_HOST=
SMTP_PORT=
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_FROM_EMAIL=
```

Los valores deben corresponder al proveedor SMTP utilizado.

No almacenes credenciales reales en archivos versionados.

## 10. Pruebas automatizadas

Ejecuta las pruebas desde el backend:

```powershell
cd backend
python -m pip install -r requirements-dev.txt
python -m pytest -q
```

La suite de pruebas debe utilizar SQLite en memoria cuando así esté configurada y no debe conectarse a la base de datos de producción.

**Las pruebas no deben ejecutar migraciones contra Railway ni modificar datos reales.**

## 11. Migraciones de base de datos

El proyecto utiliza Alembic para controlar los cambios en la estructura de PostgreSQL.

En Docker Compose, el proceso de inicio debe aplicar:

```bash
alembic upgrade head
```

Las migraciones deben ejecutarse en el entorno de despliegue, no durante las pruebas automatizadas.

Antes de ejecutar una migración sobre una base existente:

1. Verificar la versión actual del esquema.
2. Revisar las migraciones pendientes.
3. Realizar una copia de seguridad.
4. Confirmar que los cambios sean compatibles.
5. Aplicar la migración y comprobar el resultado.

Nunca marques una migración como aplicada sin verificar previamente el estado real de la base de datos.

## 12. Despliegue en Railway

Para producción configura en el servicio backend:

```env
ENVIRONMENT=production
DATABASE_URL=
JWT_SECRET_KEY=
CORS_ORIGINS=
RECAPTCHA_SECRET_KEY=
RECAPTCHA_ALLOWED_HOSTNAMES=
SMTP_HOST=
SMTP_PORT=
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_FROM_EMAIL=
```

Consideraciones:

- `DATABASE_URL` debe apuntar al PostgreSQL de producción.
- `JWT_SECRET_KEY` debe ser diferente de la clave local.
- `CORS_ORIGINS` debe contener los orígenes HTTPS autorizados del frontend.
- `RECAPTCHA_SECRET_KEY` debe permanecer en Railway.
- `RECAPTCHA_ALLOWED_HOSTNAMES` debe contener los dominios autorizados.
- Las migraciones deben ejecutarse antes de iniciar la API.
- No utilizar bases de datos de producción para pruebas locales.

## 13. Buenas prácticas de desarrollo

- Trabajar en ramas de Git para cambios nuevos.
- Revisar los cambios antes de crear commits.
- No subir archivos `.env`, secretos ni credenciales.
- Ejecutar las pruebas antes de publicar cambios.
- No modificar migraciones ya aplicadas sin evaluar su impacto.
- Mantener sincronizados backend y Flutter.
- Documentar los cambios importantes.
- Verificar el despliegue después de cada actualización.

## 14. Estructura general del proyecto

```text
Proyecto_GAVAC/
├── backend/
│   ├── app/
│   ├── alembic/
│   ├── tests/
│   ├── requirements.txt
│   └── requirements-dev.txt
├── mobile/
│   ├── lib/
│   ├── android/
│   ├── web/
│   └── pubspec.yaml
├── docs/
├── .github/
├── docker-compose.yml
├── .env.example
├── .gitignore
├── Dockerfile
└── README.md
```

La estructura es orientativa y debe mantenerse alineada con los directorios reales del repositorio.

---

**PROYECTO_GAVAC — Plataforma de Gestión Ganadera**

Documentación técnica para instalación, desarrollo, pruebas y despliegue.
