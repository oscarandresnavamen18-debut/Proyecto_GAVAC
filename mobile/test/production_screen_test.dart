import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/features/livestock/data/services/production_api_service.dart';
import 'package:gestion_ganadera/features/livestock/presentation/screens/produccion_screen.dart';

class _FakeProductionRepository implements ProductionRepository {
  final animals = const [AnimalOption(id: 1, tag: 'CH-101')];
  final List<ProductionRecord> records = [];
  int _nextId = 1;

  @override
  Future<List<AnimalOption>> listAnimals() async => animals;

  @override
  Future<List<ProductionRecord>> listRecords() async => List.of(records);

  @override
  Future<List<ProductionRecord>> createRecords({
    required int animalId,
    double? milkLiters,
    double? weightKg,
  }) async {
    final createdAt = DateTime.utc(2026, 11, 10);
    final animal = animals.singleWhere((item) => item.id == animalId);
    final created = [
      if (milkLiters != null)
        ProductionRecord(
          id: _nextId++,
          animalId: animalId,
          animalTag: animal.tag,
          recordType: 'MILK',
          quantity: milkLiters,
          unit: 'L',
          recordedAt: createdAt,
        ),
      if (weightKg != null)
        ProductionRecord(
          id: _nextId++,
          animalId: animalId,
          animalTag: animal.tag,
          recordType: 'WEIGHT',
          quantity: weightKg,
          unit: 'kg',
          recordedAt: createdAt,
        ),
    ];
    records.insertAll(0, created);
    return created;
  }

  @override
  Future<void> deleteRecord(int id) async {
    records.removeWhere((record) => record.id == id);
  }
}

void main() {
  testWidgets('production form persists measurements through its repository', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProductionRepository();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: ProduccionScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    final registerButton = find.widgetWithText(
      FilledButton,
      'Nuevo registro',
    );
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '18');
    await tester.enterText(find.byType(TextFormField).at(1), '420');
    await tester.tap(find.text('Guardar registro'));
    await tester.pumpAndSettle();

    expect(find.text('CH-101'), findsNWidgets(2));
    expect(find.text('18 L'), findsNWidgets(2));
    expect(find.text('420 kg'), findsNWidgets(2));
    expect(repository.records, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('production records reload from its repository', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProductionRepository()
      ..records.add(
        ProductionRecord(
          id: 1,
          animalId: 1,
          animalTag: 'CH-101',
          recordType: 'MILK',
          quantity: 18,
          unit: 'L',
          recordedAt: DateTime.utc(2026, 11, 10),
        ),
      );

    await tester.pumpWidget(
      MaterialApp(home: ProduccionScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('CH-101'), findsOneWidget);
    expect(find.text('18 L'), findsNWidgets(2));
  });
}
