import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String?> saveFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  // Escritorio: carpeta Descargas. Móvil: documentos de la app.
  Directory? directory;
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    directory = await getDownloadsDirectory();
  }
  directory ??= await getApplicationDocumentsDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
