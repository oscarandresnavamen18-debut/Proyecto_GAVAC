import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_ganadera/core/network/api_client.dart';
import 'package:gestion_ganadera/core/session/app_session.dart';
import 'package:gestion_ganadera/features/auth/data/services/auth_api_service.dart';
import 'package:gestion_ganadera/features/auth/presentation/screens/login_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  ApiException? loginError;
  final logins = <String>[];

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    required String role,
    String? captchaToken,
  }) async {
    logins.add('$email|$role');
    if (loginError != null) throw loginError!;
    return AuthResult(accessToken: 'token-de-prueba', role: role);
  }

  @override
  Future<AuthResult> register({
    required String nombre,
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {}

  @override
  Future<AlternateEmailStatus> alternateEmailStatus() async =>
      const AlternateEmailStatus();

  @override
  Future<void> requestAlternateEmail(String email) async {}

  @override
  Future<AlternateEmailStatus> confirmAlternateEmail(String code) async =>
      const AlternateEmailStatus();
}

Future<void> _fillAndSubmit(WidgetTester tester, String userType) async {
  await tester.tap(find.byKey(const Key('login_user_type')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(userType).last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'admin@finca.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'Clave12345');
  await tester.tap(find.text('Entrar al Sistema'));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(AppSession.clear);

  Future<void> pumpLogin(WidgetTester tester, AuthRepository repository) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(repository: repository),
        routes: {'/dashboard': (_) => const Text('Dashboard de prueba')},
      ),
    );
  }

  testWidgets('requires choosing the user type', (tester) async {
    final repository = _FakeAuthRepository();
    await pumpLogin(tester, repository);

    await tester.tap(find.text('Entrar al Sistema'));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona el tipo de usuario'), findsOneWidget);
    expect(repository.logins, isEmpty);
  });

  testWidgets('sends the selected role and opens the dashboard', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await pumpLogin(tester, repository);

    await _fillAndSubmit(tester, 'Veterinario');

    expect(repository.logins, ['admin@finca.com|VETERINARIO']);
    expect(AppSession.accessToken, 'token-de-prueba');
    expect(AppSession.role, 'VETERINARIO');
    expect(find.text('Dashboard de prueba'), findsOneWidget);
  });

  testWidgets('explains when the account has another user type', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..loginError = const ApiException(403, 'rol');
    await pumpLogin(tester, repository);

    await _fillAndSubmit(tester, 'Trabajador de campo');

    expect(
      find.text('Esta cuenta no está registrada como trabajador de campo.'),
      findsOneWidget,
    );
    expect(AppSession.accessToken, isNull);
  });
}
