# Casos de uso — Gestión Ganadera

## CU-01. Iniciar sesión
- El usuario ingresa sus credenciales.
- El sistema valida la identidad y permite el acceso autorizado.
- Ante credenciales inválidas, muestra un mensaje controlado.

## CU-02. Gestionar fincas
- Un usuario autorizado registra y consulta fincas.
- Solo puede modificar la información según sus permisos.

## CU-03. Gestionar animales
- Registrar cada animal con un identificador único.
- Consultar y actualizar sus datos autorizados.
- Evitar duplicados según las reglas que defina el equipo.

## CU-04. Registrar eventos
- Asociar eventos sanitarios o reproductivos al animal correspondiente.
- Registrar fecha, tipo, responsable y observaciones pertinentes.
- Mantener un historial trazable de los cambios.

## CU-05. Consultar información
- Buscar animales y consultar sus historiales.
- Generar informes según los permisos y filtros disponibles.

## CU-06. Trabajar sin conexión
- Permitir las operaciones que el equipo habilite para uso offline.
- Guardar los cambios pendientes en almacenamiento local persistente.
- Mostrar el estado de sincronización.

## CU-07. Sincronizar cambios
- Enviar operaciones pendientes cuando exista conexión.
- Evitar aplicar dos veces la misma operación.
- Informar errores y conflictos que requieran intervención.

## CU-08. Administrar usuarios y permisos
- Permitir la gestión solo a usuarios autorizados.
- Aplicar permisos en el backend, no únicamente en la interfaz.

## CU-09. Auditar operaciones
- Registrar las operaciones críticas definidas por el equipo.
- Restringir el acceso a los registros de auditoría.

## Pendiente de definición
- Perfiles y permisos exactos.
- Campos obligatorios de animales y eventos.
- Reglas de sincronización y resolución de conflictos.
- Informes prioritarios y operaciones permitidas sin conexión.

Estado: propuesta inicial pendiente de revisión y aprobación del equipo.
