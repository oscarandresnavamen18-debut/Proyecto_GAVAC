import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/features/livestock/presentation/screens/produccion_screen.dart';

void main() {
  testWidgets('production form adds an event to the current session', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ProduccionScreen()));
    final registerButton = find.widgetWithText(
      ElevatedButton,
      'Registrar Producción',
    );
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'CH-101');
    await tester.enterText(find.byType(TextField).at(1), '18');
    await tester.enterText(find.byType(TextField).at(2), '420');
    await tester.tap(find.text('Guardar Registro'));
    await tester.pumpAndSettle();

    expect(find.text('CH-101'), findsOneWidget);
    expect(find.text('18 L'), findsOneWidget);
    expect(find.text('420 kg'), findsOneWidget);
  });
}
