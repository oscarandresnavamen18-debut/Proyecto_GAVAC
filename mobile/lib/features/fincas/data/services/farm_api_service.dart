import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';

class FarmApiService {
  // GET /api/v1/farms
  static Future<List<dynamic>> getFarms(String token) async {
    final url = Uri.parse('${ApiClient.baseUrl}/api/v1/farms');
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
        throw Exception(data['detail'] ?? 'Error al obtener fincas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // POST /api/v1/farms
  static Future<Map<String, dynamic>> createFarm(String token, String nombre, String? ubicacion) async {
    final url = Uri.parse('${ApiClient.baseUrl}/api/v1/farms');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nombre': nombre,
          if (ubicacion != null) 'ubicacion': ubicacion,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data as Map<String, dynamic>;
      } else {
        throw Exception(data['detail'] ?? 'Error al crear finca');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
