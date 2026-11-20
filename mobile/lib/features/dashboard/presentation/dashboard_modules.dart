import 'package:material_ui/material_ui.dart';

import '../../../core/session/app_session.dart';

/// Opción del menú lateral del dashboard.
class DashboardModule {
  const DashboardModule({
    required this.icon,
    required this.label,
    this.permission,
    this.adminOnly = false,
  });

  final IconData icon;
  final String label;
  // Clave de permiso del backend; null = siempre visible.
  final String? permission;
  final bool adminOnly;

  /// Indica si el usuario en sesión puede ver este módulo.
  bool get isVisible {
    if (adminOnly) return AppSession.isAdmin;
    return permission == null || AppSession.canAccess(permission!);
  }
}

/// Módulos en el orden del menú. La posición coincide con la página que
/// muestra el dashboard.
abstract final class DashboardModules {
  static const inicio = 0;
  static const registro = 1;
  static const sanidad = 2;
  static const reproduccion = 3;
  static const produccion = 4;
  static const insumos = 5;
  static const reportes = 6;
  static const administracion = 7;

  static const all = [
    DashboardModule(icon: Icons.dashboard_outlined, label: 'Inicio'),
    DashboardModule(
      icon: Icons.person_add_outlined,
      label: 'Registro',
      permission: 'registro',
    ),
    DashboardModule(
      icon: Icons.shield_outlined,
      label: 'Salud',
      permission: 'sanidad',
    ),
    DashboardModule(
      icon: Icons.favorite_border,
      label: 'Reproducción',
      permission: 'reproduccion',
    ),
    DashboardModule(
      icon: Icons.water_drop_outlined,
      label: 'Producción',
      permission: 'produccion',
    ),
    DashboardModule(
      icon: Icons.inventory_2_outlined,
      label: 'Inventario',
      permission: 'insumos',
    ),
    DashboardModule(
      icon: Icons.bar_chart_outlined,
      label: 'Reportes',
      permission: 'reportes',
    ),
    DashboardModule(
      icon: Icons.admin_panel_settings_outlined,
      label: 'Administración',
      adminOnly: true,
    ),
  ];
}
