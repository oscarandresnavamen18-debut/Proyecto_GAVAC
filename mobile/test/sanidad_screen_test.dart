import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/core/network/api_client.dart';
import 'package:gestion_ganadera/features/sanidad/data/services/health_api_service.dart';
import 'package:gestion_ganadera/features/sanidad/presentation/screens/sanidad_screen.dart';

class _FakeHealthRepository implements HealthRepository {
  _FakeHealthRepository({List<HealthRecord>? records})
      : records = records ?? [];

  final List<AnimalOption> animals = const [
    AnimalOption(id: 1, tag: 'CH-101', name: 'Lucero'),
  ];
  final List<HealthRecord> records;
  Object? loadFailure;
  final created = <Map<String, Object?>>[];

  @override
  Future<List<AnimalOption>> listAnimals() async {
    if (loadFailure != null) throw loadFailure!;
    return animals;
  }

  @override
  Future<List<HealthRecord>> listRecords() async {
    if (loadFailure != null) throw loadFailure!;
    return List.of(records);
  }

  @override
  Future<HealthRecord> createRecord({
    required int animalId,
    required String recordType,
    required String diagnosis,
    required DateTime recordedAt,
    String? treatment,
    String? dose,
    String? veterinarian,
    DateTime? nextCheckAt,
    String? notes,
  }) async {
    created.add({
      'animalId': animalId,
      'recordType': recordType,
      'diagnosis': diagnosis,
      'dose': dose,
      'treatment': treatment,
    });
    return HealthRecord(
      id: created.length,
      animalId: animalId,
      animalTag: 'CH-101',
      recordType: recordType,
      diagnosis: diagnosis,
      treatment: treatment,
      dose: dose,
      veterinarian: 'Admin',
      recordedAt: recordedAt,
      status: recordType == 'VACUNA' ? 'VIGENTE' : 'EN_TRATAMIENTO',
    );
  }

  @override
  Future<void> deleteRecord(int id) async =>
      records.removeWhere((record) => record.id == id);
}

HealthRecord _vaccine(int id, String status) => HealthRecord(
      id: id,
      animalId: 1,
      animalTag: 'CH-101',
      recordType: 'VACUNA',
      diagnosis: 'Aftosa $id',
      dose: '2 ml',
      recordedAt: DateTime(2026, 1, id),
      status: status,
    );

void main() {
  testWidgets('health screen renders at mobile and desktop widths', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final size in [const Size(390, 844), const Size(1440, 900)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(home: SanidadScreen(repository: _FakeHealthRepository())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Control y Sanidad Ganadera'), findsOneWidget);
      expect(find.text('Historial Sanitario del Ganado'), findsOneWidget);
      expect(find.text('No hay registros sanitarios disponibles'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('health records load from the repository with KPIs', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeHealthRepository(records: [
      _vaccine(1, 'VIGENTE'),
      _vaccine(2, 'VENCIDO'),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: SanidadScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aftosa 1'), findsOneWidget);
    expect(find.text('Vencido'), findsOneWidget);
    // 1 animal con vacuna vigente de 1 animal registrado.
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('registering a vaccine persists it through the repository', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeHealthRepository();
    await tester.pumpWidget(
      MaterialApp(home: SanidadScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Registrar Vacuna'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre de Vacuna *'), 'Brucelosis');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Dosis (ml) *'), '2 ml');
    await tester.tap(find.text('Guardar Vacuna'));
    await tester.pumpAndSettle();

    expect(repository.created.single['diagnosis'], 'Brucelosis');
    expect(repository.created.single['recordType'], 'VACUNA');
    expect(find.text('Brucelosis'), findsOneWidget);
    expect(find.text('Vacuna registrada correctamente.'), findsOneWidget);
  });

  testWidgets('health load errors are visible and retryable', (
    WidgetTester tester,
  ) async {
    final repository = _FakeHealthRepository()
      ..loadFailure = const ApiException(500, 'Servidor no disponible');
    await tester.pumpWidget(
      MaterialApp(home: SanidadScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Servidor no disponible'), findsOneWidget);

    repository.loadFailure = null;
    await tester.ensureVisible(find.text('Intentar de nuevo'));
    await tester.tap(find.text('Intentar de nuevo'));
    await tester.pumpAndSettle();
    expect(find.text('No hay registros sanitarios disponibles'), findsOneWidget);
  });
}
