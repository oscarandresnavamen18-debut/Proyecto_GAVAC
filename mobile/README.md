# Aplicación móvil

Cliente multiplataforma de GAVAC desarrollado con Flutter y Material 3.

## Estructura

- `lib/core/`: cliente HTTP, rutas, sesión, tema y utilidades compartidas.
- `lib/features/`: un módulo por opción del menú (`auth`, `dashboard`, `animales`, `sanidad`, `reproduccion`, `produccion`, `insumos`, `reportes`, `administracion`), cada uno con `data/` (modelos y servicios) y `presentation/` (pantallas y componentes).
- `test/`: pruebas de widgets con la misma estructura de `lib/`.

Más detalle en [docs/ARQUITECTURA.md](../docs/ARQUITECTURA.md).

## Requisitos

- Flutter 3.47 o posterior, con Dart 3.13 o posterior.
- Backend disponible en `http://localhost:8001` para web y escritorio, o en `http://10.0.2.2:8001` para el emulador Android.

## Desarrollo

Desde esta carpeta:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

No ejecutes `flutter create` sobre este proyecto existente. Para Flutter Web, puedes configurar la URL del backend con:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8001
```
