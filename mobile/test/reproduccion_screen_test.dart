import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/features/reproduccion/data/services/breeding_api_service.dart';
import 'package:gestion_ganadera/features/reproduccion/presentation/screens/reproduccion_screen.dart';

class _FakeBreedingRepository implements BreedingRepository {
  _FakeBreedingRepository({List<BreedingRecord>? records})
      : records = records ?? [];

  final List<AnimalOption> animals = const [
    AnimalOption(id: 1, tag: 'VACA-1', gender: 'HEMBRA'),
    AnimalOption(id: 2, tag: 'TORO-1', gender: 'MACHO'),
  ];
  final List<BreedingRecord> records;
  final created = <Map<String, Object?>>[];

  @override
  Future<List<AnimalOption>> listAnimals() async => animals;

  @override
  Future<List<BreedingRecord>> listRecords() async => List.of(records);

  @override
  Future<BreedingRecord> createRecord({
    required int animalId,
    required String recordType,
    required DateTime recordedAt,
    String? notes,
  }) async {
    created.add({'animalId': animalId, 'recordType': recordType});
    return BreedingRecord(
      id: created.length,
      animalId: animalId,
      animalTag: 'VACA-1',
      recordType: recordType,
      recordedAt: recordedAt,
      status: 'En celo',
      notes: notes,
    );
  }

  @override
  Future<void> deleteRecord(int id) async =>
      records.removeWhere((record) => record.id == id);
}

void main() {
  testWidgets('reproduction screen renders without layout errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(
      home: ReproduccionScreen(repository: _FakeBreedingRepository()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Control Reproducción'), findsOneWidget);
    expect(find.text('Historial Reproductivo'), findsOneWidget);
    expect(find.text('No hay eventos reproductivos registrados'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pregnant KPI uses the latest event of each cow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeBreedingRepository(records: [
      BreedingRecord(
        id: 1, animalId: 1, animalTag: 'VACA-1', recordType: 'PRENEZ',
        recordedAt: DateTime(2026, 1, 1), status: 'Gestante',
      ),
      BreedingRecord(
        id: 2, animalId: 1, animalTag: 'VACA-1', recordType: 'PARTO',
        recordedAt: DateTime(2026, 10, 1), status: 'Parto registrado',
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: ReproduccionScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    final pregnant = find.ancestor(
      of: find.text('Vacas gestantes hoy'),
      matching: find.byType(Column),
    );
    expect(
      find.descendant(of: pregnant.first, matching: find.text('0')),
      findsOneWidget,
    );
  });

  testWidgets('registering an event only offers females and persists it', (
    WidgetTester tester,
  ) async {
    final repository = _FakeBreedingRepository();
    await tester.pumpWidget(
      MaterialApp(home: ReproduccionScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    final button = find.text('Registrar Evento').first;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Registrar Evento Reproductivo'), findsOneWidget);
    expect(find.text('VACA-1'), findsOneWidget);
    expect(find.text('TORO-1'), findsNothing);

    await tester.tap(find.text('Guardar Evento'));
    await tester.pumpAndSettle();

    expect(repository.created.single, {'animalId': 1, 'recordType': 'CELO'});
    expect(find.text('Evento reproductivo registrado.'), findsOneWidget);
  });
}
