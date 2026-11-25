import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/gavac_colors.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/session/app_session.dart';
import '../../data/services/auth_api_service.dart';
import '../widgets/captcha_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.repository = const AuthApiService()});

  final AuthRepository repository;

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

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('gavac_saved_email');
      if (savedEmail != null && savedEmail.isNotEmpty && mounted) {
        setState(() {
          _emailController.text = savedEmail;
        });
      }
    } catch (_) {}
  }

  static const String welcomeTitle = 'Bienvenido';
  static const String welcomeSubtitle =
      'Ingresa tus credenciales para acceder.';
  static const String emailLabel = 'Correo Electrónico';
  static const String emailHint = 'correo@ejemplo.com';
  static const String passwordLabel = 'Contraseña';
  static const String passwordHint = '••••••••';
  static const String buttonText = 'Entrar al Sistema';
  static const String registerText = '¿No tienes cuenta? Regístrate aquí';

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get _formBackground =>
      _isDarkMode ? const Color(0xFF0F172A) : Colors.white;
  Color get _formText =>
      _isDarkMode ? const Color(0xFFF1F5F9) : GavacColors.textPrimary;
  Color get _mutedText =>
      _isDarkMode ? const Color(0xFFCBD5E1) : GavacColors.textSecondary;
  Color get _fieldBackground =>
      _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
  Color get _fieldBorder =>
      _isDarkMode ? const Color(0xFF334155) : const Color(0xFFD1D5DB);

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
      final email = _emailController.text.trim().replaceAll(' ', '');
      final result = await widget.repository.login(
        email: email,
        password: _passwordController.text,
        captchaToken: kIsWeb ? _captchaToken : null,
      );
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('gavac_saved_email', email);
      } catch (_) {}
      await AppSession.saveSession(result.accessToken);
      AppSession.role = result.role ?? 'ADMIN';
      try {
        await AppSession.loadProfile();
      } catch (error) {
        debugPrint('No se pudo cargar el perfil: $error');
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } on ApiException catch (error) {
      if (!mounted) return;
      _resetCaptcha?.call();
      _showMessage(switch (error.statusCode) {
        0 => 'No se pudo conectar con el servicio. Inténtalo de nuevo.',
        401 => 'Correo o contraseña incorrectos.',
        403 => 'Tu cuenta no está activa o no tiene acceso.',
        _ => 'No se pudo iniciar sesión. Inténtalo de nuevo.',
      });
    } on FormatException {
      if (mounted) {
        _showMessage('El servicio respondió con un formato no válido.');
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
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
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
                    decoration: const InputDecoration(
                      labelText: 'Código de 8 dígitos',
                    ),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña',
                    ),
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
                              'Ingresa el código y una contraseña de al menos 10 caracteres.',
                            ),
                          ),
                        );
                        return;
                      }
                      setDialogState(() => busy = true);
                      final email = emailController.text.trim();
                      try {
                        if (codeSent) {
                          await widget.repository.confirmPasswordReset(
                            email: email,
                            code: codeController.text.trim(),
                            newPassword: passwordController.text,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(dialogContext);
                          _showMessage(
                            'Contraseña restablecida. Ya puedes iniciar sesión.',
                          );
                        } else {
                          await widget.repository.requestPasswordReset(email);
                          if (!context.mounted) return;
                          setDialogState(() => codeSent = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Si el correo está asociado, recibirás un código de verificación.',
                              ),
                            ),
                          );
                        }
                      } on ApiException catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error.statusCode == 0
                                    ? 'No se pudo conectar con el servicio.'
                                    : 'No se pudo completar la solicitud. Revisa el código e inténtalo de nuevo.',
                              ),
                            ),
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

    return Scaffold(
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFF1A3A32),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/imagenes/imagenLoginNuevo.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/imagenes/imagenLogoNuevo.png',
                          height: 110,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text(
                                'GAVAC',
                                style: TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Tecnología inteligente\npara la gestión del campo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.4,
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
        Expanded(
          flex: 1,
          child: Container(
            color: _formBackground,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 64,
                  vertical: 48,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        welcomeTitle,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: _isDarkMode
                              ? const Color(0xFFB7D8CC)
                              : GavacColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        welcomeSubtitle,
                        style: TextStyle(fontSize: 16, color: _mutedText),
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
                          onPressed: _isLoading
                              ? null
                              : _showPasswordResetDialog,
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
                            shadowColor: GavacColors.primary.withValues(
                              alpha: 0.3,
                            ),
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
                                      Colors.white,
                                    ),
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
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.register);
                          },
                          child: Text(
                            registerText,
                            style: TextStyle(
                              color: _isDarkMode
                                  ? const Color(0xFFB7D8CC)
                                  : GavacColors.primary,
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
              const SizedBox(height: 32),
              Center(
                child: Image.asset(
                  'assets/imagenes/imagenLogoNuevo.png',
                  height: 80,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: GavacColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                welcomeTitle,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _isDarkMode
                      ? const Color(0xFFB7D8CC)
                      : GavacColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                welcomeSubtitle,
                style: TextStyle(fontSize: 14, color: _mutedText),
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
              if (kIsWeb) ...[_buildCaptcha(), const SizedBox(height: 20)],
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
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
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.register);
                  },
                  child: Text(
                    registerText,
                    style: TextStyle(
                      color: _isDarkMode
                          ? const Color(0xFFB7D8CC)
                          : GavacColors.primary,
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _formText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: _formText),
          cursorColor: GavacColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _mutedText),
            prefixIcon: Icon(prefixIcon, color: _mutedText),
            filled: true,
            fillColor: _fieldBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: GavacColors.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
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
        Text(
          passwordLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _formText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: TextStyle(color: _formText),
          cursorColor: GavacColors.primary,
          decoration: InputDecoration(
            hintText: passwordHint,
            hintStyle: TextStyle(color: _mutedText),
            prefixIcon: Icon(Icons.lock_outline, color: _mutedText),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _mutedText,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            filled: true,
            fillColor: _fieldBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: GavacColors.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
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
