import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/features/dashboard/data/services/alerts_api_service.dart';
import 'package:gestion_ganadera/features/dashboard/presentation/screens/dashboard_screen.dart';

class _FakeAlerts implements AlertsRepository {
  _FakeAlerts(this.result);

  final List<Alerta> result;

  @override
  Future<List<Alerta>> alertas() async => result;
}

void main() {
  testWidgets('bell shows the alarm count and opens the module', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          alerts: _FakeAlerts(const [
            Alerta(
              key: 'insumo_agotado:1',
              tipo: 'INSUMO_AGOTADO',
              severidad: 'ALTA',
              titulo: 'Insumo agotado: Sal',
              detalle: 'No quedan existencias.',
              modulo: 'insumos',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Alarmas: 1 pendientes'), findsOneWidget);
    await tester.tap(find.byTooltip('Alarmas: 1 pendientes'));
    await tester.pumpAndSettle();
    expect(find.text('Alarmas (1)'), findsOneWidget);
    expect(find.text('No quedan existencias.'), findsOneWidget);

    await tester.tap(find.text('Insumo agotado: Sal'));
    await tester.pumpAndSettle();
    // Se abrió el módulo de inventario (insumos).
    expect(
      find.text(
        'Organiza y lleva el control de los insumos y recursos de tu finca.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('no alarms shows everything in order', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: DashboardScreen(alerts: _FakeAlerts(const []))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Alarmas: todo en orden'));
    await tester.pumpAndSettle();
    expect(
      find.text('Todo en orden: no hay alarmas pendientes.'),
      findsOneWidget,
    );
  });
}
