
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/gavac_colors.dart';
import '../../../../core/theme/gavac_theme.dart';
import '../../../../core/utils/app_session.dart';
import '../widgets/captcha_widget.dart';

String get _apiBaseUrl => ApiClient.baseUrl;
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _captchaToken;
  VoidCallback? _resetCaptcha;

  static const String appName = 'GAVAC';
  static const String appSlogan =
      'Tecnología inteligente\npara la gestión del campo.';
  static const String welcomeTitle = 'Bienvenido';
  static const String welcomeSubtitle =
      'Ingresa tus credenciales para acceder.';
  static const String emailLabel = 'Correo Electrónico';
  static const String emailHint = 'usuario@gavac.pro';
  static const String passwordLabel = 'Contraseña';
  static const String passwordHint = '••••••••';
  static const String buttonText = 'Entrar al Sistema';
  static const String registerText = '¿No tienes cuenta? Regístrate aquí';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (kIsWeb && _captchaToken == null) {
      _showMessage('Completa la verificación reCAPTCHA.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/v1/auth/login'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim().replaceAll(' ', ''),
          'password': _passwordController.text,
          if (kIsWeb) 'captcha_token': _captchaToken,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        AppSession.accessToken = (jsonDecode(response.body)
            as Map<String, dynamic>)['access_token'] as String;
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        _resetCaptcha?.call();
        _showMessage(
          response.statusCode == 401
              ? 'Correo o contraseña incorrectos.'
              : 'No se pudo iniciar sesión. Inténtalo de nuevo.',
        );
      }
    } on http.ClientException {
      if (mounted) {
        _showMessage(
          'No se pudo conectar con el servicio. Inténtalo de nuevo.',
        );
      }
    } on FormatException {
      if (mounted) {
        _showMessage(
          'El servicio respondió con un formato no válido.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildCaptcha() => CaptchaWidget(
        onToken: (token) => setState(() => _captchaToken = token),
        onResetReady: (reset) => _resetCaptcha = reset,
      );

  Future<void> _showPasswordResetDialog() async {
    final emailController =
        TextEditingController(text: _emailController.text.trim());
    final codeController = TextEditingController();
    final passwordController = TextEditingController();
    var codeSent = false;
    var busy = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Restablecer contraseña'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo principal o alternativo verificado',
                  ),
                ),
                if (codeSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    decoration:
                        const InputDecoration(labelText: 'Código de 8 dígitos'),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Nueva contraseña'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (emailController.text.trim().isEmpty) return;
                      if (codeSent &&
                          (codeController.text.length != 8 ||
                              passwordController.text.length < 10)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Ingresa el código y una contraseña de al menos 10 caracteres.'),
                          ),
                        );
                        return;
                      }
                      setDialogState(() => busy = true);
                      try {
                        final response = await http.post(
                          Uri.parse(
                            '$_apiBaseUrl/api/v1/auth/password-reset/${codeSent ? 'confirm' : 'request'}',
                          ),
                          headers: const {'Content-Type': 'application/json'},
                          body: jsonEncode(
                            codeSent
                                ? {
                                    'email': emailController.text.trim(),
                                    'code': codeController.text.trim(),
                                    'new_password': passwordController.text,
                                  }
                                : {'email': emailController.text.trim()},
                          ),
                        );
                        if (!context.mounted) return;
                        if (response.statusCode == 204) {
                          Navigator.pop(dialogContext);
                          _showMessage(
                              'Contraseña restablecida. Ya puedes iniciar sesión.');
                        } else if (response.statusCode == 202) {
                          setDialogState(() => codeSent = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Si el correo está asociado, recibirás un código de verificación.'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'No se pudo completar la solicitud. Revisa el código e inténtalo de nuevo.'),
                            ),
                          );
                        }
                      } on http.ClientException {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'No se pudo conectar con el servicio.')),
                          );
                        }
                      } finally {
                        if (context.mounted) setDialogState(() => busy = false);
                      }
                    },
              child: Text(codeSent ? 'Confirmar' : 'Enviar código'),
            ),
          ],
        ),
      ),
    );
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 768;

    return Theme(
      data: GavacTheme.lightTheme,
      child: Scaffold(
        body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // LADO IZQUIERDO - Imagen de fondo con texto
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFF6B8E85),
            child: const Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.3,
                    child: Image(
                      image: AssetImage('assets/imagenes/imagenlogin.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: ColoredBox(color: Color(0x33000000)),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appName,
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            color: Color.fromARGB(255, 29, 28, 28),
                            letterSpacing: -2,
                            shadows: [
                              Shadow(
                                color: Color(0x80000000),
                                offset: Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          appSlogan,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            height: 1.4,
                            shadows: [
                              Shadow(
                                color: Color(0x80000000),
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // LADO DERECHO - Formulario de Login
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        welcomeTitle,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: GavacColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        welcomeSubtitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(height: 48),

                      _buildTextField(
                        label: emailLabel,
                        hint: emailHint,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 24),

                      _buildPasswordField(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                              _isLoading ? null : _showPasswordResetDialog,
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (kIsWeb) ...[
                        _buildCaptcha(),
                        const SizedBox(height: 20),
                      ],

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GavacColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor:
                                GavacColors.primary.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  buttonText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ✅ CAMBIO INTEGRADO: Navegación al Registro (Escritorio)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: const Text(
                            registerText,
                            style: TextStyle(
                              color: GavacColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: GavacColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                welcomeTitle,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: GavacColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                welcomeSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 40),

              _buildTextField(
                label: emailLabel,
                hint: emailHint,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),

              _buildPasswordField(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _showPasswordResetDialog,
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),
              const SizedBox(height: 32),
              if (kIsWeb) ...[
                _buildCaptcha(),
                const SizedBox(height: 20),
              ],

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GavacColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          buttonText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ✅ CAMBIO INTEGRADO: Navegación al Registro (Móvil)
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text(
                    registerText,
                    style: TextStyle(
                      color: GavacColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required IconData prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: GavacColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: GavacColors.textPrimary),
          cursorColor: GavacColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: GavacColors.textMuted),
            prefixIcon: Icon(prefixIcon, color: GavacColors.textMuted),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: GavacColors.primary, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es obligatorio';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          passwordLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: GavacColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: GavacColors.textPrimary),
          cursorColor: GavacColors.primary,
          decoration: InputDecoration(
            hintText: passwordHint,
            hintStyle: const TextStyle(color: GavacColors.textMuted),
            prefixIcon:
                const Icon(Icons.lock_outline, color: GavacColors.textMuted),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: GavacColors.textMuted,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: GavacColors.primary, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es obligatorio';
            }
            if (value.length < 6) {
              return 'Mínimo 6 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }
}
