import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/core/network/api_client.dart';
import 'package:gestion_ganadera/core/utils/app_session.dart';
import 'package:gestion_ganadera/features/reports/data/services/reports_api_service.dart';
import 'package:gestion_ganadera/features/reports/presentation/screens/reportes_screen.dart';

class _FakeReportsRepository implements ReportsRepository {
  final requests = <String>[];
  Object? failure;

  @override
  Future<Uint8List> download(String report, ReportFormat format) async {
    if (failure != null) throw failure!;
    requests.add('$report.${format.extension}');
    return Uint8List.fromList([1, 2, 3]);
  }
}

void main() {
  tearDown(AppSession.clear);

  Future<void> pumpReports(
    WidgetTester tester,
    _FakeReportsRepository repository,
    List<String> saved,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ReportesScreen(
          repository: repository,
          saveFile:
              ({required bytes, required fileName, required mimeType}) async {
                saved.add('$fileName|$mimeType');
                return null;
              },
        ),
      ),
    );
  }

  testWidgets('downloads a module report as PDF and Excel', (tester) async {
    final repository = _FakeReportsRepository();
    final saved = <String>[];
    await pumpReports(tester, repository, saved);

    expect(find.text('Reporte de Sanidad'), findsOneWidget);
    await tester.tap(find.text('PDF').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excel').first);
    await tester.pumpAndSettle();

    // El primer bloque es el resumen general de la finca.
    expect(find.text('Resumen general'), findsWidgets);
    expect(repository.requests, ['general.pdf', 'general.xlsx']);
    expect(saved.first, startsWith('gavac_general_'));

    await tester.tap(find.text('PDF').at(1));
    await tester.pumpAndSettle();
    expect(repository.requests.last, 'animales.pdf');
    expect(saved.first, endsWith('.pdf|application/pdf'));
    expect(find.textContaining('Reporte descargado'), findsWidgets);
  });

  testWidgets('only shows reports of enabled modules', (tester) async {
    AppSession.permissions = ['sanidad', 'reportes'];
    await pumpReports(tester, _FakeReportsRepository(), []);

    expect(find.text('Reporte de Sanidad'), findsOneWidget);
    expect(find.text('Reporte de Insumos'), findsNothing);
    expect(find.text('Reporte de Producción'), findsNothing);
  });

  testWidgets('download errors are shown to the user', (tester) async {
    final repository = _FakeReportsRepository()
      ..failure = const ApiException(403, 'No tienes permiso');
    await pumpReports(tester, repository, []);

    await tester.tap(find.text('PDF').first);
    await tester.pumpAndSettle();
    expect(find.text('No tienes permiso'), findsOneWidget);
  });
}
