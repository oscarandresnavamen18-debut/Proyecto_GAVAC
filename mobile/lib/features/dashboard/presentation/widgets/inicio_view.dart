import 'package:material_ui/material_ui.dart';

import '../../../../core/session/app_session.dart';
import '../../../../core/theme/gavac_colors.dart';
import '../dashboard_modules.dart';

/// Página de inicio: finca activa, bienvenida y accesos rápidos.
class InicioView extends StatelessWidget {
  const InicioView({super.key, required this.onOpenModule});

  /// Abre el módulo con el índice de [DashboardModules].
  final ValueChanged<int> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final userName = AppSession.userName.isNotEmpty
        ? AppSession.userName
        : 'Usuario';
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(),
              const SizedBox(height: 32),
              _WelcomeBanner(userName: userName, isCompact: isCompact),
              const SizedBox(height: 32),
              _StatCards(onOpenModule: onOpenModule),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 16,
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
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: GavacColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppSession.farmName.isNotEmpty
                          ? AppSession.farmName
                          : 'Seleccionar Finca',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: GavacColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.userName, required this.isCompact});

  final String userName;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: isCompact ? 190 : 220,
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
        padding: EdgeInsets.all(isCompact ? 20 : 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bienvenido, $userName',
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompact ? 22 : 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Este es el estado actual de tu\nactivo ganadero hoy.',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCards extends StatelessWidget {
  const _StatCards({required this.onOpenModule});

  final ValueChanged<int> onOpenModule;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 800;
        final columns = compact ? 2 : 4;
        final spacing = compact ? 12.0 : 24.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final cards = [
          _StatCard(
            title: 'TOTAL ANIMALES',
            value: '0',
            icon: Icons.grid_view,
            iconColor: const Color(0xFF64748B),
            iconBg: const Color(0xFFF1F5F9),
            onTap: () => onOpenModule(DashboardModules.registro),
          ),
          _StatCard(
            title: 'EN SANIDAD',
            value: '0',
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFFD1FAE5),
            onTap: () => onOpenModule(DashboardModules.sanidad),
          ),
          _StatCard(
            title: 'REPRODUCCIÓN',
            value: '0',
            icon: Icons.favorite_border,
            iconColor: const Color(0xFFEF4444),
            iconBg: const Color(0xFFFEE2E2),
            onTap: () => onOpenModule(DashboardModules.reproduccion),
          ),
          const _StatCard(
            title: 'ALERTAS',
            value: '0',
            icon: Icons.warning_amber_rounded,
            iconColor: Color(0xFFF59E0B),
            iconBg: Color(0xFFFEF3C7),
          ),
        ];
        return Wrap(
          spacing: spacing,
          runSpacing: 12,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
    );
  }
}
