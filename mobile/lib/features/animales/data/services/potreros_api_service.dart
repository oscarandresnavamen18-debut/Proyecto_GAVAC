import '../../../../core/network/api_client.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/utils/date_format.dart';

/// Potrero o lote de la finca.
class Potrero {
  const Potrero({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.areaHectareas,
    this.activo = true,
    this.animales = 0,
  });

  factory Potrero.fromJson(Map<String, dynamic> json) => Potrero(
    id: json['id'] as int,
    nombre: json['name'] as String,
    descripcion: json['description'] as String?,
    areaHectareas: (json['area_hectares'] as num?)?.toDouble(),
    activo: json['is_active'] as bool? ?? true,
    animales: json['animal_count'] as int? ?? 0,
  );

  final int id;
  final String nombre;
  final String? descripcion;
  final double? areaHectareas;
  final bool activo;
  // Animales que están hoy en el potrero.
  final int animales;
}

/// Paso de un animal de un potrero a otro.
class MovimientoPotrero {
  const MovimientoPotrero({
    required this.id,
    required this.animalId,
    required this.chapeta,
    required this.fecha,
    this.desde,
    this.hacia,
    this.notas,
    this.registradoPor,
  });

  factory MovimientoPotrero.fromJson(Map<String, dynamic> json) =>
      MovimientoPotrero(
        id: json['id'] as int,
        animalId: json['animal_id'] as int,
        chapeta: json['animal_tag'] as String,
        fecha: parseApiDate(json['moved_at'])!,
        desde: json['from_lot_name'] as String?,
        hacia: json['to_lot_name'] as String?,
        notas: json['notes'] as String?,
        registradoPor: json['created_by_name'] as String?,
      );

  final int id;
  final int animalId;
  final String chapeta;
  final DateTime fecha;
  // null = sin potrero.
  final String? desde;
  final String? hacia;
  final String? notas;
  final String? registradoPor;
}

/// Venta o muerte de un animal.
class SalidaAnimal {
  const SalidaAnimal({
    required this.id,
    required this.animalId,
    required this.chapeta,
    required this.tipo,
    required this.fecha,
    this.nombreAnimal,
    this.precio,
    this.comprador,
    this.causa,
    this.notas,
    this.potrero,
    this.registradoPor,
  });

  factory SalidaAnimal.fromJson(Map<String, dynamic> json) => SalidaAnimal(
    id: json['id'] as int,
    animalId: json['animal_id'] as int,
    chapeta: json['animal_tag'] as String,
    nombreAnimal: json['animal_name'] as String?,
    tipo: json['exit_type'] as String,
    fecha: parseApiDate(json['exit_date'])!,
    precio: (json['price'] as num?)?.toDouble(),
    comprador: json['buyer'] as String?,
    causa: json['cause'] as String?,
    notas: json['notes'] as String?,
    potrero: json['lot_name'] as String?,
    registradoPor: json['created_by_name'] as String?,
  );

  final int id;
  final int animalId;
  final String chapeta;
  final String? nombreAnimal;
  // VENTA o MUERTE.
  final String tipo;
  final DateTime fecha;
  final double? precio;
  final String? comprador;
  final String? causa;
  final String? notas;
  final String? potrero;
  final String? registradoPor;

  bool get esVenta => tipo == 'VENTA';
  String get tipoTexto => esVenta ? 'Venta' : 'Muerte';
}

abstract interface class PotrerosRepository {
  Future<List<Potrero>> listPotreros({bool incluirInactivos = false});
  Future<Potrero> crearPotrero({
    required String nombre,
    String? descripcion,
    double? areaHectareas,
  });
  Future<Potrero> actualizarPotrero(
    int id, {
    String? nombre,
    String? descripcion,
    double? areaHectareas,
    bool? activo,
  });

