import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/core/network/api_client.dart';
import 'package:gestion_ganadera/features/dashboard/data/services/alerts_api_service.dart';
import 'package:gestion_ganadera/features/dashboard/data/services/dashboard_api_service.dart';
import 'package:gestion_ganadera/features/dashboard/presentation/dashboard_modules.dart';
import 'package:gestion_ganadera/features/dashboard/presentation/widgets/inicio_view.dart';

class _FakeDashboardRepository implements DashboardRepository {
  _FakeDashboardRepository(this.result);

  DashboardSummary result;
  Object? failure;
  int calls = 0;

  @override
  Future<DashboardSummary> summary() async {
    calls++;
    if (failure != null) throw failure!;
    return result;
  }
}

const _summary = DashboardSummary(
  farmName: 'La Esperanza',
  totalAnimales: 3,
  hembras: 2,
  machos: 1,
  pesoPromedioKg: 486.83,
  animalesEnTratamiento: 1,
  vacunasPorVencer: 1,
  vacasGestantes: 2,
  partosProximos: 1,
  lecheLitros30Dias: 51.8,
  lechePromedioOrdeno: 17.27,
  insumosBajoMinimo: 1,
  alertas: 2,
);

Future<void> _pump(
  WidgetTester tester,
  DashboardRepository repository, {
  ValueChanged<int>? onOpen,
  int refreshToken = 0,
  List<Alerta>? alertas,
  VoidCallback? onOpenAlerts,
}) async {
  tester.view.physicalSize = const Size(1400, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: InicioView(
          onOpenModule: onOpen ?? (_) {},
          repository: repository,
          refreshToken: refreshToken,
          alertas: alertas,
          onOpenAlerts: onOpenAlerts,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the real indicators and averages', (tester) async {
    await _pump(tester, _FakeDashboardRepository(_summary));

    expect(find.text('La Esperanza'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2 hembras · 1 macho'), findsOneWidget);
    expect(find.text('1 parto en 30 días'), findsOneWidget);
    expect(find.text('486,8 kg'), findsOneWidget);
    expect(find.text('17,3 L'), findsOneWidget);
    expect(find.text('51,8 L'), findsOneWidget);
  });

  testWidgets('alerts card shows the same alarms as the bell', (tester) async {
    var opened = 0;
    await _pump(
      tester,
      _FakeDashboardRepository(_summary),
      alertas: const [
        Alerta(
          key: 'a',
          tipo: 'VACUNA_VENCIDA',
          severidad: 'ALTA',
          titulo: 'Vacuna vencida',
          detalle: '',
          modulo: 'sanidad',
        ),
        Alerta(
          key: 'b',
          tipo: 'PARTO_PROXIMO',
          severidad: 'MEDIA',
          titulo: 'Parto próximo',
          detalle: '',
          modulo: 'reproduccion',
        ),
      ],
      onOpenAlerts: () => opened++,
    );

    expect(find.text('1 urgente · toca para ver'), findsOneWidget);
    await tester.tap(find.text('ALERTAS'));
    expect(opened, 1);
  });

  testWidgets('cards open their module', (tester) async {
    final opened = <int>[];
    await _pump(tester, _FakeDashboardRepository(_summary), onOpen: opened.add);

    await tester.tap(find.text('VACAS GESTANTES'));
    await tester.tap(find.text('TOTAL ANIMALES'));
    expect(opened, [DashboardModules.reproduccion, DashboardModules.registro]);
  });

  testWidgets('reloads when the dashboard returns to the start page', (
    tester,
  ) async {
    final repository = _FakeDashboardRepository(_summary);
    await _pump(tester, repository);
    expect(repository.calls, 1);

    repository.result = const DashboardSummary(totalAnimales: 7);
    await _pump(tester, repository, refreshToken: 1);
    expect(repository.calls, 2);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('load errors can be retried', (tester) async {
    final repository = _FakeDashboardRepository(_summary)
      ..failure = const ApiException(0, 'sin conexión');
    await _pump(tester, repository);
    expect(find.textContaining('No se pudo cargar el resumen'), findsOneWidget);

    repository.failure = null;
    await tester.tap(find.text('Intentar de nuevo'));
    await tester.pumpAndSettle();
    expect(find.text('2 hembras · 1 macho'), findsOneWidget);
  });
}
