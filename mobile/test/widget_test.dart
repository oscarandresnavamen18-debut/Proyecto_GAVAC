import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/main.dart';
import 'package:gestion_ganadera/features/auth/presentation/screens/login_screen.dart';
import 'package:gestion_ganadera/features/reproduccion/presentation/screens/reproduccion_screen.dart';
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

  testWidgets('GAVAC app keeps the light theme without a theme toggle',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GAVACApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(find.byKey(const ValueKey('theme-toggle')), findsNothing);
    expect(app.theme?.colorScheme.primary, const Color(0xFF2E6B57));
    expect(app.darkTheme, isNull);
  });

  testWidgets('Reproduction screen renders without layout errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReproduccionScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Control Reproducción'), findsOneWidget);
    expect(find.text('Historial Reproductivo'), findsOneWidget);
    expect(find.text('No hay eventos reproductivos registrados'), findsOneWidget);
    expect(find.text('CH-1024'), findsNothing);
    expect(find.text('CH-1025'), findsNothing);
    expect(find.text('CH-1026'), findsNothing);
    expect(find.text('0'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reproduction registration opens event registration dialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReproduccionScreen()));
    await tester.pumpAndSettle();

    final button = find.text('Registrar Evento').first;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Registrar Evento Reproductivo'), findsOneWidget);
    expect(find.text('Guardar Evento'), findsOneWidget);
    expect(find.textContaining('registrado exitosamente'), findsNothing);
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
    expect(field.style?.color, const Color(0xFFF1F5F9));
    expect(field.cursorColor, GavacColors.primary);
    expect(field.decoration?.fillColor, const Color(0xFF1E293B));
  });
}
