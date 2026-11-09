# Proyecto Gestión Ganadera — Base de Código e Instrucciones

Base de código e infraestructura alineada con la documentación formal del proyecto (`docs/`).

## Stack Tecnológico
- **Backend:** Python 3.12, FastAPI, SQLAlchemy 2.0, Pydantic v2, PyJWT, Argon2 (stdlib).
- **Base de Datos:** PostgreSQL 16 con migraciones de esquema Alembic.
- **Frontend / Móvil:** Flutter (Dart) con Material 3.
- **Contenedores:** Docker Compose & Dockerfile multi-stage.

## Inicio Rápido con Docker
```bash
# 1. Crear variables de entorno

cp .env.example .env

# 2. Generar una clave y asignarla a JWT_SECRET_KEY en .env
python -c "import secrets; print(secrets.token_url-safe(48))"

# 3. Iniciar contenedores
docker compose up --build -d

# 4. Probar salud de la API
curl http://localhost:8000/health
```

La clave JWT es obligatoria; Docker Compose no inicia la API si está vacía. En Railway, configura una clave distinta como secreto, `ENVIRONMENT=production` y `CORS_ORIGINS` con el origen HTTPS exacto de Vercel cuando esté disponible. No uses comodines ni publiques secretos en Git.

`DATABASE_URL` también es obligatoria. La plantilla `.env.example` apunta al servicio PostgreSQL local de Docker Compose (`db`); para Railway usa la URL como variable secreta del servicio. Las pruebas del backend fuerzan SQLite en memoria y no deben conectarse a Railway.

Para el inicio de sesión web, compila Flutter con `--dart-define=RECAPTCHA_SITE_KEY=...` usando la clave pública de reCAPTCHA v2. Configura `RECAPTCHA_SECRET_KEY` como secreto del servicio API en Railway y `RECAPTCHA_ALLOWED_HOSTNAMES` con el dominio exacto del sitio web (y el dominio público de la API solo si la validación debe aceptar solicitudes desde ese host). Configura también `CORS_ORIGINS` con el origen HTTPS exacto del frontend. Nunca incluyas la clave secreta en la compilación web. La app móvil nativa no muestra ni envía el CAPTCHA; la API verifica los tokens cuando se envían. Por eso, CAPTCHA en web protege el flujo normal de la interfaz, pero no impide que un cliente que llame directamente a la API omita el token; para imponerlo también a clientes nativos se requiere una verificación de plataforma confiable o pedir CAPTCHA en todas las plataformas.

El correo alternativo se registra solo desde una sesión autenticada y debe verificarse con un código enviado al buzón, que vence en 10 minutos y limita los intentos. Una vez verificado, puede usarse para iniciar sesión y solicitar/restablecer contraseña. La migración `8f2c1a6d4e90` agrega estas columnas y tablas operativas del ganado, producción, inventario y auditoría de forma aditiva.

La sesión JWT dura 60 minutos desde el inicio de sesión y vence aunque haya actividad. Para enviar códigos de recuperación, configura `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD` y `SMTP_FROM_EMAIL` como variables del entorno/API. El código numérico vence a los 10 minutos, solo puede usarse una vez y limita los intentos.

Documentación interactiva Swagger: `http://localhost:8000/docs`

## Pruebas Automatizadas
```bash
# Crear entorno e instalar dependencias
python -m venv .venv
.\.venv\Scripts\activate  # Windows PowerShell
pip install -r backend/requirements.txt

# Ejecutar test suite
pytest backend/tests
```


## Migraciones Alembic
```bash
docker compose up --build
```

El contenedor aplica `alembic upgrade head` antes de iniciar Unicorn. Las migraciones deben ser ejecutadas solo por el despliegue, nunca por la suite de pruebas. Para ejecutar Alembic manualmente, configura primero `DATABASE_URL` con la base local correcta; no uses la URL de Railway para pruebas. Si una base existente no tiene la tabla de versiones de Alembic, verifica su esquema y estado antes de migrarla; no marques ni apliques migraciones a ciegas.
****
