import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';

class AppSession {
  // Datos del usuario (por defecto)
  static String userName = 'Admin';
  static String farmName = 'Hacienda El Paraíso';
  static String? accessToken;
  // Rol devuelto por el backend: ADMIN, VETERINARIO o MAYORDOMO.
  static String? role;
  static int? farmId;
  // Módulos habilitados (registro, sanidad, reproduccion, produccion,
  // insumos, reportes). null = perfil aún no cargado.
  static List<String>? permissions;

  static bool get isAdmin => role == null || role == 'ADMIN';

  /// Filtro visual del menú. El backend valida los permisos en cada petición,
  /// así que mientras no haya perfil cargado se muestran todos los módulos.
  static bool canAccess(String module) =>
      permissions == null || permissions!.contains(module);

  /// Guarda el token en SharedPreferences para persistencia.
  static Future<void> saveSession(String token) async {
    accessToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gavac_access_token', token);
    } catch (_) {}
  }

  /// Intenta restaurar la sesión desde SharedPreferences al iniciar la app.
  static Future<bool> tryRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('gavac_access_token');
      if (token == null || token.isEmpty) return false;
      accessToken = token;
      await loadProfile();
      return true;
    } catch (_) {
      await clear();
      return false;
    }
  }

  /// Carga nombre, rol, permisos y finca activa del usuario autenticado.
  static Future<void> loadProfile() async {
    final token = accessToken;
    if (token == null) return;
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
    } catch (e) {
      await clear();
      rethrow;
    }
  }

  // Método para limpiar la sesión (para cuando cierre sesión)
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
