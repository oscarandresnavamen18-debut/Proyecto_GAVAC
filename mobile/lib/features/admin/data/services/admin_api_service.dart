import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_session.dart';
import '../models/finca_model.dart';
import '../models/usuario_model.dart';

/// Endpoints de administración (solo para el rol ADMIN).
class AdminApiService {
  static String get _token {
    final token = AppSession.accessToken;
    if (token == null) {
      throw const ApiException(401, 'La sesión venció. Inicia sesión de nuevo.');
    }
    return token;
  }

  // ---------- Fincas ----------

  static Future<List<AdminFincaModel>> listarFincas() async {
    final data = await ApiClient.get('/api/v1/farms', token: _token) as List;
    return data
        .cast<Map<String, dynamic>>()
        .map(AdminFincaModel.fromJson)
        .toList();
  }

  static Future<AdminFincaModel> crearFinca(String nombre, String ubicacion) async {
    final data = await ApiClient.post(
      '/api/v1/farms',
      {'nombre': nombre, 'ubicacion': ubicacion},
      token: _token,
    );
    return AdminFincaModel.fromJson(data);
  }

  static Future<AdminFincaModel> editarFinca(
    int id,
    String nombre,
    String ubicacion,
  ) async {
    final data = await ApiClient.patch(
      '/api/v1/farms/$id',
      {'nombre': nombre, 'ubicacion': ubicacion},
      token: _token,
    );
    return AdminFincaModel.fromJson(data);
  }

  /// Cambia la finca con la que trabaja el administrador.
  static Future<AdminFincaModel> activarFinca(int id) async {
    final data = await ApiClient.post(
      '/api/v1/farms/$id/activate',
      const {},
      token: _token,
    );
    return AdminFincaModel.fromJson(data);
  }

  // ---------- Usuarios ----------

  static Future<List<AdminUsuarioModel>> listarUsuarios() async {
    final data = await ApiClient.get('/api/v1/users', token: _token) as List;
    return data
        .cast<Map<String, dynamic>>()
        .map(AdminUsuarioModel.fromJson)
        .toList();
  }

  static Future<AdminUsuarioModel> crearUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String rol,
    required int fincaId,
  }) async {
    final data = await ApiClient.post(
      '/api/v1/users',
      {
        'nombre': nombre,
        'email': correo,
        'password': password,
        'role': rol,
        'farm_id': fincaId,
      },
      token: _token,
    );
    return AdminUsuarioModel.fromJson(data);
  }

  static Future<AdminUsuarioModel> actualizarUsuario(
    int id, {
    String? nombre,
    String? rol,
    int? fincaId,
    bool? activo,
    List<String>? permisos,
    String? password,
  }) async {
    final data = await ApiClient.patch(
      '/api/v1/users/$id',
      {
        if (nombre != null) 'nombre': nombre,
        if (rol != null) 'role': rol,
        if (fincaId != null) 'farm_id': fincaId,
        if (activo != null) 'is_active': activo,
        if (permisos != null) 'permisos': permisos,
        if (password != null) 'password': password,
      },
      token: _token,
    );
    return AdminUsuarioModel.fromJson(data);
  }
}
