import 'package:material_ui/material_ui.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/gavac_colors.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/session/app_session.dart';
import '../../data/services/auth_api_service.dart';

enum RegisterUserType {
  admin('ADMIN', 'Administrador', Icons.admin_panel_settings_outlined),
  trabajadorCampo(
    'MAYORDOMO',
    'Trabajador de campo',
    Icons.agriculture_outlined,
  ),
  veterinario('VETERINARIO', 'Veterinario', Icons.medical_services_outlined);

  const RegisterUserType(this.apiValue, this.label, this.icon);

  final String apiValue;
  final String label;
  final IconData icon;
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.repository = const AuthApiService()});

  final AuthRepository repository;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  RegisterUserType _selectedRole = RegisterUserType.admin;
  List<Map<String, dynamic>> _farms = [];
  int? _selectedFarmId;
  bool _isLoadingFarms = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  static const String appName = 'GAVAC';
  static const String appSlogan =
      'Únete a la revolución\nde la gestión ganadera.';

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get _formBackground =>
      _isDarkMode ? const Color(0xFF0F172A) : Colors.white;
  Color get _formText =>
      _isDarkMode ? const Color(0xFFF1F5F9) : GavacColors.textPrimary;
  Color get _mutedText =>
      _isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF757575);
  Color get _fieldBackground =>
      _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
  Color get _fieldBorder =>
      _isDarkMode ? const Color(0xFF334155) : const Color(0xFFD1D5DB);

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadFarms() async {
    setState(() => _isLoadingFarms = true);
    try {
      final farms = await widget.repository.listPublicFarms();
      if (mounted) {
        setState(() {
          _farms = farms;
          if (_farms.isNotEmpty && _selectedFarmId == null) {
            _selectedFarmId = _farms.first['id'] as int?;
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingFarms = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Las contraseñas no coinciden.');
      return;
    }

    if (_selectedRole != RegisterUserType.admin && _selectedFarmId == null) {
      _showMessage('Debe seleccionar una finca asignada.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await widget.repository.register(
        nombre: _nombreController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole.apiValue,
        farmId: _selectedRole == RegisterUserType.admin ? null : _selectedFarmId,
      );
      await AppSession.saveSession(result.accessToken);
      AppSession.role = result.role ?? _selectedRole.apiValue;
      AppSession.userName = _nombreController.text.trim();
      try {
        await AppSession.loadProfile();
      } catch (_) {}

      _showMessage('Cuenta creada correctamente.');
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } on ApiException catch (error) {
      _showMessage(switch (error.statusCode) {
        0 => 'No se pudo conectar con el servidor. Revisa tu conexión.',
        409 => 'El correo electrónico ya se encuentra registrado.',
        404 => 'La finca seleccionada no fue encontrada.',
        _ => 'No se pudo registrar la cuenta. Inténtalo de nuevo.',
      });
    } on FormatException {
      _showMessage('Respuesta no válida del servidor.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: GavacColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 768;

    return Scaffold(
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  List<Widget> _buildFormFields(bool isDesktop) {
    final spacing = isDesktop ? 20.0 : 16.0;
    return [
      _buildTextField(
        'Nombre completo',
        'Ingresa tu nombre completo',
        _nombreController,
        Icons.person_outline,
      ),
      SizedBox(height: spacing),
      _buildTextField(
        'Correo electrónico',
        'correo@ejemplo.com',
        _emailController,
        Icons.email_outlined,
        TextInputType.emailAddress,
      ),
      SizedBox(height: spacing),
      Text(
        'Tipo de usuario',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _formText,
        ),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<RegisterUserType>(
        initialValue: _selectedRole,
        isExpanded: true,
        dropdownColor: _formBackground,
        style: TextStyle(color: _formText, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(_selectedRole.icon, color: _mutedText),
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
        items: [
          for (final type in RegisterUserType.values)
            DropdownMenuItem(value: type, child: Text(type.label)),
        ],
        onChanged: _isLoading
            ? null
            : (value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                  if (value != RegisterUserType.admin && _farms.isEmpty) {
                    _loadFarms();
                  }
                }
              },
      ),
      if (_selectedRole != RegisterUserType.admin) ...[
        SizedBox(height: spacing),
        Text(
          'Finca Asignada',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _formText,
          ),
        ),
        const SizedBox(height: 8),
        _isLoadingFarms
            ? const Center(child: CircularProgressIndicator())
            : _farms.isEmpty
                ? const Text(
                    'No hay fincas registradas. El administrador debe crear una finca primero.',
                    style: TextStyle(color: Colors.red, fontSize: 13),
                  )
                : DropdownButtonFormField<int>(
                    initialValue: _selectedFarmId,
                    isExpanded: true,
                    dropdownColor: _formBackground,
                    style: TextStyle(color: _formText, fontSize: 15),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.agriculture_outlined, color: _mutedText),
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
                    items: [
                      for (final farm in _farms)
                        DropdownMenuItem<int>(
                          value: farm['id'] as int,
                          child: Text(farm['name'] as String),
                        ),
                    ],
                    onChanged: _isLoading
                        ? null
                        : (value) => setState(() => _selectedFarmId = value),
                    validator: (v) => v == null ? 'Selecciona una finca' : null,
                  ),
      ],
      SizedBox(height: spacing),
      _buildPasswordField(
        'Contraseña',
        _passwordController,
        _obscurePassword,
        () => setState(() => _obscurePassword = !_obscurePassword),
      ),
      SizedBox(height: spacing),
      _buildPasswordField(
        'Confirmar contraseña',
        _confirmPasswordController,
        _obscureConfirmPassword,
        () => setState(
          () => _obscureConfirmPassword = !_obscureConfirmPassword,
        ),
      ),
    ];
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // LADO IZQUIERDO - Formulario
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
                        'Crear Cuenta',
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
                        'Completa tus datos para comenzar.',
                        style: TextStyle(fontSize: 16, color: _mutedText),
                      ),
                      const SizedBox(height: 32),
                      ..._buildFormFields(true),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
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
                                  'Registrarme',
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
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.login,
                          ),
                          child: Text(
                            '¿Ya tienes cuenta? Inicia sesión',
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

        // LADO DERECHO - Imagen de fondo con Ganado Gyr (imagenganado.png)
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFF1A3A32),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/imagenes/imagenganado.png',
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
                                appName,
                                style: TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          appSlogan,
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
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Crear Cuenta',
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
                'Completa tus datos para comenzar.',
                style: TextStyle(fontSize: 14, color: _mutedText),
              ),
              const SizedBox(height: 32),
              ..._buildFormFields(false),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
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
                          'Registrarme',
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
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.login),
                  child: Text(
                    '¿Ya tienes cuenta? Inicia sesión',
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

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon, [
    TextInputType? type,
  ]) {
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
          keyboardType: type,
          style: TextStyle(color: _formText, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _mutedText),
            prefixIcon: Icon(icon, color: _mutedText),
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
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscure,
    VoidCallback toggle,
  ) {
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
          obscureText: obscure,
          style: TextStyle(color: _formText, fontSize: 15),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: _mutedText),
            prefixIcon: Icon(Icons.lock_outline, color: _mutedText),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _mutedText,
              ),
              onPressed: toggle,
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
          validator: (v) => (v == null || v.isEmpty)
              ? 'Campo obligatorio'
              : (v.length < 6 ? 'Mínimo 6 caracteres' : null),
        ),
      ],
    );
  }
}
