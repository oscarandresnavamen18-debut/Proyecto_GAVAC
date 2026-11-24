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


### 7. Mensaje de estado vacío confuso al filtrar por "Vendidos y muertos"
- **Módulo:** Registro de Animales (Filtros de inventario)
- **Descripción:** Al activar el filtro **Vendidos y muertos** (cuando la tarjeta de **Salidas** muestra `0 vendidos · 0 muertos` y **En la finca** muestra `3` animales activos), el sistema muestra el mensaje genérico *"No hay animales registrados en el sistema"* en lugar de indicar que no existen registros bajo ese filtro específico[cite: 21].
- **Comportamiento esperado:** Al filtrar por **Vendidos y muertos** sin registros coincidentes, debe mostrarse un mensaje contextual claro (por ejemplo, *"No hay animales vendidos o muertos registrados"*) y evitar contradicción visual frente al conteo de animales activos[cite: 21].
- **Comportamiento actual:** Se muestra *"No hay animales registrados en el sistema"*, generando confusión sobre si existen o no animales cargados en la plataforma[cite: 21].
- **Severidad:** Baja / Usabilidad (confusión en la lectura del estado del inventario).


### 8. Error de respuesta del servidor en Módulo de Producción ("El servidor devolvió una respuesta no válida")
- **Módulo:** Producción vs. Panel Principal (Inicio)
- **Descripción:** Mientras el **Panel Principal (Inicio)** sí carga métricas reales de la finca (*Peso promedio del hato: 25 kg*, *Promedio por ordeño: 13,3 L*, *Leche producida: 26,5 L*)[cite: 22], al ingresar al **Módulo de Producción** o intentar registrar producción aparece el mensaje de error **`"El servidor devolvió una respuesta no válida."`**, dejando las tarjetas en `0 L` / `0 kg` y el historial vacío (*"No hay registros de producción"*)[cite: 21].
- **Comportamiento esperado:** El endpoint consumido por el Módulo de Producción debe responder con un JSON/esquema válido, sincronizado con los datos de la finca, permitiendo listar el historial y crear nuevos registros[cite: 21, 22].
- **Comportamiento actual:** El cliente Flutter recibe una respuesta no válida desde el backend en el módulo de Producción, bloqueando tanto la consulta del historial como el registro diario[cite: 21].
- **Severidad:** Alta (fallo de integración/contrato entre frontend y backend en Producción).


### 9. Inconsistencia en asignación de rol Administrador tras registro de usuario y finca
- **Módulo:** Autenticación / Registro de Usuarios y Fincas
- **Descripción:** Tras registrar una cuenta nueva (`samuel2@gmail.com`) y crear una finca, el sistema no permite iniciar sesión seleccionando el tipo de usuario **Administrador** (mostrando *"No se pudo iniciar sesión. Inténtalo de nuevo."*)[cite: 24].
- **Comportamiento esperado:** El usuario que registra una finca debe contar con permisos de administración sobre su predio o recibir retroalimentación clara sobre el rol asignado durante el registro.
- **Comportamiento actual:** El registro asigna un rol distinto a Administrador (o el selector de rol en login bloquea el acceso), impidiendo ingresar como Administrador con la cuenta recién creada[cite: 24].
- **Severidad:** Alta (bloquea gestión administrativa de la finca recién creada).


### 10. Error al Inicio de seccion en el login
El encargado del login por favor corregir el inicio de seccion, no deja loguearse a la pagina.
## Descripcion:
Error en el servidor.
##
solucinar la problematica para continuar haciendo pruebas.

### 11. Error en la conexión de la base de datos con el servidor
- **Módulo:** Base de Datos / Backend (Autenticación)
- **Responsable:** Encargado de Base de Datos / Backend
- **Descripción:** El servidor no logra establecer conexión con la base de datos (PostgreSQL / `DATABASE_URL` o migraciones pendientes), lo que impide validar credenciales y completar el inicio de sesión.
- **Comportamiento esperado:** La base de datos debe estar conectada y operativa junto con el servidor para permitir el registro y el inicio de sesión de los usuarios.
- **Comportamiento actual:** Falla la conexión entre el servidor y la base de datos, bloqueando el acceso al sistema y la continuidad de las pruebas QA.
- **Severidad:** Crítica (bloquea completamente el acceso y las pruebas funcionales).