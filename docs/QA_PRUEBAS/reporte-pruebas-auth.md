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




### 4. Visualización de finca incorrecta al iniciar sesión como usuario (posible fallo de filtrado por usuario / sesión)
- **Módulo:** Fincas / Perfil de usuario
- **Descripción:** Al iniciar sesión con una cuenta de usuario, el sistema no muestra la finca registrada por ese usuario, sino una finca diferente llamada **"Hacienda el paraiso"**., debe salir la que registra el usuario mas no esa.
- **Comportamiento esperado:** Cada usuario autenticado debe visualizar únicamente las fincas asociadas a su propio ID de usuario o permisos asignados.
- **Comportamiento actual:** Se carga o muestra una finca de otro registro/usuario ("Hacienda el paraiso") en lugar de la propia.
- **Severidad:** Alta (problema de integridad y privacidad de datos entre usuarios).




### 5. Bloqueo al registrar vacunas, tratamientos y eventos reproductivos teniendo animales registrados
- **Módulos:** Salud (Vacunas y Tratamientos) / Reproducción (Eventos) / Registro de Animales
- **Descripción:** Aunque existen 2 animales activos en el módulo de Registro (incluyendo una hembra con chapeta `CH-00058` y un macho con chapeta `CH-20004`), los módulos de **Salud** y **Reproducción** no reconocen el inventario cargado y bloquean los botones de registro mostrando los mensajes *"Registra primero un animal en el módulo de Registro"* y *"Registra primero una hembra en el módulo de Registro"*.
- **Comportamiento esperado:** Los formularios de vacunas, tratamientos y eventos reproductivos deben leer la lista de animales/hembras activos de la finca y permitir su registro.
- **Comportamiento actual:** El estado de animales registrados no se comparte o no se consulta correctamente desde los módulos de Salud y Reproducción, impidiendo registrar novedades sanitarias y reproductivas.
- **Severidad:** Alta (bloquea flujos operativos principales de sanidad y reproducción).


### 6. Problemas de contraste, legibilidad y visualización en el modal "Registrar Animal"
- **Módulo:** Registro de Animales (Modal de creación)
- **Descripción:** Al abrir el formulario modal **Registrar Animal**, se evidencian problemas de legibilidad y visualización en campos y menús desplegables (sin relación con la paleta de colores del tema): el placeholder de **Fecha de Nacimiento** tiene bajo contraste, el botón de cerrar (`X`) es poco visible y las opciones del selector de potrero (*Sin potrero*, *La candelaria*, *La pesquera*) presentan bajo contraste / desborde visual al desplegarse.
- **Comportamiento esperado:** Todos los textos de ayuda/placeholders, controles de cierre y listas desplegables del modal deben tener buen contraste, alineación y legibilidad clara al interactuar con ellos.
- **Comportamiento actual:** Ciertos textos y elementos del modal resultan difíciles de leer o se visualizan con poco contraste/desborde al abrir el selector de potrero.
- **Severidad:** Media (afecta usabilidad y legibilidad al registrar animales).