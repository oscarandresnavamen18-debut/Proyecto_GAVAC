import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/features/animales/data/services/animal_api_service.dart';
import 'package:gestion_ganadera/features/animales/data/services/potreros_api_service.dart';
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
          potreros: _FakePotrerosRepository(),
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
          home: AnimalesScreen(
            potreros: _FakePotrerosRepository(),
            repository: _FakeAnimalRepository([]),
          ),
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
      MaterialApp(
        home: AnimalesScreen(
          potreros: _FakePotrerosRepository(),
          repository: repository,
        ),
      ),
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
          home: AnimalesScreen(
            potreros: _FakePotrerosRepository(),
            repository: _FakeAnimalRepository([]),
          ),
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
      MaterialApp(
        home: AnimalesScreen(
          potreros: _FakePotrerosRepository(),
          repository: repository,
        ),
      ),
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
      MaterialApp(
        home: AnimalesScreen(
          potreros: _FakePotrerosRepository(),
          repository: repository,
        ),
      ),
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
      MaterialApp(
        home: AnimalesScreen(
          potreros: _FakePotrerosRepository(),
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Eliminar animal'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(repository.deleted, [8]);
    expect(find.text('GAV-008'), findsNothing);
  });

  testWidgets('shows real status, paddock and filters exits', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final potreros = _FakePotrerosRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: AnimalesScreen(
          potreros: potreros,
          repository: _FakeAnimalRepository([
            AnimalRecord(
              id: 1,
              chapeta: 'V-1',
              raza: 'Gyr',
              sexo: 'Hembra',
              fechaNacimiento: DateTime(2022, 1, 1),
              pesoKg: 400,
              loteId: 7,
            ),
            AnimalRecord(
              id: 2,
              chapeta: 'V-2',
              raza: 'Gyr',
              sexo: 'Hembra',
              fechaNacimiento: DateTime(2022, 1, 1),
              pesoKg: 380,
              estado: 'VENDIDO',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Por defecto solo los que están en la finca.
    expect(find.text('V-1'), findsOneWidget);
    expect(find.text('V-2'), findsNothing);
    expect(find.text('Potrero Norte'), findsOneWidget);
    expect(find.text('1 vendidos · 0 muertos'), findsOneWidget);

    await tester.tap(find.text('Vendidos y muertos'));
    await tester.pumpAndSettle();
    expect(find.text('V-2'), findsOneWidget);
    expect(find.text('Vendido'), findsOneWidget);
    expect(find.text('V-1'), findsNothing);
  });

  testWidgets('registers a sale from the row menu', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final potreros = _FakePotrerosRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: AnimalesScreen(
          potreros: potreros,
          repository: _FakeAnimalRepository([
            AnimalRecord(
              id: 1,
              chapeta: 'V-1',
              raza: 'Gyr',
              sexo: 'Hembra',
              fechaNacimiento: DateTime(2022, 1, 1),
              pesoKg: 400,
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Potrero y salida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar venta o muerte'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Precio de venta (\$)'),
      '3.500.000',
    );
    await tester.tap(find.text('Registrar venta'));
    await tester.pumpAndSettle();

    expect(potreros.salidasRegistradas, ['1|VENTA|3500000.0']);
    expect(find.textContaining('Venta de V-1 registrada'), findsOneWidget);
  });
}

class _FakePotrerosRepository implements PotrerosRepository {
  final salidasRegistradas = <String>[];

  @override
  Future<List<Potrero>> listPotreros({bool incluirInactivos = false}) async =>
      const [Potrero(id: 7, nombre: 'Potrero Norte', animales: 1)];

  @override
  Future<List<SalidaAnimal>> listSalidas() async => [];

  @override
  Future<SalidaAnimal> registrarSalida({
    required int animalId,
    required String tipo,
    required DateTime fecha,
    double? precio,
    String? comprador,
    String? causa,
    String? notas,
  }) async {
    salidasRegistradas.add('$animalId|$tipo|$precio');
    return SalidaAnimal(
      id: 1,
      animalId: animalId,
      chapeta: 'V-$animalId',
      tipo: tipo,
      fecha: fecha,
      precio: precio,
    );
  }

  @override
  Future<Potrero> crearPotrero({
    required String nombre,
    String? descripcion,
    double? areaHectareas,
  }) => throw UnimplementedError();

  @override
  Future<Potrero> actualizarPotrero(
    int id, {
    String? nombre,
    String? descripcion,
    double? areaHectareas,
    bool? activo,
  }) => throw UnimplementedError();

  @override
  Future<List<MovimientoPotrero>> moverAnimales({
    required List<int> animalIds,
    required int? destinoId,
    required DateTime fecha,
    String? notas,
  }) async => [];

  @override
  Future<List<MovimientoPotrero>> listMovimientos({int? animalId}) async => [];

  @override
  Future<void> anularSalida(int id) async {}
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
    int? loteId,
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
    int? loteId,
  }) async {
    throw UnimplementedError();
  }
}
