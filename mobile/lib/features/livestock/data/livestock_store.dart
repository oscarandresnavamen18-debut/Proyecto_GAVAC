import 'package:flutter/material.dart';

class Animal {
  final String id;
  final String nombre;
  final String arete;

  const Animal({
    required this.id,
    required this.nombre,
    required this.arete,
  });
}

class LivestockStore extends ChangeNotifier {
  static final LivestockStore instance = LivestockStore._internal();

  LivestockStore._internal() {
    _animals.addAll(const [
      Animal(id: '1', nombre: 'Lola', arete: 'ART-001'),
      Animal(id: '2', nombre: 'Bruma', arete: 'ART-002'),
      Animal(id: '3', nombre: 'Max', arete: 'ART-003'),
      Animal(id: '4', nombre: 'Estrella', arete: 'ART-004'),
    ]);
  }

  final List<Animal> _animals = [];

  List<Animal> get animals => List.unmodifiable(_animals);

  Animal? byId(String id) {
    try {
      return _animals.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  void addAnimal(Animal animal) {
    _animals.add(animal);
    notifyListeners();
  }
}
