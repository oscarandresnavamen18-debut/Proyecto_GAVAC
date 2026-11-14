import 'package:material_ui/material_ui.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/theme/gavac_colors.dart';
import '../../data/services/alerts_api_service.dart';
import '../../data/services/dashboard_api_service.dart';
import '../dashboard_modules.dart';

/// Página de inicio: finca activa, bienvenida, indicadores y promedios.
class InicioView extends StatefulWidget {
  const InicioView({
    super.key,
    required this.onOpenModule,
    this.alertas,
    this.onOpenAlerts,
    this.refreshToken = 0,
    this.repository = const DashboardApiService(),
  });

  /// Abre el módulo con el índice de [DashboardModules].
  final ValueChanged<int> onOpenModule;

  /// Alarmas de la campana (null = aún cargando).
  final List<Alerta>? alertas;
  final VoidCallback? onOpenAlerts;

  /// Cambia cada vez que se vuelve al inicio, para recargar los datos.
  final int refreshToken;
  final DashboardRepository repository;

  @override
  State<InicioView> createState() => _InicioViewState();
}

class _InicioViewState extends State<InicioView> {
  DashboardSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(InicioView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await widget.repository.summary();
      if (mounted) setState(() => _summary = summary);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = AppSession.userName.isNotEmpty
        ? AppSession.userName
        : 'Usuario';
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;
        return RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isCompact ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(farmName: _summary?.farmName ?? AppSession.farmName),
                const SizedBox(height: 32),
                _WelcomeBanner(userName: userName, isCompact: isCompact),
                const SizedBox(height: 32),
                if (_error != null)
                  _ErrorBanner(message: _error!, onRetry: _load)
                else ...[
                  _StatCards(
                    summary: _summary,
                    loading: _loading,
                    onOpenModule: widget.onOpenModule,
                    alertas: widget.alertas,
                    onOpenAlerts: widget.onOpenAlerts,
                  ),
                  const SizedBox(height: 24),
                  _Averages(summary: _summary, loading: _loading),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Número con coma decimal y sin ceros sobrantes: 17.27 → "17,3", 20 → "20".
String _number(double value) {
  final text = value.toStringAsFixed(1);
  return (text.endsWith('.0') ? text.substring(0, text.length - 2) : text)
      .replaceAll('.', ',');
}

String _plural(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';

class _Header extends StatelessWidget {
  const _Header({required this.farmName});

  final String farmName;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
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
                  farmName.isNotEmpty ? farmName : 'Sin finca asignada',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: GavacColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: GavacColors.textMuted),
          const SizedBox(height: 8),
          Text(
            'No se pudo cargar el resumen: $message',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Intentar de nuevo'),
          ),
        ],
      ),
    );
  }
}

class _StatCards extends StatelessWidget {
  const _StatCards({
    required this.summary,
    required this.loading,
    required this.onOpenModule,
    this.alertas,
    this.onOpenAlerts,
  });

  final List<Alerta>? alertas;
  final VoidCallback? onOpenAlerts;
  final DashboardSummary? summary;
  final bool loading;
  final ValueChanged<int> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final s = summary ?? const DashboardSummary();
    String value(int number) => loading && summary == null ? '…' : '$number';

    final cards = [
      _StatCard(
        title: 'TOTAL ANIMALES',
        value: value(s.totalAnimales),
        detail:
            '${_plural(s.hembras, 'hembra', 'hembras')} · '
            '${_plural(s.machos, 'macho', 'machos')}',
        icon: Icons.grid_view,
        iconColor: const Color(0xFF64748B),
        iconBg: const Color(0xFFF1F5F9),
        onTap: () => onOpenModule(DashboardModules.registro),
      ),
      _StatCard(
        title: 'EN TRATAMIENTO',
        value: value(s.animalesEnTratamiento),
        detail: 'Animales con tratamiento activo',
        icon: Icons.shield_outlined,
        iconColor: const Color(0xFF10B981),
        iconBg: const Color(0xFFD1FAE5),
        onTap: () => onOpenModule(DashboardModules.sanidad),
      ),
      _StatCard(
        title: 'VACAS GESTANTES',
        value: value(s.vacasGestantes),
        detail: s.partosProximos == 0
            ? 'Sin partos en los próximos 30 días'
            : '${_plural(s.partosProximos, 'parto', 'partos')} en 30 días',
        icon: Icons.favorite_border,
        iconColor: const Color(0xFFEF4444),
        iconBg: const Color(0xFFFEE2E2),
        onTap: () => onOpenModule(DashboardModules.reproduccion),
      ),
      _StatCard(
        title: 'ALERTAS',
        value: alertas == null ? '…' : '${alertas!.length}',
        detail: alertas == null
            ? 'Cargando alarmas'
            : alertas!.isEmpty
            ? 'Todo en orden'
            : '${_plural(alertas!.where((a) => a.esAlta).length, 'urgente', 'urgentes')} · toca para ver',
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFF59E0B),
        iconBg: const Color(0xFFFEF3C7),
        onTap: onOpenAlerts,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 800;
        final columns = compact ? (constraints.maxWidth < 420 ? 1 : 2) : 4;
        final spacing = compact ? 12.0 : 24.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
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
    required this.detail,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.onTap,
  });

  final String title;
  final String value;
  final String detail;
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
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
            const SizedBox(height: 4),
            Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Promedios de la finca: peso del hato y producción de leche.
class _Averages extends StatelessWidget {
  const _Averages({required this.summary, required this.loading});

  final DashboardSummary? summary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    String show(String? text) => loading && s == null ? '…' : (text ?? '—');

    final items = [
      (
        Icons.monitor_weight_outlined,
        'Peso promedio del hato',
        show(
          s?.pesoPromedioKg == null
              ? null
              : '${_number(s!.pesoPromedioKg!)} kg',
        ),
      ),
      (
        Icons.water_drop_outlined,
        'Promedio por ordeño (30 días)',
        show(
          s?.lechePromedioOrdeno == null
              ? null
              : '${_number(s!.lechePromedioOrdeno!)} L',
        ),
      ),
      (
        Icons.local_drink_outlined,
        'Leche producida (30 días)',
        show(s == null ? null : '${_number(s.lecheLitros30Dias)} L'),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Promedios de la finca',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: GavacColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 32,
            runSpacing: 16,
            children: [
              for (final (icon, label, value) in items)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: GavacColors.primary),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: GavacColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
