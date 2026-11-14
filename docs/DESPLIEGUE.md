# Despliegue y configuración

Guía para configurar GAVAC fuera del entorno local: variables de entorno, Railway, reCAPTCHA, correo y migraciones. Para el arranque local consulta el [README](../README.md).

## Variables de entorno del API

| Variable | Obligatoria | Descripción |
|---|---|---|
| `DATABASE_URL` | Sí | URL de PostgreSQL. En local la arma Docker Compose (servicio `db_api`); en Railway se configura como secreto del servicio. |
| `JWT_SECRET_KEY` | Sí | Clave aleatoria de al menos 32 caracteres: `python -c "import secrets; print(secrets.token_urlsafe(48))"`. En producción el API no arranca si parece un texto de ejemplo. |
| `ENVIRONMENT` | Sí en producción | `production`, `development` o `test`. |
| `JWT_EXPIRE_MINUTES` | No | Duración de la sesión (60 por defecto). Vence aunque haya actividad. |
| `CORS_ORIGINS` | Sí en producción | Orígenes HTTPS exactos del frontend, separados por comas. Sin comodines. |
| `RECAPTCHA_SECRET_KEY` | Sí para web | Clave secreta de reCAPTCHA v2. |
| `RECAPTCHA_ALLOWED_HOSTNAMES` | No | Dominios desde los que se acepta el token de reCAPTCHA. |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_FROM_EMAIL` | Para correos | Envío de códigos de recuperación y de verificación del correo alternativo. |

Nunca publiques secretos en Git: `.env` está en `.gitignore` y `.env.example` solo trae valores de ejemplo.

## Railway

- Configura las variables anteriores en el servicio del API, con `ENVIRONMENT=production` y una `JWT_SECRET_KEY` propia.
- El contenedor aplica `alembic upgrade head` antes de iniciar Uvicorn.
- Antes de desplegar una versión con migraciones nuevas, saca un respaldo de la base (`pg_dump`).
- No expongas la base de datos públicamente (TCP Proxy) salvo para tareas puntuales, y desactívala al terminar.

## reCAPTCHA (inicio de sesión web)

- Compila Flutter Web con la clave pública: `--dart-define=RECAPTCHA_SITE_KEY=<clave_publica>`.
- La clave secreta va solo en el API (`RECAPTCHA_SECRET_KEY`); nunca en la compilación web.
- En la consola de Google reCAPTCHA, el dominio del frontend (y `localhost` para desarrollo) debe estar en la lista de dominios.
- La app nativa no muestra CAPTCHA. El CAPTCHA protege el flujo normal de la web, pero un cliente que llame directamente al API puede omitirlo; para exigirlo en todas las plataformas haría falta una verificación de plataforma confiable.

## Correo y recuperación de contraseña

- Los códigos de recuperación y de verificación del correo alternativo vencen a los 10 minutos, se usan una sola vez y limitan los intentos.
- El correo alternativo se registra desde una sesión autenticada; una vez verificado sirve para iniciar sesión y recuperar la contraseña.

## Migraciones

- Docker Compose y Railway aplican las migraciones al iniciar el API.
- Manualmente: configura `DATABASE_URL` con la base correcta y ejecuta `alembic upgrade head` desde `backend/`.
- Las pruebas del backend usan SQLite en memoria y nunca deben conectarse a Railway.
- Si una base existente no tiene la tabla `alembic_version`, revisa su esquema antes de migrarla; no marques ni apliques migraciones a ciegas.
- Cuentas creadas antes de la migración `b7d4e2f1a9c3` quedaron con rol `MAYORDOMO`; los administradores reales deben pasarse a `ADMIN`:

  ```sql
  UPDATE usuarios SET role = 'ADMIN' WHERE email = 'correo-del-admin@...';
  ```
