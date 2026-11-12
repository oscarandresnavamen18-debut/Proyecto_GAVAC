import 'package:material_ui/material_ui.dart';
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
      'Producción':
          'Registra la producción diaria y consulta el rendimiento del ganado.',
      'Inventario':
          'Organiza y lleva el control de los insumos y recursos de tu finca.',
      'Reportes':
          'Consulta resúmenes para entender mejor la actividad de tu finca.',
    }.entries) {
      await tester.tap(find.text(entry.key).first);
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    }

    expect(tester.takeException(), isNull);
  });
}
