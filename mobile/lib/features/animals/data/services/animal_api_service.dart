import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_session.dart';

class AnimalRecord {
  const AnimalRecord({
    required this.id,
    required this.chapeta,
    required this.raza,
    required this.sexo,
    required this.fechaNacimiento,
    required this.pesoKg,
  });

  factory AnimalRecord.fromJson(Map<String, dynamic> json) => AnimalRecord(
        id: json['id'] as int,
        chapeta: json['tag_id'] as String,
        raza: json['breed'] as String,
        sexo: (json['gender'] as String) == 'MACHO' ? 'Macho' : 'Hembra',
        fechaNacimiento: DateTime.parse(json['birth_date'] as String),
        pesoKg: (json['current_weight'] as num).toDouble(),
      );

  final int id;
  final String chapeta;
  final String raza;
  final String sexo;
  final DateTime fechaNacimiento;
  final double pesoKg;

  String get especie => 'Bovino';
  String get estadoSincronizacion => 'Sincronizado';
  String get peso => '${pesoKg.toStringAsFixed(0)} kg';

  String get edad {
    final today = DateTime.now();
    var months = (today.year - fechaNacimiento.year) * 12 +
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

abstract interface class AnimalRepository {
  Future<List<AnimalRecord>> listAnimals();

  Future<AnimalRecord> createAnimal({
    required String chapeta,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required double pesoKg,
  });
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
    final response = await ApiClient.get('/api/v1/animals', token: _token);
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
  }) async {
    final farms = await ApiClient.get('/api/v1/farms', token: _token);
    if (farms is! List || farms.isEmpty) {
      throw const ApiException(
        403,
        'Tu cuenta no tiene una finca asignada. Contacta al administrador.',
      );
    }
    final farm = farms.first as Map<String, dynamic>;
    final response = await ApiClient.post(
      '/api/v1/animals',
      {
        'farm_id': farm['id'] as int,
        'tag_id': chapeta,
        'gender': sexo == 'Macho' ? 'MACHO' : 'HEMBRA',
        'birth_date': fechaNacimiento.toIso8601String().split('T').first,
        'breed': raza,
        'current_weight': pesoKg,
        'status': 'ACTIVO',
      },
      token: _token,
    );
    return AnimalRecord.fromJson(response);
  }
}
