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

## 3. Los usuarios no se guardan en la base de datos
- **Estado:** Fallido
- **Módulo:** Backend / Base de Datos
- **Descripción:** Debido al fallo en el proceso de registro, no se inserta ni persiste ningún registro de usuario nuevo en la base de datos.
- **Resultado esperado:** Almacenar el registro del usuario recién creado en la tabla correspondiente de la base de datos.
- **Resultado actual:** La base de datos no guarda ningún usuario nuevo.