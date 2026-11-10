import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/features/reports/presentation/screens/reportes_screen.dart';

void main() {
  testWidgets('report actions explain that data integration is pending', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ReportesScreen()));
    await tester.tap(find.text('Reporte de Inventario'));
    await tester.pump();

    expect(
      find.text(
        'La generación de reportes estará disponible cuando se conecten los datos.',
      ),
      findsOneWidget,
    );
  });
}
