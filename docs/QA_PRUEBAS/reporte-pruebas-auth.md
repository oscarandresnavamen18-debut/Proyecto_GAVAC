# Reporte de Pruebas QA - Módulo de Autenticación

## 1. Fallo al iniciar sesión (Login)
- **Estado:** Fallido
- **Módulo:** Autenticación / Login
- **Descripción:** Al ingresar credenciales en el formulario de inicio de sesión, el sistema no permite ingresar ni inicia la sesión del usuario.
- **Resultado esperado:** Validar las credenciales correctamente y redirigir al usuario a la vista principal.
- **Resultado actual:** No inicia sesión y bloquea el flujo de acceso.

## 2. Error al registrar usuario nuevo
- **Estado:** Fallido
- **Módulo:** Autenticación / Registro
- **Descripción:** Al completar el formulario de registro con los datos de un usuario nuevo y enviarlo, el sistema no crea la cuenta.
- **Resultado esperado:** Crear el nuevo usuario y mostrar confirmación de registro exitoso.
- **Resultado actual:** El usuario no se crea.