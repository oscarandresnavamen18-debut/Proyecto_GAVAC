import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/features/sanidad/presentation/screens/sanidad_screen.dart';

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
        const MaterialApp(home: SanidadScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Control y Sanidad Ganadera'), findsOneWidget);
      expect(find.text('Historial Sanitario del Ganado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
