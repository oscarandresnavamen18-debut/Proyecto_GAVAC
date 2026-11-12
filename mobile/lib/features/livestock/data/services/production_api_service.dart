import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_session.dart';

class AnimalOption {
  const AnimalOption({required this.id, required this.tag});

  factory AnimalOption.fromJson(Map<String, dynamic> json) => AnimalOption(
        id: json['id'] as int,
        tag: json['tag_id'] as String,
      );

  final int id;
  final String tag;
}

class ProductionRecord {
  const ProductionRecord({
    required this.id,
    required this.animalId,
    required this.animalTag,
    required this.recordType,
    required this.quantity,
    required this.unit,
    required this.recordedAt,
  });

  factory ProductionRecord.fromJson(Map<String, dynamic> json) =>
      ProductionRecord(
        id: json['id'] as int,
        animalId: json['animal_id'] as int,
        animalTag: json['animal_tag'] as String,
        recordType: json['record_type'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
      );

  final int id;
  final int animalId;
  final String animalTag;
  final String recordType;
  final double quantity;
  final String unit;
  final DateTime recordedAt;

  bool get isMilk => recordType == 'MILK';
}

abstract interface class ProductionRepository {
  Future<List<AnimalOption>> listAnimals();
  Future<List<ProductionRecord>> listRecords();
  Future<List<ProductionRecord>> createRecords({
    required int animalId,
    double? milkLiters,
    double? weightKg,
  });
  Future<void> deleteRecord(int id);
}

class ProductionApiService implements ProductionRepository {
  const ProductionApiService();

  String get _token {
    final token = AppSession.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException(
        401,
        'Inicia sesión para consultar la producción.',
      );
    }
    return token;
  }

  @override
  Future<List<AnimalOption>> listAnimals() async {
    final response = await ApiClient.get('/api/v1/animals', token: _token);
    if (response is! List) {
      throw const FormatException('La respuesta de animales no es válida.');
    }
    return response
        .map((animal) => AnimalOption.fromJson(animal as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ProductionRecord>> listRecords() async =>
      _parseRecords(await ApiClient.get('/api/v1/production', token: _token));

  @override
  Future<List<ProductionRecord>> createRecords({
    required int animalId,
    double? milkLiters,
    double? weightKg,
  }) async {
    final response = await ApiClient.post(
      '/api/v1/production',
      {
        'animal_id': animalId,
        if (milkLiters != null) 'milk_liters': milkLiters,
        if (weightKg != null) 'weight_kg': weightKg,
      },
      token: _token,
    );
    return _parseRecords(response);
  }

  @override
  Future<void> deleteRecord(int id) =>
      ApiClient.delete('/api/v1/production/$id', token: _token);

  List<ProductionRecord> _parseRecords(dynamic response) {
    if (response is! List) {
      throw const FormatException(
        'La respuesta de los registros de producción no es válida.',
      );
    }
    return response
        .map(
          (record) => ProductionRecord.fromJson(record as Map<String, dynamic>),
        )
        .toList();
  }
}
