# Seguridad y protección de datos

## 1. Principios
- Aplicar mínimo privilegio.
- Validar todas las entradas en el backend.
- No confiar únicamente en las restricciones del frontend.
- Proteger los datos tanto en tránsito como en almacenamiento.

## 2. Autenticación
- El backend emite tokens JWT firmados con HS256 y expiración configurable.
- `JWT_SECRET_KEY` es obligatorio y debe tener al menos 32 caracteres; no existe una clave predeterminada para producción.
- La sesión dura 60 minutos desde el inicio de sesión (`JWT_EXPIRE_MINUTES`); el vencimiento es absoluto, no por inactividad.
- La recuperación de contraseña usa un código numérico de ocho dígitos, almacenado como HMAC, válido durante diez minutos y limitado a cinco intentos.
- Los códigos anteriores se invalidan al pedir uno nuevo; las solicitudes se limitan a una por minuto por cuenta y la respuesta no revela si el correo existe.
- El envío SMTP se procesa después de responder a la solicitud; los fallos quedan registrados en los logs sin exponer el código ni el correo.
- El cambio de contraseña incrementa la versión de token del usuario e invalida sus JWT emitidos anteriormente.
- La clave se mantiene como secreto de entorno y no debe registrarse ni incluirse en Git.
- Las contraseñas se almacenan mediante hash Argon2; nunca se registran contraseñas, tokens ni secretos.
- No existe renovación de sesión ni endpoint de cierre de sesión; la recuperación de contraseña sí invalida los JWT anteriores del usuario.
- No registrar contraseñas, tokens ni secretos en los logs.

## 3. Autorización
- Verificar permisos en cada operación protegida.
- Aislar los datos de cada finca según los permisos del usuario.
- Probar intentos de acceso no autorizado.

## 4. Secretos y configuración
- No subir archivos .env con credenciales reales.
- Mantener un .env.example sin secretos.
- Separar configuración de desarrollo y producción.
- Revisar los cambios antes de publicarlos en GitHub.
- En Railway, generar una clave JWT aleatoria y definirla como variable secreta del servicio API.
- Configurar las variables `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD` y `SMTP_FROM_EMAIL` como secretos/variables del servicio API; nunca guardar credenciales SMTP en el repositorio.
- En Railway, mantener `CORS_ORIGINS` vacío hasta conocer el origen web; después registrar solo los dominios HTTPS exactos.
- En local, permitir HTTP únicamente para direcciones loopback.

## 5. API y errores
- Validar tipos, formatos, límites y relaciones entre datos.
- Devolver mensajes de error controlados.
- No exponer trazas, consultas SQL ni detalles internos.
- CORS no usa comodines, cookies ni cabeceras o métodos arbitrarios; acepta solo los orígenes exactos configurados.
- La creación automática de tablas se reserva al entorno de desarrollo; producción debe aplicar migraciones Alembic antes de iniciar la API.

## 6. Datos sin conexión
- Definir qué información puede almacenarse en el dispositivo.
- Evaluar cifrado del almacenamiento local.
- Proteger la cola de operaciones pendientes.
- Resolver conflictos sin perder cambios silenciosamente.
- Considerar el cierre de sesión y la revocación de acceso.

## 7. Auditoría y recuperación
- El diseño de auditoría debe registrar quién inició sesión y las acciones realizadas, con fecha UTC, recurso, resultado e identificador de correlación.
- No registrar contraseñas, tokens ni el contenido completo de solicitudes; los cambios antes/después quedan fuera de la propuesta inicial.
- Restringir la lectura de auditoría y evitar que usuarios de la aplicación puedan alterar sus registros.
- Definir copias de seguridad y pruebas de restauración.
- Aprobar retención, eliminación y permisos para consultar informes antes de implementar el módulo.

## 8. Pruebas mínimas
- Acceso sin sesión y con permisos insuficientes.
- Intentos de consultar datos de otra finca.
- Entradas inválidas y errores inesperados.
- Verificación de que los secretos no aparecen en logs.
- Pruebas de restauración y sincronización.

Estado: autenticación JWT, recuperación por correo, validación de CORS y migración Alembic incorporadas en el código; SMTP y dominios de despliegue requieren configuración; política de retención y módulo de auditoría siguen pendientes de aprobación.
