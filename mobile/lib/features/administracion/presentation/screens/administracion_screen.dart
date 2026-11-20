import 'package:material_ui/material_ui.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/gavac_colors.dart';
import '../../data/models/finca_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/admin_api_service.dart';
import 'gestion_fincas_screen.dart';
import 'gestion_usuarios_screen.dart';

/// Panel de administración: accesos a fincas y usuarios con un resumen de
/// los datos registrados.
class AdministracionScreen extends StatefulWidget {
  const AdministracionScreen({super.key});

  @override
  State<AdministracionScreen> createState() => _AdministracionScreenState();
}

class _AdministracionScreenState extends State<AdministracionScreen> {
  List<AdminFincaModel> _fincas = [];
  List<AdminUsuarioModel> _usuarios = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        AdminApiService.listarFincas(),
        AdminApiService.listarUsuarios(),
      ]);
      if (!mounted) return;
      setState(() {
        _fincas = results[0] as List<AdminFincaModel>;
        _usuarios = results[1] as List<AdminUsuarioModel>;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    // Al volver se refrescan los datos que pudieron cambiar.
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 900;
    final panels = [
      _Panel(
        title: 'Fincas Registradas',
        emptyText: 'No hay fincas registradas',
        loading: _loading,
        error: _error,
        onRetry: _load,
        rows: [
          for (final finca in _fincas)
            _PanelRow(
              title: finca.nombre,
              subtitle: finca.ubicacion.isEmpty
                  ? 'Sin ubicación'
                  : finca.ubicacion,
            ),
        ],
      ),
      _Panel(
        title: 'Usuarios y Permisos',
        emptyText: 'No hay veterinarios ni trabajadores registrados',
        loading: _loading,
        error: _error,
        onRetry: _load,
        rows: [
          for (final usuario in _usuarios)
            _PanelRow(
              title: '${usuario.nombre} · ${etiquetaRol(usuario.rol)}',
              subtitle: usuario.activo
                  ? usuario.permisos
                        .map((p) => modulosConPermiso[p] ?? p)
                        .join(', ')
                  : 'Inactivo',
            ),
        ],
      ),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Administración',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: GavacColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fincas, usuarios y permisos por módulo',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _open(const GestionFincasAdminScreen()),
                    icon: const Icon(Icons.agriculture_outlined, size: 18),
                    label: const Text('Gestionar Fincas'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GavacColors.primary,
                      side: const BorderSide(
                        color: GavacColors.primary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _open(const GestionUsuariosAdminScreen()),
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Gestionar Usuarios'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GavacColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (isCompact)
            Column(children: [panels[0], const SizedBox(height: 16), panels[1]])
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: panels[0]),
                const SizedBox(width: 24),
                Expanded(child: panels[1]),
              ],
            ),
        ],
      ),
    );
  }
}

class _PanelRow {
  const _PanelRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.emptyText,
    required this.rows,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final String title;
  final String emptyText;
  final List<_PanelRow> rows;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (loading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (error != null) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      );
    } else if (rows.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            emptyText,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
      );
    } else {
      body = Column(
        children: [
          for (final row in rows)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                row.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: GavacColors.textPrimary,
                ),
              ),
              subtitle: Text(
                row.subtitle,
                style: const TextStyle(color: GavacColors.textSecondary),
              ),
            ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: GavacColors.primary,
            ),
          ),
          const Divider(height: 24),
          body,
        ],
      ),
    );
  }
}
