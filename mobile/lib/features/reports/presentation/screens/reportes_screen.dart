import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestion_ganadera/core/theme/gavac_colors.dart';

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GavacColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 16 : 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Superior
              Container(
                width: double.infinity,
                height: MediaQuery.sizeOf(context).width < 600 ? 220 : 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: const DecorationImage(
                    image: AssetImage('assets/imagenes/imagenganado.png'),
                    fit: BoxFit.cover,
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
                        GavacColors.primary.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.sizeOf(context).width < 600
                        ? 16
                        : 32,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.bar_chart_outlined,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Módulo de Reportes',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: MediaQuery.sizeOf(context).width < 600
                                    ? 18
                                    : 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Informes estadísticos y trazabilidad del hato ganadero.',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Opciones de Reporte y Resumen analítico
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generación de Informes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: GavacColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Selecciona el tipo de informe que deseas consultar o exportar:',
                      style: TextStyle(color: GavacColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildReportButton(
                          context,
                          'Reporte de Inventario',
                          Icons.grid_view,
                        ),
                        _buildReportButton(
                          context,
                          'Reporte Sanitario',
                          Icons.shield,
                        ),
                        _buildReportButton(
                          context,
                          'Reporte Reproducción',
                          Icons.favorite,
                        ),
                        _buildReportButton(
                          context,
                          'Reporte de Productividad',
                          Icons.water_drop,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Divider(height: 24),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No hay datos suficientes para generar informes',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportButton(BuildContext context, String title, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La generación de reportes estará disponible cuando se conecten los datos.',
            ),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: GavacColors.primary,
        elevation: 0,
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon, color: GavacColors.primary),
      label: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
