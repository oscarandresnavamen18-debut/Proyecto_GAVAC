import '../../../../core/network/api_client.dart';
import '../../../../core/session/app_session.dart';

class AnimalRecord {
  const AnimalRecord({
    required this.id,
    required this.chapeta,
    required this.raza,
    required this.sexo,
    required this.fechaNacimiento,
    required this.pesoKg,
    this.estado = 'ACTIVO',
    this.loteId,
  });

  factory AnimalRecord.fromJson(Map<String, dynamic> json) => AnimalRecord(
    id: json['id'] as int,
    chapeta: json['tag_id'] as String,
    raza: json['breed'] as String,
    sexo: (json['gender'] as String) == 'MACHO' ? 'Macho' : 'Hembra',
    fechaNacimiento: DateTime.parse(json['birth_date'] as String),
    pesoKg: (json['current_weight'] as num).toDouble(),
    estado: json['status'] as String? ?? 'ACTIVO',
    loteId: json['lote_id'] as int?,
  );

  final int id;
  final String chapeta;
  final String raza;
  final String sexo;
  final DateTime fechaNacimiento;
  final double pesoKg;
  // ACTIVO (en la finca), VENDIDO o MUERTO.
  final String estado;
  // Potrero donde está el animal (null = sin potrero).
  final int? loteId;

  bool get enFinca => estado == 'ACTIVO';

  /// Texto del estado para mostrar: Activo, Vendido o Muerto.
  String get estadoTexto =>
      estado.isEmpty ? '' : estado[0] + estado.substring(1).toLowerCase();

  String get especie => 'Bovino';
  String get peso => pesoKg == pesoKg.roundToDouble()
      ? '${pesoKg.toStringAsFixed(0)} kg'
      : '${pesoKg.toStringAsFixed(1)} kg';

  String get edad {
    final today = DateTime.now();
    var months =
        (today.year - fechaNacimiento.year) * 12 +
        today.month -
        fechaNacimiento.month;
    if (today.day < fechaNacimiento.day) months--;
    if (months < 12) return '$months meses';
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    return remainingMonths == 0
        ? '$years ${years == 1 ? 'año' : 'años'}'
        : '$years ${years == 1 ? 'año' : 'años'} y $remainingMonths meses';
  }
}

/// Lee un peso escrito por el usuario: acepta "230", "230,5", "230kg" o
/// "230 KG". Devuelve null si no es un número mayor que cero.
double? parsePesoKg(String? value) {
  final cleaned = (value ?? '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s*(kgs?|kilos?|kilogramos?)$'), '')
      .replaceAll(',', '.')
      .trim();
  final peso = double.tryParse(cleaned);
  return peso != null && peso > 0 ? peso : null;
}

abstract interface class AnimalRepository {
  /// Todos los animales de la finca, incluidos los vendidos y muertos.
  Future<List<AnimalRecord>> listAnimals();

  Future<AnimalRecord> createAnimal({
    required String chapeta,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required double pesoKg,
    int? loteId,
  });

  Future<AnimalRecord> updateAnimal(
    int id, {
    required String chapeta,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required double pesoKg,
  });

  Future<void> deleteAnimal(int id);
}

class AnimalApiService implements AnimalRepository {
  const AnimalApiService();

  String get _token {
    final token = AppSession.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException(
        401,
        'Inicia sesión para consultar los animales.',
      );
    }
    return token;
  }

  @override
  Future<List<AnimalRecord>> listAnimals() async {
    final response = await ApiClient.get(
      '/api/v1/animals?estado=todos',
      token: _token,
    );
    if (response is! List) {
      throw const FormatException('La respuesta de animales no es válida.');
    }
    return response
        .map((animal) => AnimalRecord.fromJson(animal as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AnimalRecord> createAnimal({
    required String chapeta,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required double pesoKg,
    int? loteId,
  }) async {
    final farms = await ApiClient.get('/api/v1/farms', token: _token);
    if (farms is! List || farms.isEmpty) {
      throw const ApiException(
        403,
        'Tu cuenta no tiene una finca asignada. Contacta al administrador.',
      );
    }
    // El administrador puede tener varias fincas: se usa la finca activa.
    final farm = farms.cast<Map<String, dynamic>>().firstWhere(
      (f) => f['id'] == AppSession.farmId,
      orElse: () => farms.first as Map<String, dynamic>,
    );
    final response = await ApiClient.post('/api/v1/animals', {
      'farm_id': farm['id'] as int,
      'tag_id': chapeta,
      'gender': sexo == 'Macho' ? 'MACHO' : 'HEMBRA',
      'birth_date': fechaNacimiento.toIso8601String().split('T').first,
      'breed': raza,
      'current_weight': pesoKg,
      'lote_id': ?loteId,
    }, token: _token);
    return AnimalRecord.fromJson(response);
  }

  @override
  Future<AnimalRecord> updateAnimal(
    int id, {
    required String chapeta,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required double pesoKg,
  }) async {
    final response = await ApiClient.patch('/api/v1/animals/$id', {
      'tag_id': chapeta,
      'gender': sexo == 'Macho' ? 'MACHO' : 'HEMBRA',
      'birth_date': fechaNacimiento.toIso8601String().split('T').first,
      'breed': raza,
      'current_weight': pesoKg,
    }, token: _token);
    return AnimalRecord.fromJson(response);
  }

  @override
  Future<void> deleteAnimal(int id) =>
      ApiClient.delete('/api/v1/animals/$id', token: _token);
}
