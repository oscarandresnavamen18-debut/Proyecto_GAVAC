import '../../../../core/network/api_client.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/utils/date_format.dart';
import '../../../animales/data/models/animal_option.dart';

export '../../../animales/data/models/animal_option.dart';

/// Tipos de evento: clave del API → nombre visible.
const Map<String, String> breedingEventLabels = {
  'CELO': 'Celo',
  'INSEMINACION': 'Inseminación',
  'PRENEZ': 'Preñez',
  'PARTO': 'Parto',
};

class BreedingRecord {
  const BreedingRecord({
    required this.id,
    required this.animalId,
    required this.animalTag,
    required this.recordType,
    required this.recordedAt,
    required this.status,
    this.animalName,
    this.expectedAt,
    this.notes,
  });

  factory BreedingRecord.fromJson(Map<String, dynamic> json) => BreedingRecord(
    id: json['id'] as int,
    animalId: json['animal_id'] as int,
    animalTag: json['animal_tag'] as String,
    animalName: json['animal_name'] as String?,
    recordType: json['record_type'] as String,
    recordedAt: parseApiDate(json['recorded_at'])!,
    expectedAt: parseApiDate(json['expected_at']),
    notes: json['notes'] as String?,
    status: json['status'] as String,
  );

  final int id;
  final int animalId;
  final String animalTag;
  final String? animalName;
  final String recordType;
  final DateTime recordedAt;
  final DateTime? expectedAt;
  final String? notes;
  final String status;

  String get label => breedingEventLabels[recordType] ?? recordType;
}

abstract interface class BreedingRepository {
  Future<List<AnimalOption>> listAnimals();
  Future<List<BreedingRecord>> listRecords();
  Future<BreedingRecord> createRecord({
    required int animalId,
    required String recordType,
    required DateTime recordedAt,
    String? notes,
  });
  Future<void> deleteRecord(int id);
}

class BreedingApiService implements BreedingRepository {
  const BreedingApiService();

  String get _token {
    final token = AppSession.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException(
        401,
        'Inicia sesión para consultar la reproducción.',
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
  Future<List<BreedingRecord>> listRecords() async {
    final response = await ApiClient.get(
      '/api/v1/breeding-records',
      token: _token,
    );
    if (response is! List) {
      throw const FormatException(
        'La respuesta de los eventos reproductivos no es válida.',
      );
    }
    return response
        .map((item) => BreedingRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BreedingRecord> createRecord({
    required int animalId,
    required String recordType,
    required DateTime recordedAt,
    String? notes,
  }) async {
    final response = await ApiClient.post('/api/v1/breeding-records', {
      'animal_id': animalId,
      'record_type': recordType,
      'recorded_at': isoDate(recordedAt),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    }, token: _token);
    return BreedingRecord.fromJson(response);
  }

  @override
  Future<void> deleteRecord(int id) =>
      ApiClient.delete('/api/v1/breeding-records/$id', token: _token);
}
