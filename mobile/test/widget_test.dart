import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/main.dart';
import 'package:gestion_ganadera/features/auth/presentation/screens/login_screen.dart';
import 'package:gestion_ganadera/features/reproduccion/presentation/screens/reproduccion_screen.dart';
import 'package:gestion_ganadera/features/animals/presentation/screens/inventario_screen.dart';
import 'package:gestion_ganadera/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:gestion_ganadera/features/livestock/presentation/screens/produccion_screen.dart';
import 'package:gestion_ganadera/features/reports/presentation/screens/reportes_screen.dart';
import 'package:gestion_ganadera/core/theme/gavac_colors.dart';
import 'package:gestion_ganadera/core/theme/gavac_theme.dart';

void main() {
  testWidgets('GAVACApp renders LoginScreen initially',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GAVACApp());

    // Verify that LoginScreen is rendered
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Entrar al Sistema'), findsOneWidget);
    expect(
      find.text('La verificación de acceso está disponible en la versión web.'),
      findsNothing,
    );
  });

  testWidgets('Reproduction screen renders without layout errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReproduccionScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Control de Eventos Reproductivos'), findsOneWidget);
    expect(find.text('Historial de Eventos Reproductivos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new modules render without layout errors on mobile',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final screen in const [
      ProduccionScreen(),
      InventarioScreen(),
      ReportesScreen(),
    ]) {
      await tester.pumpWidget(MaterialApp(home: screen));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: screen.runtimeType.toString());
    }
  });

  testWidgets('dashboard opens production, inventory, and reports modules',
      (WidgetTester tester) async {
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

  testWidgets('inventory form adds an item to the current session',
      (WidgetTester tester) async {
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

    await tester.enterText(find.byType(TextField).at(0), 'Sal mineral');
    await tester.enterText(find.byType(TextField).at(1), '12');
    await tester.tap(find.text('Guardar Insumo'));
    await tester.pumpAndSettle();

    expect(find.text('Sal mineral'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('production form adds an event to the current session',
      (WidgetTester tester) async {
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

  testWidgets('login text remains readable when the system theme is dark',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GavacTheme.darkTheme,
        home: const LoginScreen(),
      ),
    );

    final emailInput = find.byType(TextField).first;
    await tester.enterText(emailInput, 'ganadero@example.com');
    await tester.pump();

    final field = tester.widget<TextField>(emailInput);
    expect(field.style?.color, GavacColors.textPrimary);
    expect(field.cursorColor, GavacColors.primary);
    expect(field.decoration?.fillColor, const Color(0xFFF8FAFC));
  });
}
