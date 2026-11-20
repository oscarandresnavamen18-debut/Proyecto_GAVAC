/// Animal resumido para listas desplegables de los módulos
/// (producción, sanidad y reproducción).
class AnimalOption {
  const AnimalOption({
    required this.id,
    required this.tag,
    this.name,
    this.gender,
  });

  factory AnimalOption.fromJson(Map<String, dynamic> json) => AnimalOption(
    id: json['id'] as int,
    tag: json['tag_id'] as String,
    name: json['name'] as String?,
    gender: json['gender'] as String?,
  );

  final int id;
  final String tag;
  final String? name;
  // MACHO o HEMBRA.
  final String? gender;

  bool get isFemale => gender == 'HEMBRA';

  /// Texto para listas desplegables: "CH-101 · Lucero".
  String get label => name == null || name!.isEmpty ? tag : '$tag · $name';
}
