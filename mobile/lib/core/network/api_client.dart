import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  static const _webBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8001',
  );

  static String get baseUrl {
    if (kIsWeb) {
      return _webBaseUrl;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8001';
    } else {
      return 'http://localhost:8001';
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(token, json: true),
        body: jsonEncode(body),
      ),
    );
    final data = _decodeResponse(response);
    if (data is Map<String, dynamic>) return data;
    throw const FormatException(
        'El servidor devolvió una respuesta no válida.');
  }

  static Future<dynamic> get(String endpoint, {String? token}) async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(token),
      ),
    );
    return _decodeResponse(response);
  }

  static Future<void> delete(String endpoint, {String? token}) async {
    final response = await _send(
      () => http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(token),
      ),
    );
    _decodeResponse(response, allowEmptyBody: true);
  }

  static Map<String, String> _headers(String? token, {bool json = false}) => {
        if (json) 'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } on http.ClientException catch (error) {
      throw ApiException(0, 'No se pudo conectar con el servidor: $error');
    }
  }

  static dynamic _decodeResponse(
    http.Response response, {
    bool allowEmptyBody = false,
  }) {
    final body = response.body.trim();
    dynamic data;
    if (body.isNotEmpty) {
      try {
        data = jsonDecode(body);
      } on FormatException {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw ApiException(
            response.statusCode,
            'Error del servidor (${response.statusCode}).',
          );
        }
        throw const FormatException(
          'El servidor devolvió una respuesta no válida.',
        );
      }
    } else if (!allowEmptyBody &&
        response.statusCode >= 200 &&
        response.statusCode < 300) {
      throw const FormatException('El servidor devolvió una respuesta vacía.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = data is Map<String, dynamic> ? data['detail'] : null;
      throw ApiException(
        response.statusCode,
        detail?.toString() ?? 'Error del servidor (${response.statusCode}).',
      );
    }
    return data;
  }
}
