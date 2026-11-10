import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/features/animals/presentation/screens/inventario_screen.dart';

void main() {
  testWidgets('inventory form adds an item to the current session', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: InventarioScreen()));
    final registerButton = find.widgetWithText(
      ElevatedButton,
      'Registrar Insumo',
    );
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Sal mineral');
    await tester.enterText(find.byType(TextFormField).at(1), '12');
    await tester.tap(find.text('Guardar Insumo'));
    await tester.pumpAndSettle();

    expect(find.text('Sal mineral'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('inventory form requires a name and quantity', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: InventarioScreen()));
    final registerButton = find.widgetWithText(
      ElevatedButton,
      'Registrar Insumo',
    );
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar Insumo'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa el nombre del insumo.'), findsOneWidget);
    expect(find.text('Ingresa la cantidad.'), findsOneWidget);
    expect(find.text('Registrar Insumo / Recurso'), findsOneWidget);
  });
}
