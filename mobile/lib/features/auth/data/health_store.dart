import 'package:flutter/material.dart';

enum HealthStatus {
  aplicado,
  programado,
  vencido,
}

enum HealthType {
  vacuna,
  desparasitacion,
  tratamiento,
  revision;

  String get label {
    switch (this) {
      case HealthType.vacuna:
        return 'Vacuna';
      case HealthType.desparasitacion:
        return 'Desparasitación';
      case HealthType.tratamiento:
        return 'Tratamiento';
      case HealthType.revision:
        return 'Revisión';
    }
  }
}

class HealthRecord {
  final String id;
  final String animalId;
  final HealthType tipo;
  final String descripcion;
  final DateTime fecha;
  final bool aplicado;
  final DateTime? proximaFecha;
  final String responsable;
  final String observaciones;

  const HealthRecord({
    required this.id,
    required this.animalId,
    required this.tipo,
    required this.descripcion,
    required this.fecha,
    required this.aplicado,
    this.proximaFecha,
    required this.responsable,
    required this.observaciones,
  });

  HealthStatus get estado {
    if (aplicado) return HealthStatus.aplicado;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(fecha.year, fecha.month, fecha.day);
    if (eventDate.isBefore(today)) return HealthStatus.vencido;
    return HealthStatus.programado;
  }

  HealthRecord copyWith({
    String? id,
    String? animalId,
    HealthType? tipo,
    String? descripcion,
    DateTime? fecha,
    bool? aplicado,
    DateTime? proximaFecha,
    String? responsable,
    String? observaciones,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      tipo: tipo ?? this.tipo,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      aplicado: aplicado ?? this.aplicado,
      proximaFecha: proximaFecha ?? this.proximaFecha,
      responsable: responsable ?? this.responsable,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}

class HealthStore extends ChangeNotifier {
  static final HealthStore instance = HealthStore._internal();

  HealthStore._internal() {
    _records.addAll([
      HealthRecord(
        id: '1',
        animalId: '1',
        tipo: HealthType.vacuna,
        descripcion: 'Fiebre Aftosa - Dosis 1',
        fecha: DateTime.now().subtract(const Duration(days: 5)),
        aplicado: true,
        proximaFecha: DateTime.now().add(const Duration(days: 180)),
        responsable: 'Dr. Carlos Mendoza',
        observaciones: 'Sin reacciones adversas',
      ),
      HealthRecord(
        id: '2',
        animalId: '2',
        tipo: HealthType.desparasitacion,
        descripcion: 'Ivermectina 1%',
        fecha: DateTime.now().add(const Duration(days: 10)),
        aplicado: false,
        proximaFecha: DateTime.now().add(const Duration(days: 90)),
        responsable: 'Juan Pérez',
        observaciones: 'Aplicar temprano en la mañana',
      ),
    ]);
  }

  final List<HealthRecord> _records = [];

  List<HealthRecord> get records => List.unmodifiable(_records);

  int get aplicados => _records.where((r) => r.estado == HealthStatus.aplicado).length;
  int get programados => _records.where((r) => r.estado == HealthStatus.programado).length;
  int get vencidos => _records.where((r) => r.estado == HealthStatus.vencido).length;

  String newId() => DateTime.now().millisecondsSinceEpoch.toString();

  void add(HealthRecord r) {
    _records.add(r);
    notifyListeners();
  }

  void update(HealthRecord r) {
    final idx = _records.indexWhere((element) => element.id == r.id);
    if (idx != -1) {
      _records[idx] = r;
      notifyListeners();
    }
  }

  void remove(String id) {
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
