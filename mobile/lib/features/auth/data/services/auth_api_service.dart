import '../../../../core/network/api_client.dart';
import '../../../../core/session/app_session.dart';

/// Resultado de iniciar sesión o registrarse.
class AuthResult {
  const AuthResult({required this.accessToken, required this.role});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    accessToken: json['access_token'] as String,
    role: json['role'] as String?,
  );

  final String accessToken;
  // ADMIN, VETERINARIO o MAYORDOMO.
  final String? role;
}

/// Estado del correo alternativo de la cuenta.
class AlternateEmailStatus {
  const AlternateEmailStatus({this.email, this.verified = false});

  factory AlternateEmailStatus.fromJson(Map<String, dynamic> json) =>
      AlternateEmailStatus(
        email: json['email'] as String?,
        verified: json['verified'] as bool? ?? false,
      );

  final String? email;
  final bool verified;

  /// Correo ya verificado, o `null` si aún no hay uno.
  String? get verifiedEmail => verified ? email : null;
}

/// Autenticación y datos de la cuenta. Los errores llegan como
/// [ApiException]; `statusCode == 0` indica que no hubo conexión.
abstract interface class AuthRepository {
  Future<AuthResult> login({
    required String email,
    required String password,
    String? captchaToken,
  });
  Future<AuthResult> register({
    required String nombre,
    required String email,
    required String password,
    required String role,
    int? farmId,
  });
  Future<List<Map<String, dynamic>>> listPublicFarms();
  Future<void> requestPasswordReset(String email);
  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  });
  Future<AlternateEmailStatus> alternateEmailStatus();
  Future<void> requestAlternateEmail(String email);
  Future<AlternateEmailStatus> confirmAlternateEmail(String code);
}

class AuthApiService implements AuthRepository {
  const AuthApiService();

  static const _base = '/api/v1/auth';

  String get _token {
    final token = AppSession.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException(
        401,
        'La sesión venció. Inicia sesión de nuevo.',
      );
    }
    return token;
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    String? captchaToken,
  }) async => AuthResult.fromJson(
    await ApiClient.post('$_base/login', {
      'email': email,
      'password': password,
      if (captchaToken != null) 'captcha_token': captchaToken,
    }),
  );

  @override
  Future<AuthResult> register({
    required String nombre,
    required String email,
    required String password,
    required String role,
    int? farmId,
  }) async => AuthResult.fromJson(
    await ApiClient.post('$_base/register', {
      'nombre': nombre,
      'email': email,
      'password': password,
      'role': role,
      if (farmId != null) 'farm_id': farmId,
    }),
  );

  @override
  Future<List<Map<String, dynamic>>> listPublicFarms() async =>
      (await ApiClient.get('/api/v1/farms/public') as List)
          .cast<Map<String, dynamic>>();

  @override
  Future<void> requestPasswordReset(String email) =>
      ApiClient.postAction('$_base/password-reset/request', {'email': email});

  @override
  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) => ApiClient.postAction('$_base/password-reset/confirm', {
    'email': email,
    'code': code,
    'new_password': newPassword,
  });

  @override
  Future<AlternateEmailStatus> alternateEmailStatus() async =>
      AlternateEmailStatus.fromJson(
        await ApiClient.get('$_base/alternate-email', token: _token)
            as Map<String, dynamic>,
      );

  @override
  Future<void> requestAlternateEmail(String email) => ApiClient.postAction(
    '$_base/alternate-email/request',
    {'email': email},
    token: _token,
  );

  @override
  Future<AlternateEmailStatus> confirmAlternateEmail(String code) async =>
      AlternateEmailStatus.fromJson(
        await ApiClient.post('$_base/alternate-email/confirm', {
          'code': code,
        }, token: _token),
      );
}
