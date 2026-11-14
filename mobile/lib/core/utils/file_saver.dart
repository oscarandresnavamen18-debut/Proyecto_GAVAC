import 'dart:typed_data';

import 'file_saver_io.dart' if (dart.library.html) 'file_saver_web.dart'
    as platform;

/// Guarda un archivo generado por la app.
///
/// En web lo descarga con el navegador y devuelve `null`; en móvil y
/// escritorio lo guarda en el dispositivo y devuelve la ruta.
Future<String?> saveFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) =>
    platform.saveFile(bytes: bytes, fileName: fileName, mimeType: mimeType);
