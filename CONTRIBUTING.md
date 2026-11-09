# Contribuir a GAVAC

## Antes de empezar

1. Crea una rama de trabajo a partir de `main`.
2. Usa un nombre que explique el cambio, por ejemplo `feat/farm-reports`, `fix/login-validation` o `docs/local-setup`.
3. Mantén cada solicitud de cambio enfocada y evita incluir secretos, archivos `.env`, dependencias instaladas o artefactos generados.

## Validaciones

Ejecuta las validaciones del componente que modificaste antes de abrir una solicitud de cambio.

Backend, desde `backend/`:

```powershell
python -m pip install -r requirements-dev.txt
python -m pytest -q
alembic heads
```

Aplicación Flutter, desde `mobile/`:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

Los cambios de esquema de base de datos deben incluir una migración Alembic y pruebas. Los cambios de endpoints deben conservar el contrato descrito en `docs/CONTRATO_API.md`.

## Solicitudes de cambio

- Explica el problema y la solución.
- Indica cómo probaste el cambio y el resultado.
- Incluye capturas si modifica la interfaz.
- Señala cualquier cambio de configuración, migración o variable de entorno.
- No subas secretos ni datos reales de usuarios.

Las verificaciones de GitHub Actions deben pasar antes de integrar cambios en `main`.
