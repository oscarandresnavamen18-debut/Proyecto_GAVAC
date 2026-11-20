import 'package:material_ui/material_ui.dart';

import '../../../../core/network/api_client.dart';
import '../../data/services/auth_api_service.dart';

/// Diálogo para consultar, registrar y verificar el correo alternativo.
Future<void> showAlternateEmailDialog(
  BuildContext context, {
  AuthRepository repository = const AuthApiService(),
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _AlternateEmailDialog(repository: repository),
  );
}

class _AlternateEmailDialog extends StatefulWidget {
  const _AlternateEmailDialog({required this.repository});

  final AuthRepository repository;

  @override
  State<_AlternateEmailDialog> createState() => _AlternateEmailDialogState();
}

class _AlternateEmailDialogState extends State<_AlternateEmailDialog> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verifiedEmail;
  bool _codeSent = false;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await widget.repository.alternateEmailStatus();
      if (!mounted) return;
      setState(() => _verifiedEmail = status.verifiedEmail);
    } on ApiException catch (error) {
      _showMessage(
        error.statusCode == 0
            ? 'No se pudo conectar con el servicio.'
            : 'No se pudo consultar el correo alternativo.',
      );
    } on FormatException {
      _showMessage('El servicio respondió con un formato no válido.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    if (email.isEmpty || (_codeSent && code.length != 8)) {
      _showMessage('Completa el correo y el código de verificación.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_codeSent) {
        final status = await widget.repository.confirmAlternateEmail(code);
        if (!mounted) return;
        setState(() => _verifiedEmail = status.verifiedEmail ?? email);
      } else {
        await widget.repository.requestAlternateEmail(email);
        if (!mounted) return;
        setState(() => _codeSent = true);
        _showMessage('Enviamos un código para verificar el correo.');
      }
    } on ApiException catch (error) {
      _showMessage(
        error.statusCode == 0 ? 'No se pudo conectar con el servicio.' : 'No se pudo verificar el correo. Revisa los datos e inténtalo de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final verified = _verifiedEmail;
    return AlertDialog(
      title: const Text('Correo alternativo'),
      content: _busy
          ? const SizedBox(
              height: 64,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (verified != null)
                  Text('Correo verificado: $verified')
                else ...[
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo alternativo',
                    ),
                  ),
                  if (_codeSent)
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      decoration: const InputDecoration(
                        labelText: 'Código enviado al correo',
                      ),
                    ),
                ],
              ],
            ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        if (!_busy && verified == null)
          FilledButton(
            onPressed: _submit,
            child: Text(_codeSent ? 'Verificar' : 'Enviar código'),
          ),
      ],
    );
  }
}
