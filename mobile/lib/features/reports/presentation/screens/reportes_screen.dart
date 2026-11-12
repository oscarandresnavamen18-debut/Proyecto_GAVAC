import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/gavac_colors.dart';
import '../../../../core/widgets/feature_page_widgets.dart';

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  static const _reportTypes = [
    _ReportType(
      title: 'Inventario',
      subtitle: 'Existencias y movimientos de insumos',
      icon: Icons.inventory_2_outlined,
      color: GavacColors.infoText,
      backgroundColor: GavacColors.infoBg,
    ),
    _ReportType(
      title: 'Sanidad',
      subtitle: 'Tratamientos, vacunas y alertas',
      icon: Icons.health_and_safety_outlined,
      color: GavacColors.successText,
      backgroundColor: GavacColors.successBg,
    ),
    _ReportType(
      title: 'Reproducción',
      subtitle: 'Eventos y seguimiento reproductivo',
      icon: Icons.favorite_border,
      color: Color(0xFFBE5670),
      backgroundColor: Color(0xFFFFF1F3),
    ),
    _ReportType(
      title: 'Productividad',
      subtitle: 'Producción y rendimiento del ganado',
      icon: Icons.query_stats,
      color: GavacColors.warningText,
      backgroundColor: GavacColors.warningBg,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pagePadding = MediaQuery.sizeOf(context).width < 600 ? 16.0 : 32.0;

    return Scaffold(
      backgroundColor: GavacColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(pagePadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FeaturePageHeader(
                    icon: Icons.insert_chart_outlined,
                    title: 'Reportes',
                    subtitle:
                        'Consulta resúmenes para entender mejor la actividad de tu finca.',
                  ),
                  const SizedBox(height: 24),
                  FeaturePanel(
                    title: 'Informes disponibles',
                    subtitle:
                        'Selecciona un área para conocer el tipo de información que ofrecerá.',
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 12.0;
                        final columns = constraints.maxWidth < 560 ? 1 : 2;
                        final cardWidth =
                            (constraints.maxWidth - (spacing * (columns - 1))) /
                                columns;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: _reportTypes
                              .map(
                                (report) => SizedBox(
                                  width: cardWidth,
                                  child: _ReportCard(report: report),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _ReportsEmptyState(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportType {
  const _ReportType({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final _ReportType report;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La generación de reportes estará disponible cuando se conecten los datos.',
              ),
            ),
          );
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7ECE9)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: report.backgroundColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(report.icon, color: report.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Reporte de ${report.title}',
                      style: GoogleFonts.plusJakartaSans(
                        color: GavacColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.subtitle,
                      style: const TextStyle(
                        color: GavacColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: GavacColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsEmptyState extends StatelessWidget {
  const _ReportsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: GavacColors.successBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8EEE2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.analytics_outlined,
            size: 34,
            color: GavacColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Tus reportes aparecerán aquí',
            style: GoogleFonts.plusJakartaSans(
              color: GavacColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'La generación de informes estará disponible cuando se conecten los datos de la finca.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GavacColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
