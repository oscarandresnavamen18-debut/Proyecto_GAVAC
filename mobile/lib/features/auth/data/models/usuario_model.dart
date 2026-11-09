class UsuarioModel {
  final String id;
  final String nombre;
  final String correo;
  final String rol;
  final String fincaId;
  bool activo;

  UsuarioModel({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.fincaId,
    required this.activo,
  });
}
