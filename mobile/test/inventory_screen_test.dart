import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/features/animals/data/services/inventory_api_service.dart';
import 'package:gestion_ganadera/features/animals/presentation/screens/inventario_screen.dart';

class _FakeInventoryRepository implements InventoryRepository {
  final List<InventoryItem> items = [];
  int _nextId = 1;

  @override
  Future<List<InventoryItem>> listItems() async => List.of(items);

  @override
  Future<InventoryItem> createItem(String name, double quantity) async {
    final item = InventoryItem(
      id: _nextId++,
      name: name,
      category: 'GENERAL',
      unit: 'unidades',
      quantity: quantity,
      minimumQuantity: 0,
    );
    items.insert(0, item);
    return item;
  }

  @override
  Future<void> deactivateItem(int id) async {
    items.removeWhere((item) => item.id == id);
  }
}

void main() {
  testWidgets('inventory form persists an item through its repository', (
    WidgetTester tester,
  ) async {
    final repository = _FakeInventoryRepository();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: InventarioScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    final registerButton = find.widgetWithText(
      FilledButton,
      'Registrar Insumo',
    );
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Sal mineral');
    await tester.enterText(find.byType(TextFormField).at(1), '12');
    await tester.tap(find.text('Guardar insumo'));
    await tester.pumpAndSettle();

    expect(find.text('Sal mineral'), findsOneWidget);
    expect(find.text('12 unidades · GENERAL'), findsOneWidget);
    expect(repository.items, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('inventory form requires a name and quantity', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
          home: InventarioScreen(repository: _FakeInventoryRepository())),
    );
    await tester.pumpAndSettle();
    final registerButton = find.widgetWithText(
      FilledButton,
      'Registrar Insumo',
    );
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar insumo'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa el nombre del insumo.'), findsOneWidget);
    expect(find.text('Ingresa la cantidad.'), findsOneWidget);
    expect(find.text('Registrar Insumo'), findsWidgets);
  });

  testWidgets('inventory data reloads from its repository', (
    WidgetTester tester,
  ) async {
    final repository = _FakeInventoryRepository()
      ..items.add(
        const InventoryItem(
          id: 1,
          name: 'Sal mineral',
          category: 'GENERAL',
          unit: 'unidades',
          quantity: 5,
          minimumQuantity: 0,
        ),
      );

    await tester.pumpWidget(
      MaterialApp(home: InventarioScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sal mineral'), findsOneWidget);
    expect(find.text('5 unidades · GENERAL'), findsOneWidget);
  });
}
