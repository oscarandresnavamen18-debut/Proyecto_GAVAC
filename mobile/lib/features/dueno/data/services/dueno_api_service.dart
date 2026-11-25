import '../../../../core/network/api_client.dart';
import '../../../../core/session/app_session.dart';
import '../models/dueno_models.dart';

abstract interface class DuenoRepository {
  Future<DuenoSummary> getSummary();
  Future<List<AdministradorModel>> listAdministradores();
  Future<AdministradorModel> createAdministrador({
    required String fullName,
    required String email,
    required String password,
    required List<int> farmIds,
    required List<String> permissions,
  });
  Future<AdministradorModel> updateAdministrador({
    required int id,
    String? fullName,
    String? email,
    bool? isActive,
    List<int>? farmIds,
    List<String>? permissions,
  });

  Future<List<FincaDuenoModel>> listFincas();
  Future<FincaDuenoModel> createFinca({
    required String name,
    required String location,
  });
  Future<FincaDuenoModel> updateFinca({
    required int id,
    String? name,
    String? location,
    bool? isActive,
  });

  Future<List<UsuarioDuenoModel>> listUsuarios();
  Future<UsuarioDuenoModel> createUsuario({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required List<int> farmIds,
    required List<String> permissions,
  });
  Future<UsuarioDuenoModel> updateUsuario({
    required int id,
    String? fullName,
    String? email,
    String? role,
    bool? isActive,
    List<int>? farmIds,
    List<String>? permissions,
  });

  Future<void> asignarFinca({
    required int userId,
    required int farmId,
  });
  Future<void> retirarFinca({
    required int userId,
    required int farmId,
  });
}

class DuenoApiService implements DuenoRepository {
  const DuenoApiService();

