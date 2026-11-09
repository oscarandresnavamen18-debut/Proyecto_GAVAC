import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';

class AnimalApiService {
  // GET /api/v1/animals
  static Future<List<dynamic>> getAnimals(String token, {int skip = 0, int limit = 100}) async {
    final url = Uri.parse('${ApiClient.baseUrl}/api/v1/animals?skip=$skip&limit=$limit');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data as List<dynamic>;
      } else {
        throw Exception(data['detail'] ?? 'Error al obtener animales');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // POST /api/v1/animals
  static Future<Map<String, dynamic>> createAnimal(
    String token, {
    required int farmId,
    required String tagId,
    String? name,
    required String gender,
    required String birthDate,
    required String breed,
    String? color,
    required double currentWeight,
    String status = 'ACTIVO',
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/api/v1/animals');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'farm_id': farmId,
          'tag_id': tagId,
          if (name != null) 'name': name,
          'gender': gender,
          'birth_date': birthDate,
          'breed': breed,
          if (color != null) 'color': color,
          'current_weight': currentWeight,
          'status': status,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data as Map<String, dynamic>;
      } else {
        throw Exception(data['detail'] ?? 'Error al registrar animal');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
