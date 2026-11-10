import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  testWidgets('dashboard opens production, inventory, and reports', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
    await tester.pumpAndSettle();

    for (final entry in {
      'Producción': 'Módulo de Producción',
      'Inventario': 'Módulo de Inventario',
      'Reportes': 'Módulo de Reportes',
    }.entries) {
      await tester.tap(find.text(entry.key).first);
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    }

    expect(tester.takeException(), isNull);
  });
}
