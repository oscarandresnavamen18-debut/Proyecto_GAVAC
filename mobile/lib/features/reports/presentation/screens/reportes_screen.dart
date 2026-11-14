import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/gavac_colors.dart';
import '../../../../core/utils/app_session.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/file_saver.dart' as file_saver;
import '../../../../core/widgets/feature_page_widgets.dart';
import '../../data/services/reports_api_service.dart';

/// Guarda el archivo descargado; se puede reemplazar en las pruebas.
typedef FileSaver = Future<String?> Function({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
});

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({
    super.key,
    this.repository = const ReportsApiService(),
    this.saveFile = file_saver.saveFile,
  });

  final ReportsRepository repository;
  final FileSaver saveFile;

  static const _generalReport = _ReportType(
    key: 'general',
    module: 'reportes',
    title: 'Resumen general',
    subtitle: 'PDF con portada de indicadores y una sección por módulo; Excel con una hoja por módulo.',
    icon: Icons.summarize_outlined,
    color: Colors.white,
    backgroundColor: GavacColors.primary,
  );

  static const _reportTypes = [
    _ReportType(
      key: 'animales',
      module: 'registro',
      title: 'Registro animal',
      subtitle: 'Inventario de animales, razas, pesos y estado',
      icon: Icons.pets_outlined,
      color: GavacColors.primary,
      backgroundColor: Color(0xFFE8F1EE),
    ),
    _ReportType(
      key: 'sanidad',
      module: 'sanidad',
      title: 'Sanidad',
      subtitle: 'Vacunas, tratamientos y vencimientos',
      icon: Icons.health_and_safety_outlined,
      color: GavacColors.successText,
      backgroundColor: GavacColors.successBg,
    ),
    _ReportType(
      key: 'reproduccion',
      module: 'reproduccion',
      title: 'Reproducción',
      subtitle: 'Celos, inseminaciones, preñeces y partos',
      icon: Icons.favorite_border,
      color: Color(0xFFBE5670),
      backgroundColor: Color(0xFFFFF1F3),
    ),
    _ReportType(
      key: 'produccion',
      module: 'produccion',
      title: 'Producción',
      subtitle: 'Litros de leche y pesajes por animal',
      icon: Icons.query_stats,
      color: GavacColors.warningText,
      backgroundColor: GavacColors.warningBg,
    ),
    _ReportType(
      key: 'insumos',
      module: 'insumos',
      title: 'Insumos',
      subtitle: 'Existencias y alertas de stock mínimo',
      icon: Icons.inventory_2_outlined,
      color: GavacColors.infoText,
      backgroundColor: GavacColors.infoBg,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pagePadding = MediaQuery.sizeOf(context).width < 600 ? 16.0 : 32.0;
    final available = _reportTypes
        .where((report) => AppSession.canAccess(report.module))
        .toList();

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
                    subtitle: 'Consulta resúmenes para entender mejor la actividad de tu finca.',
                  ),
                  const SizedBox(height: 24),
                  if (available.isNotEmpty) ...[
                    FeaturePanel(
                      title: 'Resumen general',
                      subtitle: 'Todos tus módulos en un solo archivo: indicadores de la finca y el detalle de cada módulo.',
                      child: _ReportCard(
                        report: _generalReport,
                        repository: repository,
                        saveFile: saveFile,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  FeaturePanel(
                    title: 'Informes por módulo',
                    subtitle: 'Descarga los registros de cada módulo de tu finca activa en PDF o Excel.',
                    child: available.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No tienes módulos habilitados para generar reportes.',
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              const spacing = 12.0;
                              final columns = constraints.maxWidth < 560
                                  ? 1
                                  : 2;
                              final cardWidth =
                                  (constraints.maxWidth -
                                      (spacing * (columns - 1))) /
                                  columns;
                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  for (final report in available)
                                    SizedBox(
                                      width: cardWidth,
                                      child: _ReportCard(
                                        report: report,
                                        repository: repository,
                                        saveFile: saveFile,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
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
    required this.key,
    required this.module,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String key;
  final String module;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
}

class _ReportCard extends StatefulWidget {
  const _ReportCard({
    required this.report,
    required this.repository,
    required this.saveFile,
  });

  final _ReportType report;
  final ReportsRepository repository;
  final FileSaver saveFile;

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  ReportFormat? _downloading;

  Future<void> _download(ReportFormat format) async {
    setState(() => _downloading = format);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await widget.repository.download(widget.report.key, format);
      final fileName =
          'gavac_${widget.report.key}_${isoDate(DateTime.now())}.${format.extension}';
      final path = await widget.saveFile(
        bytes: bytes,
        fileName: fileName,
        mimeType: format.mimeType,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'Reporte descargado: $fileName'
                : 'Reporte guardado en $path',
          ),
        ),
      );
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _downloading = null);
    }
  }

  Widget _formatButton(ReportFormat format, IconData icon, String label) {
    final busy = _downloading == format;
    return OutlinedButton.icon(
      onPressed: _downloading == null ? () => _download(format) : null,
      icon: busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: GavacColors.primary,
        side: const BorderSide(color: Color(0xFFD5DED9)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  children: [
                    Text(
                      report.key == 'general'
                          ? report.title
                          : 'Reporte de ${report.title}',
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
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _formatButton(
                ReportFormat.pdf,
                Icons.picture_as_pdf_outlined,
                'PDF',
              ),
              _formatButton(
                ReportFormat.excel,
                Icons.table_chart_outlined,
                'Excel',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