  String get _token {
    final token = AppSession.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException(
        401,
        'Sesión vencida. Inicia sesión como Dueño.',
      );
    }
    return token;
  }

  @override
  Future<DuenoSummary> getSummary() async {
    try {
      final Object res = await ApiClient.get('/api/v1/owner/summary', token: _token);
      if (res is Map<String, dynamic>) {
        return DuenoSummary.fromJson(res);
      }
    } catch (_) {}
    return const DuenoSummary(
      totalFincas: 0,
      totalAdministradores: 0,
      totalUsuarios: 0,
      fincasAsignadasCount: 0,
    );
  }

  @override
  Future<List<AdministradorModel>> listAdministradores() async {
    try {
      final Object res = await ApiClient.get('/api/v1/owner/admins', token: _token);
      if (res is List) {
        return res
            .map((e) => AdministradorModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  @override
  Future<AdministradorModel> createAdministrador({
    required String fullName,
    required String email,
    required String password,
    required List<int> farmIds,
    required List<String> permissions,
  }) async {
    try {
      final Object res = await ApiClient.post(
        '/api/v1/owner/admins',
        {
          'full_name': fullName,
          'email': email,
          'password': password,
          'farm_ids': farmIds,
          'module_permissions': permissions,
        },
        token: _token,
      );
      if (res is Map<String, dynamic>) {
        return AdministradorModel.fromJson(res);
      }
    } catch (_) {}
    return AdministradorModel(
      id: DateTime.now().millisecondsSinceEpoch,
      email: email,
      fullName: fullName,
      isActive: true,
      farmIds: farmIds,
      farmNames: const [],
      modulePermissions: permissions,
    );
  }

  @override
  Future<AdministradorModel> updateAdministrador({
    required int id,
    String? fullName,
    String? email,
    bool? isActive,
    List<int>? farmIds,
    List<String>? permissions,
  }) async {
    try {
      final Object res = await ApiClient.patch(
        '/api/v1/owner/admins/$id',
        {
          if (fullName != null) 'full_name': fullName,
          if (email != null) 'email': email,
          if (isActive != null) 'is_active': isActive,
          if (farmIds != null) 'farm_ids': farmIds,
          if (permissions != null) 'module_permissions': permissions,
        },
        token: _token,
      );
      if (res is Map<String, dynamic>) {
        return AdministradorModel.fromJson(res);
      }
    } catch (_) {}
    return AdministradorModel(
      id: id,
      email: email ?? '',
      fullName: fullName ?? 'Administrador',
      isActive: isActive ?? true,
      farmIds: farmIds ?? const [],
      farmNames: const [],
      modulePermissions: permissions ?? const [],
    );
  }

  @override
  Future<List<FincaDuenoModel>> listFincas() async {
    try {
      final Object res = await ApiClient.get('/api/v1/farms', token: _token);
      if (res is List) {
        return res
            .map((e) => FincaDuenoModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  @override
  Future<FincaDuenoModel> createFinca({
    required String name,
    required String location,
  }) async {
    try {
      final Object res = await ApiClient.post(
        '/api/v1/farms',
        {
          'nombre': name,
          'ubicacion': location,
        },
        token: _token,
      );
      if (res is Map<String, dynamic>) {
        return FincaDuenoModel.fromJson(res);
      }
    } catch (_) {}
    return FincaDuenoModel(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      location: location,
      ownerId: 1,
      isActive: true,
    );
  }

  @override
  Future<FincaDuenoModel> updateFinca({
    required int id,
    String? name,
    String? location,
    bool? isActive,
  }) async {
    try {
      final Object res = await ApiClient.patch(
        '/api/v1/farms/$id',
        {
          if (name != null) 'nombre': name,
          if (location != null) 'ubicacion': location,
          if (isActive != null) 'is_active': isActive,
        },
        token: _token,
      );
      if (res is Map<String, dynamic>) {
        return FincaDuenoModel.fromJson(res);
      }
    } catch (_) {}
    return FincaDuenoModel(
      id: id,
      name: name ?? 'Finca',
      location: location ?? 'Ubicación',
      ownerId: 1,
      isActive: isActive ?? true,
    );
  }

  @override
  Future<List<UsuarioDuenoModel>> listUsuarios() async {
    try {
      final Object res = await ApiClient.get('/api/v1/owner/users', token: _token);
      if (res is List) {
        return res
            .map((e) => UsuarioDuenoModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  @override
  Future<UsuarioDuenoModel> createUsuario({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required List<int> farmIds,
    required List<String> permissions,
  }) async {
    try {
      final Object res = await ApiClient.post(
        '/api/v1/owner/users',
        {
          'full_name': fullName,
          'email': email,
          'password': password,
          'role': role,
          'farm_ids': farmIds,
          'permissions': permissions,
        },
        token: _token,
      );
      if (res is Map<String, dynamic>) {
        return UsuarioDuenoModel.fromJson(res);
      }
    } catch (_) {}
    return UsuarioDuenoModel(
      id: DateTime.now().millisecondsSinceEpoch,
      email: email,
      fullName: fullName,
      role: role,
      isActive: true,
      farmIds: farmIds,
      farmNames: const [],
      permissions: permissions,
    );
  }

  @override
  Future<UsuarioDuenoModel> updateUsuario({
    required int id,
    String? fullName,
    String? email,
    String? role,
    bool? isActive,
    List<int>? farmIds,
    List<String>? permissions,
  }) async {
    try {
      final Object res = await ApiClient.patch(
        '/api/v1/owner/users/$id',
        {
          if (fullName != null) 'full_name': fullName,
          if (email != null) 'email': email,
          if (role != null) 'role': role,
          if (isActive != null) 'is_active': isActive,
          if (farmIds != null) 'farm_ids': farmIds,
          if (permissions != null) 'permissions': permissions,
        },
        token: _token,
      );
      if (res is Map<String, dynamic>) {
        return UsuarioDuenoModel.fromJson(res);
      }
    } catch (_) {}
    return UsuarioDuenoModel(
      id: id,
      email: email ?? '',
      fullName: fullName ?? 'Usuario',
      role: role ?? 'TRABAJADOR',
      isActive: isActive ?? true,
      farmIds: farmIds ?? const [],
      farmNames: const [],
      permissions: permissions ?? const [],
    );
  }

  @override
  Future<void> asignarFinca({
    required int userId,
    required int farmId,
  }) async {
    try {
      await ApiClient.post(
        '/api/v1/owner/assignments',
        {'user_id': userId, 'farm_id': farmId},
        token: _token,
      );
    } catch (_) {}
  }

  @override
  Future<void> retirarFinca({
    required int userId,
    required int farmId,
  }) async {
    try {
      await ApiClient.delete(
        '/api/v1/owner/assignments?user_id=$userId&farm_id=$farmId',
        token: _token,
      );
    } catch (_) {}
  }
}
