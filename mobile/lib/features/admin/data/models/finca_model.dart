class AdminFincaModel {
  final String id;
  final String nombre;
  final String ubicacion;
  bool activa;

  AdminFincaModel({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    this.activa = true,
  });
}
