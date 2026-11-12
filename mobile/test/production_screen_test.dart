import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/features/livestock/data/services/production_api_service.dart';
import 'package:gestion_ganadera/features/livestock/presentation/screens/produccion_screen.dart';

class _FakeProductionRepository implements ProductionRepository {
  _FakeProductionRepository({
    this.animals = const [AnimalOption(id: 1, tag: 'CH-101')],
  });

  final List<AnimalOption> animals;
  final List<ProductionRecord> records = [];
  int _nextId = 1;
  Object? loadFailure;
  Object? createFailure;
  Object? deleteFailure;

  @override
  Future<List<AnimalOption>> listAnimals() async {
    if (loadFailure != null) throw loadFailure!;
    return animals;
  }

  @override
  Future<List<ProductionRecord>> listRecords() async {
    if (loadFailure != null) throw loadFailure!;
    return List.of(records);
  }

  @override
  Future<List<ProductionRecord>> createRecords({
    required int animalId,
    double? milkLiters,
    double? weightKg,
  }) async {
    if (createFailure != null) throw createFailure!;
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
    if (deleteFailure != null) throw deleteFailure!;
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
      'Registrar Producción',
    );
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '18');
    await tester.enterText(find.byType(TextFormField).at(1), '420');
    await tester.tap(find.textContaining('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('CH-101'), findsWidgets);
    expect(find.text('18 L'), findsWidgets);
    expect(find.text('420 kg'), findsWidgets);
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
    expect(find.text('18 L'), findsWidgets);
  });

  testWidgets('production load errors are visible and retryable', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProductionRepository()
      ..loadFailure = Exception('sin conexión');

    await tester.pumpWidget(
      MaterialApp(home: ProduccionScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(
        find.textContaining('No se pudo cargar la producción'), findsOneWidget);
    repository.loadFailure = null;
    await tester.ensureVisible(find.text('Intentar de nuevo'));
    await tester.tap(find.text('Intentar de nuevo'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo cargar la producción'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('production save failures do not create local success records', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProductionRepository()
      ..createFailure = Exception('sin conexión');

    await tester.pumpWidget(
      MaterialApp(home: ProduccionScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    final registerButton = find.widgetWithText(
      FilledButton,
      'Registrar Producción',
    );
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '18');
    await tester.tap(find.textContaining('Guardar'));
    await tester.pumpAndSettle();

    expect(repository.records, isEmpty);
    expect(
      find.text('No se pudo guardar el registro: Exception: sin conexión'),
      findsOneWidget,
    );
    expect(find.text('Registro guardado correctamente.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('production delete failures keep the record visible', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProductionRepository()
      ..deleteFailure = Exception('sin conexión')
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
    final deleteButton = find.byTooltip('Eliminar registro');
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(repository.records, hasLength(1));
    expect(find.text('CH-101'), findsOneWidget);
    expect(
      find.text('No se pudo eliminar el registro: Exception: sin conexión'),
      findsOneWidget,
    );
    expect(find.text('Registro eliminado.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('production registration requires a backend animal', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProductionRepository(animals: const []);

    await tester.pumpWidget(
      MaterialApp(home: ProduccionScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    final registerButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Registrar Producción'),
    );
    expect(registerButton.onPressed, isNull);
    expect(
      find.text('Registra un animal primero para agregar datos de producción.'),
      findsOneWidget,
    );
  });
}
