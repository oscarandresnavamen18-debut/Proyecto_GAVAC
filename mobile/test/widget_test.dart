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

  testWidgets('global theme button switches between light and dark modes',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GAVACApp());

    expect(
      Theme.of(tester.element(find.byType(LoginScreen))).brightness,
      Brightness.light,
    );
    expect(find.byTooltip('Cambiar a modo oscuro'), findsOneWidget);

    await tester.tap(find.byTooltip('Cambiar a modo oscuro'));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(LoginScreen))).brightness,
      Brightness.dark,
    );
    expect(find.byTooltip('Cambiar a modo claro'), findsOneWidget);

    await tester.tap(find.byTooltip('Cambiar a modo claro'));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(LoginScreen))).brightness,
      Brightness.light,
    );
  });

  testWidgets('Reproduction screen renders without layout errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReproduccionScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Control de Eventos Reproductivos'), findsOneWidget);
    expect(find.text('Historial de Eventos Reproductivos'), findsOneWidget);
    expect(find.text('No hay eventos registrados'), findsOneWidget);
    expect(find.text('CH-1024'), findsNothing);
    expect(find.text('CH-1025'), findsNothing);
    expect(find.text('CH-1026'), findsNothing);
    expect(find.text('0'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reproduction registration does not report unsaved events',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReproduccionScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Registrar Evento'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'El registro de eventos reproductivos aún no está conectado a la base de datos.',
      ),
      findsOneWidget,
    );
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
    expect(field.style?.color, GavacColors.textPrimary);
    expect(field.cursorColor, GavacColors.primary);
    expect(field.decoration?.fillColor, const Color(0xFFF8FAFC));
  });
}
