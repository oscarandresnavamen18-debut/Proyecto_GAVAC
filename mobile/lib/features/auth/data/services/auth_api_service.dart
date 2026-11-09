import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';

class AuthApiService {
  // POST /api/v1/auth/login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    return await ApiClient.post('/api/v1/auth/login', {
      'email': email,
      'password': password,
    });
  }

  // POST /api/v1/auth/register
  static Future<Map<String, dynamic>> register(String nombre, String email, String password) async {
    return await ApiClient.post('/api/v1/auth/register', {
      'nombre': nombre,
      'email': email,
      'password': password,
    });
  }

  // GET /api/v1/auth/me
  static Future<Map<String, dynamic>> getMe(String token) async {
    final url = Uri.parse('${ApiClient.baseUrl}/api/v1/auth/me');
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
        return data;
      } else {
        throw Exception(data['detail'] ?? 'Error al obtener usuario');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
