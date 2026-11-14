import '../../../../core/network/api_client.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/utils/date_format.dart';

/// Alarma de la finca: algo que requiere atención.
class Alerta {
  const Alerta({
    required this.key,
    required this.tipo,
    required this.severidad,
    required this.titulo,
    required this.detalle,
    required this.modulo,
    this.fecha,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) => Alerta(
    key: json['key'] as String,
    tipo: json['tipo'] as String,
    severidad: json['severidad'] as String,
    titulo: json['titulo'] as String,
    detalle: json['detalle'] as String,
    modulo: json['modulo'] as String,
    fecha: parseApiDate(json['fecha']),
  );

  final String key;
  final String tipo;
  // ALTA o MEDIA.
  final String severidad;
  final String titulo;
  final String detalle;
  // sanidad, reproduccion o insumos.
  final String modulo;
  final DateTime? fecha;

  bool get esAlta => severidad == 'ALTA';
}

abstract interface class AlertsRepository {
  Future<List<Alerta>> alertas();
}

class AlertsApiService implements AlertsRepository {
  const AlertsApiService();

  @override
  Future<List<Alerta>> alertas() async {
    final token = AppSession.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException(401, 'Inicia sesión para ver las alarmas.');
    }
    final data = await ApiClient.get('/api/v1/alerts', token: token);
    if (data is! List) {
      throw const FormatException('La respuesta de alarmas no es válida.');
    }
    return data.cast<Map<String, dynamic>>().map(Alerta.fromJson).toList();
  }
}
