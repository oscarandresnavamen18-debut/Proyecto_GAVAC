/// Roles que el administrador puede asignar. El valor coincide con el backend;
/// "Trabajador de campo" corresponde a `MAYORDOMO`.
const Map<String, String> rolesAsignables = {
  'VETERINARIO': 'Veterinario',
  'MAYORDOMO': 'Trabajador de campo',
};

/// Módulos con permiso configurable: clave del backend → nombre visible.
const Map<String, String> modulosConPermiso = {
  'registro': 'Registro animal',
  'sanidad': 'Sanidad',
  'reproduccion': 'Reproducción',
  'produccion': 'Producción',
  'insumos': 'Insumos',
  'reportes': 'Reportes',
};

String etiquetaRol(String rol) => switch (rol) {
      'ADMIN' => 'Administrador',
      _ => rolesAsignables[rol] ?? rol,
    };

class AdminUsuarioModel {
  final int id;
  final String nombre;
  final String correo;
  final int? fincaId;
  final String rol;
  final bool activo;
  final List<String> permisos;

  const AdminUsuarioModel({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.fincaId,
    required this.rol,
    required this.activo,
    required this.permisos,
  });

  factory AdminUsuarioModel.fromJson(Map<String, dynamic> json) =>
      AdminUsuarioModel(
        id: json['id'] as int,
        nombre: json['full_name'] as String,
        correo: json['email'] as String,
        fincaId: json['farm_id'] as int?,
        rol: json['role'] as String,
        activo: json['is_active'] as bool? ?? true,
        permisos: (json['permissions'] as List<dynamic>? ?? const [])
            .cast<String>()
            .toList(),
      );
}
