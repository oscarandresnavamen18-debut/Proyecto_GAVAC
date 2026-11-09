class AdminUsuarioModel {
  final String id;
  final String nombre;
  final String correo;
  final String fincaId;
  final String rol;
  bool activo;
  Map<String, bool> permisos;

  AdminUsuarioModel({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.fincaId,
    required this.rol,
    this.activo = true,
    Map<String, bool>? permisos,
  }) : permisos = permisos ?? {
         'registro': true,
         'sanidad': true,
         'productividad': true,
         'reproduccion': true,
         'reportes': true,
         'admin': true,
       };
}
