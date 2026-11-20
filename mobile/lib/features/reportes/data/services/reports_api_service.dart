import 'dart:typed_data';

import '../../../../core/network/api_client.dart';
import '../../../../core/session/app_session.dart';

enum ReportFormat {
  pdf('pdf', 'application/pdf'),
  excel(
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );

  const ReportFormat(this.extension, this.mimeType);

  final String extension;
  final String mimeType;
}

abstract interface class ReportsRepository {
  /// [report]: general, animales, sanidad, reproduccion, produccion o insumos.
  Future<Uint8List> download(String report, ReportFormat format);
}

class ReportsApiService implements ReportsRepository {
  const ReportsApiService();

  @override
  Future<Uint8List> download(String report, ReportFormat format) {
    final token = AppSession.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException(401, 'Inicia sesión para descargar reportes.');
    }
    return ApiClient.getBytes(
      '/api/v1/reports/$report?formato=${format.extension}',
      token: token,
    );
  }
}
