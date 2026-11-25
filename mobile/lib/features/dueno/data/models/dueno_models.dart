class DuenoSummary {
  final int totalFincas;
  final int totalAdministradores;
  final int totalUsuarios;
  final int fincasAsignadasCount;

  const DuenoSummary({
    required this.totalFincas,
    required this.totalAdministradores,
    required this.totalUsuarios,
    required this.fincasAsignadasCount,
  });

  factory DuenoSummary.fromJson(Map<String, dynamic> json) {
    return DuenoSummary(
      totalFincas: (json['total_fincas'] as num?)?.toInt() ?? 0,
      totalAdministradores: (json['total_administradores'] as num?)?.toInt() ?? 0,
      totalUsuarios: (json['total_usuarios'] as num?)?.toInt() ?? 0,
      fincasAsignadasCount: (json['fincas_asignadas'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdministradorModel {
  final int id;
  final String email;
  final String fullName;
  final bool isActive;
  final List<int> farmIds;
  final List<String> farmNames;
  final List<String> modulePermissions;

  const AdministradorModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
    required this.farmIds,
    required this.farmNames,
    required this.modulePermissions,
  });

  factory AdministradorModel.fromJson(Map<String, dynamic> json) {
    return AdministradorModel(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Administrador',
      isActive: json['is_active'] as bool? ?? true,
      farmIds: (json['farm_ids'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      farmNames: (json['farm_names'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      modulePermissions: (json['module_permissions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  AdministradorModel copyWith({
    String? fullName,
    String? email,
    bool? isActive,
    List<int>? farmIds,
    List<String>? farmNames,
    List<String>? modulePermissions,
  }) {
    return AdministradorModel(
      id: id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      isActive: isActive ?? this.isActive,
      farmIds: farmIds ?? this.farmIds,
      farmNames: farmNames ?? this.farmNames,
      modulePermissions: modulePermissions ?? this.modulePermissions,
    );
  }
}

class FincaDuenoModel {
  final int id;
  final String name;
  final String location;
  final int ownerId;
  final bool isActive;
  final List<String> assignedAdmins;
  final List<String> assignedUsers;

  const FincaDuenoModel({
    required this.id,
    required this.name,
    required this.location,
    required this.ownerId,
    required this.isActive,
    this.assignedAdmins = const [],
    this.assignedUsers = const [],
  });

  factory FincaDuenoModel.fromJson(Map<String, dynamic> json) {
    return FincaDuenoModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Finca',
      location: json['location'] as String? ?? 'Sin ubicación',
      ownerId: (json['owner_id'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      assignedAdmins: (json['assigned_admins'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      assignedUsers: (json['assigned_users'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  FincaDuenoModel copyWith({
    String? name,
    String? location,
    bool? isActive,
    List<String>? assignedAdmins,
    List<String>? assignedUsers,
  }) {
    return FincaDuenoModel(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      ownerId: ownerId,
      isActive: isActive ?? this.isActive,
      assignedAdmins: assignedAdmins ?? this.assignedAdmins,
      assignedUsers: assignedUsers ?? this.assignedUsers,
    );
  }
}

class UsuarioDuenoModel {
  final int id;
  final String email;
  final String fullName;
  final String role; // 'ADMIN', 'VETERINARIO', 'MAYORDOMO', 'TRABAJADOR'
  final bool isActive;
  final List<int> farmIds;
  final List<String> farmNames;
  final List<String> permissions;

  const UsuarioDuenoModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.farmIds,
    required this.farmNames,
    required this.permissions,
  });

  factory UsuarioDuenoModel.fromJson(Map<String, dynamic> json) {
    return UsuarioDuenoModel(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Usuario',
      role: json['role'] as String? ?? 'TRABAJADOR',
      isActive: json['is_active'] as bool? ?? true,
      farmIds: (json['farm_ids'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      farmNames: (json['farm_names'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      permissions: (json['permissions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  UsuarioDuenoModel copyWith({
    String? fullName,
    String? email,
    String? role,
    bool? isActive,
    List<int>? farmIds,
    List<String>? farmNames,
    List<String>? permissions,
  }) {
    return UsuarioDuenoModel(
      id: id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      farmIds: farmIds ?? this.farmIds,
      farmNames: farmNames ?? this.farmNames,
      permissions: permissions ?? this.permissions,
    );
  }
}

class AsignacionFincaModel {
  final int userId;
  final String userName;
  final String userRole;
  final int farmId;
  final String farmName;

  const AsignacionFincaModel({
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.farmId,
    required this.farmName,
  });
}
