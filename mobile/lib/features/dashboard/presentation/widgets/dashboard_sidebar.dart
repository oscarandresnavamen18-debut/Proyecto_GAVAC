import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/gavac_colors.dart';
import '../dashboard_modules.dart';

/// Menú lateral con los módulos permitidos, salir y correo alternativo.
class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    required this.onAlternateEmail,
    this.isDrawer = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final VoidCallback onAlternateEmail;
  final bool isDrawer;

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (var i = 0; i < DashboardModules.all.length; i++)
        if (DashboardModules.all[i].isVisible) i,
    ];

    return Container(
      width: isDrawer ? null : 260,
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
          Expanded(
            child: ListView(
              children: [
                for (final index in visible)
                  _MenuItem(
                    module: DashboardModules.all[index],
                    selected: index == selectedIndex,
                    onTap: () => onSelect(index),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Divider(color: Colors.white24, thickness: 1),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onLogout,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.redAccent, size: 22),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton.icon(
              onPressed: onAlternateEmail,
              icon: const Icon(Icons.alternate_email, color: Colors.white70),
              label: const Text(
                'Correo alternativo',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.module,
    required this.selected,
    required this.onTap,
  });

  final DashboardModule module;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? GavacColors.primary : Colors.white70;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(module.icon, color: color, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    module.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
  }
}
