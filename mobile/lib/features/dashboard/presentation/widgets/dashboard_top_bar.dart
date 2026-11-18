import 'package:material_ui/material_ui.dart';

import '../../../../core/session/app_session.dart';
import '../../../../core/theme/gavac_colors.dart';

/// Barra superior: menú (en pantallas angostas), título, alarmas y usuario.
class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    super.key,
    required this.isCompact,
    this.alertCount = 0,
    this.hasHighAlert = false,
    this.onAlerts,
    this.onToggleSidebar,
    this.isSidebarCollapsed = false,
  });

  final bool isCompact;
  final int alertCount;
  // Hay al menos una alarma de gravedad alta (contador en rojo).
  final bool hasHighAlert;
  final VoidCallback? onAlerts;
  final VoidCallback? onToggleSidebar;
  final bool isSidebarCollapsed;

  static String initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final userName = AppSession.userName.isNotEmpty
        ? AppSession.userName
        : 'Usuario';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 32,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (isCompact)
            IconButton(
              tooltip: 'Abrir menú',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu, color: GavacColors.primary),
            )
          else
            IconButton(
              tooltip: isSidebarCollapsed ? 'Expandir menú' : 'Contraer menú',
              onPressed: onToggleSidebar,
              icon: const Icon(Icons.menu, color: GavacColors.primary, size: 24),
            ),
          SizedBox(width: isCompact ? 4 : 16),
          Expanded(
            child: Text(
              'Panel Principal',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isCompact ? 18 : 20,
                fontWeight: FontWeight.w700,
                color: GavacColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: alertCount == 0
                ? 'Alarmas: todo en orden'
                : 'Alarmas: $alertCount pendientes',
            onPressed: onAlerts,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
            ),
            icon: Badge(
              isLabelVisible: alertCount > 0,
              label: Text(alertCount > 99 ? '99+' : '$alertCount'),
              backgroundColor: hasHighAlert
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFD97706),
              child: Icon(
                alertCount > 0
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_outlined,
                color: const Color(0xFF64748B),
                size: 22,
              ),
            ),
          ),
          SizedBox(width: isCompact ? 4 : 16),
          CircleAvatar(
            radius: 18,
            backgroundColor: GavacColors.primary,
            child: Text(
              initials(AppSession.userName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          if (!isCompact) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: GavacColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
          ],
        ],
      ),
    );
  }
}
