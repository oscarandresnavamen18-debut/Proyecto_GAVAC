import 'package:flutter/material.dart';
import '../../../../core/theme/gavac_colors.dart';
import '../../../../core/utils/app_session.dart';
import '../../../animals/presentation/screens/animales_screen.dart';
import '../../../animals/presentation/screens/inventario_screen.dart';
import '../../../reproduccion/presentation/screens/reproduccion_screen.dart';
import '../../../sanidad/presentation/screens/sanidad_screen.dart';
import '../../../livestock/presentation/screens/produccion_screen.dart';
import '../../../reports/presentation/screens/reportes_screen.dart';
import '../../../admin/presentation/screens/gestion_fincas_screen.dart';
import '../../../admin/presentation/screens/gestion_usuarios_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_outlined, 'label': 'Inicio'},
    {'icon': Icons.person_add_outlined, 'label': 'Registro'},
    {'icon': Icons.shield_outlined, 'label': 'Salud'},
    {'icon': Icons.favorite_border, 'label': 'Reproducción'},
    {'icon': Icons.water_drop_outlined, 'label': 'Producción'},
    {'icon': Icons.inventory_2_outlined, 'label': 'Inventario'},
    {'icon': Icons.bar_chart_outlined, 'label': 'Reportes'},
    {'icon': Icons.admin_panel_settings_outlined, 'label': 'Administración'},
  ];

  late final List<Widget Function()> _pageBuilders;
  late final List<Widget?> _pages;

  @override
  void initState() {
    super.initState();

    _pageBuilders = [
      _buildInicioView,
      () => const AnimalesScreen(),
      () => const SanidadScreen(),
      () => const ReproduccionScreen(),
      () => const ProduccionScreen(),
      () => const InventarioScreen(),
      () => const ReportesScreen(),
      _buildAdminHubView,
    ];
    _pages = List<Widget?>.filled(_pageBuilders.length, null);
    _pages[0] = _pageBuilders[0]();
  }

  void _selectPage(int index) {
    setState(() {
      _pages[index] ??= _pageBuilders[index]();
      _selectedIndex = index;
    });
  }

  // Función para cerrar sesión
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AppSession.clear();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  String _getUserInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'U';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // SIDEBAR (Fondo imagenNav.jpg + Logo imagenLogoNuevo.png)
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A32),
              image: DecorationImage(
                image: const AssetImage('assets/imagenes/imagenNav.jpg'),
                fit: BoxFit.cover,
                opacity: 0.35,
                onError: (exception, stackTrace) {},
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Image.asset(
                    'assets/imagenes/imagenLogoNuevo.png',
                    height: 65,
                    errorBuilder: (context, error, stackTrace) => const Text(
                      'GAVAC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Menú principal
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Material(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              _selectPage(index);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    _menuItems[index]['icon'] as IconData,
                                    color: isSelected
                                        ? GavacColors.primary
                                        : Colors.white70,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _menuItems[index]['label'] as String,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isSelected
                                            ? GavacColors.primary
                                            : Colors.white70,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Separador
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Divider(color: Colors.white24, thickness: 1),
                ),
                const SizedBox(height: 12),

                // Botón de Salir (Rojo)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _handleLogout,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              color: Colors.redAccent,
                              size: 22,
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Salir',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // CONTENIDO PRINCIPAL CON TOP BAR Y INDEXEDSTACK
          Expanded(
            child: Column(
              children: [
                // TOP BAR SUPERIOR
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu,
                          color: GavacColors.primary, size: 24),
                      const SizedBox(width: 16),
                      const Text(
                        'Panel Principal',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: GavacColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_outlined,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: GavacColors.primary,
                            child: Text(
                              _getUserInitials(AppSession.userName),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            AppSession.userName.isNotEmpty
                                ? AppSession.userName
                                : 'Usuario',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: GavacColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down,
                              color: Colors.grey, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),

                // VISTAS DEL MODULO
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages
                        .map((page) => page ?? const SizedBox.shrink())
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Vista de Inicio
  Widget _buildInicioView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Superior
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inicio',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: GavacColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Resumen general de tu finca',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: GavacColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          AppSession.farmName.isNotEmpty
                              ? AppSession.farmName
                              : 'Seleccionar Finca',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: GavacColors.textPrimary),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey[600]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Icon(Icons.notifications_outlined,
                        color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Banner de Bienvenida (imagenInicio.jpg)
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: DecorationImage(
                image: const AssetImage('assets/imagenes/imagenInicio.jpg'),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {},
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    GavacColors.primary.withValues(alpha: 0.95),
                    GavacColors.primary.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Bienvenido, ${AppSession.userName.isNotEmpty ? AppSession.userName : 'Usuario'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Este es el estado actual de tu\nactivo ganadero hoy.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Tarjetas de Estadísticas (KPIs en ceros '0')
          Row(
            children: [
              _buildStatCard(
                'TOTAL ANIMALES',
                '0',
                Icons.grid_view,
                const Color(0xFF64748B),
                const Color(0xFFF1F5F9),
                onTap: () => _selectPage(1),
              ),
              const SizedBox(width: 24),
              _buildStatCard(
                'EN SANIDAD',
                '0',
                Icons.shield_outlined,
                const Color(0xFF10B981),
                const Color(0xFFD1FAE5),
                onTap: () => _selectPage(2),
              ),
              const SizedBox(width: 24),
              _buildStatCard(
                'REPRODUCCIÓN',
                '0',
                Icons.favorite_border,
                const Color(0xFFEF4444),
                const Color(0xFFFEE2E2),
                onTap: () => _selectPage(3),
              ),
              const SizedBox(width: 24),
              _buildStatCard('ALERTAS', '0', Icons.warning_amber_rounded,
                  const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
            ],
          ),
        ],
      ),
    );
  }

  // Vista de Administración
  Widget _buildAdminHubView() {
    final List<Map<String, dynamic>> fincasRegistradas = [];
    final List<Map<String, dynamic>> usuariosRegistrados = [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    'Panel de control maestro y configuración',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const GestionFincasAdminScreen()),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nueva Finca'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GavacColors.primary,
                      side: const BorderSide(
                          color: GavacColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const GestionUsuariosAdminScreen()),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo Usuario'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const GestionUsuariosAdminScreen()),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Asignar Personal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GavacColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
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
                      const Text(
                        'Fincas Registradas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: GavacColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Expanded(
                              flex: 2,
                              child: Text('NOMBRE',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF94A3B8)))),
                          Expanded(
                              flex: 2,
                              child: Text('UBICACIÓN',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF94A3B8)))),
                          Expanded(
                              flex: 1,
                              child: Text('ACCIÓN',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF94A3B8)))),
                        ],
                      ),
                      const Divider(height: 24),
                      fincasRegistradas.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'No hay fincas registradas',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 14),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: fincasRegistradas.length,
                              itemBuilder: (context, index) {
                                final finca = fincasRegistradas[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                          flex: 2,
                                          child: Text(finca['nombre'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: GavacColors
                                                      .textPrimary))),
                                      Expanded(
                                          flex: 2,
                                          child: Text(finca['ubicacion'],
                                              style: const TextStyle(
                                                  color: GavacColors
                                                      .textSecondary))),
                                      Expanded(
                                        flex: 1,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {},
                                            child: const Text('GESTIONAR',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: GavacColors.primary,
                                                    fontSize: 13)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Container(
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
                      const Text(
                        'Gestión de Usuarios y Permisos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: GavacColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Expanded(
                              flex: 2,
                              child: Text('EMAIL / ROL',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF94A3B8)))),
                          Expanded(
                              flex: 2,
                              child: Text('PERMISOS MÓDULOS (BLOQUEO)',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF94A3B8)))),
                          Expanded(
                              flex: 1,
                              child: Text('ACCIÓN',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF94A3B8)))),
                        ],
                      ),
                      const Divider(height: 24),
                      usuariosRegistrados.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'No hay usuarios registrados',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 14),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: usuariosRegistrados.length,
                              itemBuilder: (context, index) {
                                final user = usuariosRegistrados[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                          flex: 2,
                                          child: Text(user['email'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: GavacColors
                                                      .textPrimary))),
                                      Expanded(
                                          flex: 2,
                                          child: Text(user['permisos'],
                                              style: const TextStyle(
                                                  color: GavacColors
                                                      .textSecondary))),
                                      Expanded(
                                        flex: 1,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                  color: Colors.grey),
                                              onPressed: () {},
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: Colors.redAccent),
                                              onPressed: () {},
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color iconColor, Color iconBg,
      {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  Icon(Icons.more_horiz, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: GavacColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