  /// Mueve los animales al potrero [destinoId] (null = sin potrero).
  Future<List<MovimientoPotrero>> moverAnimales({
    required List<int> animalIds,
    required int? destinoId,
    required DateTime fecha,
    String? notas,
  });
  Future<List<MovimientoPotrero>> listMovimientos({int? animalId});

  Future<SalidaAnimal> registrarSalida({
    required int animalId,
    required String tipo,
    required DateTime fecha,
    double? precio,
    String? comprador,
    String? causa,
    String? notas,
  });
  Future<List<SalidaAnimal>> listSalidas();
  Future<void> anularSalida(int id);
}

class PotrerosApiService implements PotrerosRepository {
  const PotrerosApiService();

  String get _token {
    final token = AppSession.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException(401, 'Inicia sesión para continuar.');
    }
    return token;
  }

  List<T> _list<T>(Object? data, T Function(Map<String, dynamic>) parse) {
    if (data is! List) {
      throw const FormatException(
        'El servidor devolvió una respuesta no válida.',
      );
    }
    return data.cast<Map<String, dynamic>>().map(parse).toList();
  }

  String? _clean(String? text) {
    final value = text?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  @override
  Future<List<Potrero>> listPotreros({bool incluirInactivos = false}) async =>
      _list(
        await ApiClient.get(
          '/api/v1/lots${incluirInactivos ? '?incluir_inactivos=true' : ''}',
          token: _token,
        ),
        Potrero.fromJson,
      );

  @override
  Future<Potrero> crearPotrero({
    required String nombre,
    String? descripcion,
    double? areaHectareas,
  }) async => Potrero.fromJson(
    await ApiClient.post('/api/v1/lots', {
      'nombre': nombre.trim(),
      'descripcion': ?_clean(descripcion),
      'area_hectareas': ?areaHectareas,
    }, token: _token),
  );

  @override
  Future<Potrero> actualizarPotrero(
    int id, {
    String? nombre,
    String? descripcion,
    double? areaHectareas,
    bool? activo,
  }) async => Potrero.fromJson(
    await ApiClient.patch('/api/v1/lots/$id', {
      'nombre': ?nombre?.trim(),
      'descripcion': ?descripcion,
      'area_hectareas': ?areaHectareas,
      'is_active': ?activo,
    }, token: _token),
  );

  @override
  Future<List<MovimientoPotrero>> moverAnimales({
    required List<int> animalIds,
    required int? destinoId,
    required DateTime fecha,
    String? notas,
  }) async => _list(
    await ApiClient.postAction('/api/v1/lots/move', {
      'animal_ids': animalIds,
      'lote_destino_id': destinoId,
      'fecha': isoDate(fecha),
      'notas': ?_clean(notas),
    }, token: _token),
    MovimientoPotrero.fromJson,
  );

  @override
  Future<List<MovimientoPotrero>> listMovimientos({
    int? animalId,
  }) async => _list(
    await ApiClient.get(
      '/api/v1/lots/movements${animalId == null ? '' : '?animal_id=$animalId'}',
      token: _token,
    ),
    MovimientoPotrero.fromJson,
  );

  @override
  Future<SalidaAnimal> registrarSalida({
    required int animalId,
    required String tipo,
    required DateTime fecha,
    double? precio,
    String? comprador,
    String? causa,
    String? notas,
  }) async => SalidaAnimal.fromJson(
    await ApiClient.post('/api/v1/exits', {
      'animal_id': animalId,
      'tipo': tipo,
      'fecha': isoDate(fecha),
      'precio': ?precio,
      'comprador': ?_clean(comprador),
      'causa': ?_clean(causa),
      'notas': ?_clean(notas),
    }, token: _token),
  );

  @override
  Future<List<SalidaAnimal>> listSalidas() async => _list(
    await ApiClient.get('/api/v1/exits', token: _token),
    SalidaAnimal.fromJson,
  );

  @override
  Future<void> anularSalida(int id) =>
      ApiClient.delete('/api/v1/exits/$id', token: _token);
}
