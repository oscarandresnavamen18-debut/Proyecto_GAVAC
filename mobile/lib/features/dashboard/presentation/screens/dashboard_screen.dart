import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/session/app_session.dart';
import '../../../administracion/presentation/screens/administracion_screen.dart';
import '../../../animales/presentation/screens/animales_screen.dart';
import '../../../auth/presentation/widgets/alternate_email_dialog.dart';
import '../../../insumos/presentation/screens/inventario_screen.dart';
import '../../../produccion/presentation/screens/produccion_screen.dart';
import '../../../reportes/presentation/screens/reportes_screen.dart';
import '../../../reproduccion/presentation/screens/reproduccion_screen.dart';
import '../../../sanidad/presentation/screens/sanidad_screen.dart';
import '../dashboard_modules.dart';
import '../widgets/dashboard_sidebar.dart';
import '../widgets/dashboard_top_bar.dart';
import '../widgets/inicio_view.dart';

/// Contenedor principal: menú lateral, barra superior y la página del
/// módulo seleccionado. Cada página se crea la primera vez que se abre.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = DashboardModules.inicio;

  late final List<Widget Function()> _pageBuilders = [
    () => InicioView(onOpenModule: _selectPage),
    () => const AnimalesScreen(),
    () => const SanidadScreen(),
    () => const ReproduccionScreen(),
    () => const ProduccionScreen(),
    () => const InventarioScreen(),
    () => const ReportesScreen(),
    () => const AdministracionScreen(),
  ];
  late final List<Widget?> _pages = List<Widget?>.filled(
    _pageBuilders.length,
    null,
  )..[DashboardModules.inicio] = _pageBuilders[DashboardModules.inicio]();

  void _selectPage(int index) {
    setState(() {
      _pages[index] ??= _pageBuilders[index]();
      _selectedIndex = index;
    });
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    AppSession.clear();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  Widget _sidebar({required bool isDrawer}) => DashboardSidebar(
    selectedIndex: _selectedIndex,
    isDrawer: isDrawer,
    onSelect: (index) {
      if (isDrawer) Navigator.of(context).pop();
      _selectPage(index);
    },
    onLogout: _confirmLogout,
    onAlternateEmail: () => showAlternateEmailDialog(context),
  );

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 800;
    final content = Column(
      children: [
        DashboardTopBar(isCompact: isCompact),
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              for (final page in _pages) page ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isCompact
          ? Drawer(child: SafeArea(child: _sidebar(isDrawer: true)))
          : null,
      body: isCompact
          ? SafeArea(child: content)
          : Row(
              children: [
                _sidebar(isDrawer: false),
                Expanded(child: content),
              ],
            ),
    );
  }
}
