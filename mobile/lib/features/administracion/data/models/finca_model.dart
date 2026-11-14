class AdminFincaModel {
  final int id;
  final String nombre;
  final String ubicacion;

  const AdminFincaModel({
    required this.id,
    required this.nombre,
    required this.ubicacion,
  });

  factory AdminFincaModel.fromJson(Map<String, dynamic> json) =>
      AdminFincaModel(
        id: json['id'] as int,
        nombre: json['name'] as String,
        ubicacion: json['location'] as String? ?? '',
      );
}
