import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_session.dart';
import '../../../../core/utils/date_format.dart';
import '../../../livestock/data/services/production_api_service.dart'
    show AnimalOption;

export '../../../livestock/data/services/production_api_service.dart'
    show AnimalOption;

class HealthRecord {
  const HealthRecord({
    required this.id,
    required this.animalId,
    required this.animalTag,
    required this.recordType,
    required this.diagnosis,
    required this.recordedAt,
    required this.status,
    this.animalName,
    this.treatment,
    this.dose,
    this.veterinarian,
    this.nextCheckAt,
    this.notes,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) => HealthRecord(
        id: json['id'] as int,
        animalId: json['animal_id'] as int,
        animalTag: json['animal_tag'] as String,
        animalName: json['animal_name'] as String?,
        recordType: json['record_type'] as String,
        diagnosis: json['diagnosis'] as String? ?? '',
        treatment: json['treatment'] as String?,
        dose: json['dose'] as String?,
        veterinarian: json['veterinarian'] as String?,
        recordedAt: parseApiDate(json['recorded_at'])!,
        nextCheckAt: parseApiDate(json['next_check_at']),
        notes: json['notes'] as String?,
        status: json['status'] as String,
      );

  final int id;
  final int animalId;
  final String animalTag;
  final String? animalName;
  // VACUNA o TRATAMIENTO.
  final String recordType;
  final String diagnosis;
  final String? treatment;
  final String? dose;
  final String? veterinarian;
  final DateTime recordedAt;
  final DateTime? nextCheckAt;
  final String? notes;
  // VIGENTE, PROXIMO_A_VENCER, VENCIDO, EN_TRATAMIENTO o FINALIZADO.
  final String status;

  bool get isVaccine => recordType == 'VACUNA';
}

abstract interface class HealthRepository {
  Future<List<AnimalOption>> listAnimals();
  Future<List<HealthRecord>> listRecords();
  Future<HealthRecord> createRecord({
    required int animalId,
    required String recordType,
    required String diagnosis,
    required DateTime recordedAt,
    String? treatment,
    String? dose,
    String? veterinarian,
    DateTime? nextCheckAt,
    String? notes,
  });
  Future<void> deleteRecord(int id);
}

class HealthApiService implements HealthRepository {
  const HealthApiService();

  String get _token {
    final token = AppSession.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException(401, 'Inicia sesión para consultar la sanidad.');
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
  Future<List<HealthRecord>> listRecords() async {
    final response =
        await ApiClient.get('/api/v1/health-records', token: _token);
    if (response is! List) {
      throw const FormatException(
          'La respuesta de los registros sanitarios no es válida.');
    }
    return response
        .map((item) => HealthRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<HealthRecord> createRecord({
    required int animalId,
    required String recordType,
    required String diagnosis,
    required DateTime recordedAt,
    String? treatment,
    String? dose,
    String? veterinarian,
    DateTime? nextCheckAt,
    String? notes,
  }) async {
    final response = await ApiClient.post(
      '/api/v1/health-records',
      {
        'animal_id': animalId,
        'record_type': recordType,
        'diagnosis': diagnosis,
        'recorded_at': isoDate(recordedAt),
        if (treatment != null && treatment.isNotEmpty) 'treatment': treatment,
        if (dose != null && dose.isNotEmpty) 'dose': dose,
        if (veterinarian != null && veterinarian.isNotEmpty)
          'veterinarian': veterinarian,
        if (nextCheckAt != null) 'next_check_at': isoDate(nextCheckAt),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
      token: _token,
    );
    return HealthRecord.fromJson(response);
  }

  @override
  Future<void> deleteRecord(int id) =>
      ApiClient.delete('/api/v1/health-records/$id', token: _token);
}
