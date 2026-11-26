import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';

class AppSession {
  static String userName = 'Admin';
  static String farmName = 'Hacienda El Paraíso';
  static String? accessToken;
  static String? role;
  static int? farmId;
  static List<String>? permissions;

  static bool get isDueno => role == 'DUENO';
  static bool get isAdmin => role == null || role == 'ADMIN' || role == 'DUENO';

  static bool canAccess(String module) =>
      permissions == null || permissions!.contains(module);

  static Future<void> saveSession(String token) async {
    accessToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gavac_access_token', token);
    } catch (_) {}
  }

  static Future<bool> tryRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('gavac_access_token');
      if (token == null || token.isEmpty) {
        await clear();
        return false;
      }
      accessToken = token;
      await loadProfile();
      return accessToken != null;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await clear();
        return false;
      }
      return accessToken != null;
    } catch (_) {
      await clear();
      return false;
    }
  }

  static Future<void> loadProfile() async {
    final token = accessToken;
    if (token == null || token.isEmpty) return;
    try {
      final me = await ApiClient.get(
        '/api/v1/auth/me',
        token: token,
      ) as Map<String, dynamic>;
      userName = me['full_name'] as String? ?? userName;
      role = me['role'] as String?;
      farmId = me['farm_id'] as int?;
      permissions = (me['permissions'] as List<dynamic>? ?? const [])
          .cast<String>()
          .toList();
      if (farmId != null) {
        final farms =
            await ApiClient.get('/api/v1/farms', token: token) as List<dynamic>;
        for (final farm in farms.cast<Map<String, dynamic>>()) {
          if (farm['id'] == farmId) farmName = farm['name'] as String;
        }
      }
    } catch (error) {
      if (error is ApiException &&
          (error.statusCode == 401 || error.statusCode == 403)) {
        await clear();
        rethrow;
      }
      debugPrint('No se pudo cargar el perfil del usuario: $error');
    }
  }

  static Future<void> clear() async {
    userName = 'Admin';
    farmName = 'Hacienda El Paraíso';
    accessToken = null;
    role = null;
    farmId = null;
    permissions = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('gavac_access_token');
    } catch (_) {}
  }
}

