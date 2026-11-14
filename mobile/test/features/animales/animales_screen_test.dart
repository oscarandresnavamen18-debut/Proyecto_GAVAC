import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/features/animales/data/services/animal_api_service.dart';
import 'package:gestion_ganadera/features/animales/presentation/screens/animales_screen.dart';

void main() {
  testWidgets('animals screen shows only animals returned by its repository', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AnimalesScreen(
          repository: _FakeAnimalRepository([
            AnimalRecord(
              id: 8,
              chapeta: 'GAV-008',
              raza: 'Brahman',
              sexo: 'Hembra',
              fechaNacimiento: DateTime(2023, 5, 1),
              pesoKg: 410,
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Módulo de Registro de Animales'), findsOneWidget);
    expect(find.text('GAV-008'), findsOneWidget);
    expect(find.text('CH-1024'), findsNothing);
    expect(find.text('CH-1025'), findsNothing);
    expect(find.text('CH-1026'), findsNothing);
    final breedText = tester.widget<Text>(find.text('Brahman'));
    expect(breedText.maxLines, 1);
    expect(breedText.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'animals screen shows a real empty state when the farm is empty',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1536, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AnimalesScreen(repository: _FakeAnimalRepository([])),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No hay animales registrados en el sistema'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('animals screen reports load errors and supports retry', (
    WidgetTester tester,
  ) async {
    final repository = _RecoveringAnimalRepository();

    await tester.pumpWidget(
      MaterialApp(home: AnimalesScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se pudieron cargar los animales'), findsOneWidget);

    repository.shouldFail = false;
    await tester.ensureVisible(find.text('Intentar de nuevo'));
    await tester.tap(find.text('Intentar de nuevo'));
    await tester.pumpAndSettle();

    expect(repository.loadAttempts, 2);
    expect(find.text('No se pudieron cargar los animales'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'animal registration dialog stays readable with dark system theme',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1536, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: AnimalesScreen(repository: _FakeAnimalRepository([])),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar Animal'));
      await tester.pumpAndSettle();

      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog).last);
      expect(dialog.backgroundColor, Colors.white);
      expect(find.textContaining('Fecha de'), findsOneWidget);
      expect(find.textContaining('Guardar'), findsOneWidget);

      final sexDropdown = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>).first,
      );
      expect(sexDropdown.dropdownColor, Colors.white);
      expect(sexDropdown.style?.color, const Color(0xFF1E293B));
      for (final item in sexDropdown.items!) {
        final itemText = item.child as Text;
        expect(itemText.style?.color, const Color(0xFF1A3A32));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('animal registration requires an entered weight', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeAnimalRepository([]);

    await tester.pumpWidget(
      MaterialApp(home: AnimalesScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar Animal'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'GAV-100');
    final weightField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == 'Ej: 450',
    );
    expect(tester.widget<TextField>(weightField).controller!.text, isEmpty);
    await tester.tap(find.text('Guardar Animal'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa un peso válido, ej: 230'), findsOneWidget);

    await tester.enterText(weightField, '532.5');
    expect(tester.widget<TextField>(weightField).controller!.text, '532.5');
    expect(tester.takeException(), isNull);
  });

  test('weight accepts units and decimal commas', () {
    expect(parsePesoKg('230'), 230);
    expect(parsePesoKg('230KG'), 230);
    expect(parsePesoKg(' 230 kg '), 230);
    expect(parsePesoKg('230,5 kilos'), 230.5);
    expect(parsePesoKg('0'), isNull);
    expect(parsePesoKg('doscientos'), isNull);
    expect(parsePesoKg(''), isNull);
  });

  testWidgets('editing an animal saves the new weight through the repository', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeAnimalRepository([
      AnimalRecord(
        id: 8,
        chapeta: 'GAV-008',
        raza: 'Brahman',
        sexo: 'Hembra',
        fechaNacimiento: DateTime(2023, 5, 1),
        pesoKg: 410,
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: AnimalesScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar animal'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Peso actual (kg) *'),
      '230KG',
    );
    await tester.tap(find.text('Actualizar Animal'));
    await tester.pumpAndSettle();

    expect(repository.updates, {8: 230});
    expect(find.text('230 kg'), findsOneWidget);
    expect(find.text('Datos del animal actualizados.'), findsOneWidget);
  });

  testWidgets('deleting an animal calls the repository', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeAnimalRepository([
      AnimalRecord(
        id: 8,
        chapeta: 'GAV-008',
        raza: 'Brahman',
        sexo: 'Hembra',
        fechaNacimiento: DateTime(2023, 5, 1),
        pesoKg: 410,
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: AnimalesScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Eliminar animal'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(repository.deleted, [8]);
    expect(find.text('GAV-008'), findsNothing);
  });
}

class _FakeAnimalRepository implements AnimalRepository {
  _FakeAnimalRepository(this.animals);

  final List<AnimalRecord> animals;
  final updates = <int, double>{};
  final deleted = <int>[];

  @override
  Future<AnimalRecord> updateAnimal(
    int id, {
    required String chapeta,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required double pesoKg,
  }) async {
    updates[id] = pesoKg;
    return AnimalRecord(
      id: id,
      chapeta: chapeta,
      raza: raza,
      sexo: sexo,
      fechaNacimiento: fechaNacimiento,
      pesoKg: pesoKg,
    );
  }

  @override
  Future<void> deleteAnimal(int id) async => deleted.add(id);

  @override
  Future<List<AnimalRecord>> listAnimals() async => animals;

  @override
  Future<AnimalRecord> createAnimal({
    required String chapeta,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required double pesoKg,
  }) async => AnimalRecord(
    id: 9,
    chapeta: chapeta,
    raza: raza,
    sexo: sexo,
    fechaNacimiento: fechaNacimiento,
    pesoKg: pesoKg,
  );
}

class _RecoveringAnimalRepository implements AnimalRepository {
  bool shouldFail = true;
  int loadAttempts = 0;

  @override
  Future<AnimalRecord> updateAnimal(
    int id, {
    required String chapeta,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required double pesoKg,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteAnimal(int id) => throw UnimplementedError();

  @override
  Future<List<AnimalRecord>> listAnimals() async {
    loadAttempts++;
    if (shouldFail) throw Exception('sin conexión');
    return [];
  }

  @override
  Future<AnimalRecord> createAnimal({
    required String chapeta,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required double pesoKg,
  }) async {
    throw UnimplementedError();
  }
}
