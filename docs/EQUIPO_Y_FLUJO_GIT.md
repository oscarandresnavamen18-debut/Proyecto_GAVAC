# Equipo y flujo de Git

## 1. Responsabilidades
- Jorge Botero: backend y base de datos.
- Óscar Navarro: backend y base de datos, coordinando con Jorge.
- Elian Martínez: frontend.
- Juan Herrera: revisión técnica y seguridad.

## 2. Reglas de colaboración
- La rama main debe mantenerse estable.
- Cada tarea debe tener un objetivo claro.
- Los cambios se realizan en ramas de trabajo.
- Los cambios se integran mediante Pull Request.
- La revisión debe completarse antes de integrar cambios.
- No se deben inventar commits ni ocultar errores de pruebas.

## 3. Flujo de trabajo propuesto
1. Revisar el estado local y actualizar la información de Git.
2. Crear una rama para la tarea asignada.
3. Implementar cambios pequeños y verificables.
4. Ejecutar pruebas y revisar los archivos modificados.
5. Preparar un commit con un mensaje claro en español.
6. Publicar la rama y abrir un Pull Request.
7. Revisar y aprobar antes de integrar en main.

## 4. Seguridad en Git
- No incluir credenciales, tokens ni datos reales de producción.
- Revisar git status antes de preparar un commit.
- Añadir archivos explícitos, no todo el directorio indiscriminadamente.
- Revisar el contenido preparado antes de confirmar el commit.
- No reescribir historia compartida sin autorización del equipo.

## 5. Convención de ramas
- feat/: nuevas funcionalidades.
- fix/: correcciones.
- docs/: documentación.
- test/: pruebas.
- security/: mejoras de seguridad.

## 6. Revisión y comunicación
- Registrar decisiones técnicas relevantes.
- Informar bloqueos y resultados de pruebas.
- Evitar que dos personas modifiquen simultáneamente los mismos archivos sin coordinación.
- Confirmar con el equipo antes de cambiar contratos compartidos.

Estado: propuesta de colaboración pendiente de aprobación del equipo.
