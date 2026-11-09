# Preparar un repositorio nuevo en GitHub

Este proyecto no cambia de remoto ni publica código automáticamente. Antes de crear el repositorio de destino, confirma su nombre, propietario, visibilidad y si quieres conservar el historial actual.

## Revisión local previa

Desde la raíz del proyecto:

```powershell
git status
git diff --check
git ls-files .env
git ls-files node_modules
```

Comprueba que `.env` y `node_modules/` no estén versionados, revisa los cambios que se van a conservar y ejecuta las pruebas indicadas en `CONTRIBUTING.md`.

## Conservar el historial

Después de crear en GitHub un repositorio vacío (sin README, licencia ni `.gitignore` inicial), conserva el remoto actual como referencia y configura el nuevo:

```powershell
git remote rename origin upstream
git remote add origin https://github.com/PROPIETARIO/NUEVO-REPOSITORIO.git
git remote -v
```

Integra y confirma los cambios revisados antes de publicar. Luego envía únicamente la rama que quieras publicar:

```powershell
git push -u origin main
```

Reemplaza la URL de ejemplo por la del nuevo repositorio. No ejecutes estos comandos hasta confirmar que el destino es correcto y que tienes permiso para publicar allí.

## Empezar con historial nuevo

Si no deseas conservar el historial, crea una copia limpia del contenido revisado en una carpeta nueva e inicializa allí un repositorio independiente. No borres `.git/` del proyecto actual: ese directorio contiene el historial y la configuración del remoto existente.

## Configuración en GitHub

Después de publicar:

1. Confirma que las acciones de CI de backend y Flutter se ejecuten correctamente.
2. Configura `main` como rama predeterminada y exige solicitudes de cambio y verificaciones antes de integrar, si el plan de GitHub lo permite.
3. Activa la notificación privada de vulnerabilidades si el proyecto será público.
4. Elige y añade una licencia antes de permitir que terceros reutilicen el código.
