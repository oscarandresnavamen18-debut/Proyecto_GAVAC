import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modelo ligero para recibir los datos de registros sanitarios desde el Backend.
class RegistroSanitario {
  final String id;
  final String codigo;
  final String arete;
  final String tipo; // 'Vacuna' o 'Tratamiento'
  final String evento; // Ej: Aftosa, Mastitis, Desparasitación
  final String fechaAplicacion;
  final String fechaVencimiento;
  final String dosis;
  final String veterinario;
  final String estado; // 'Vigente', 'Próximo a Vencer', 'Vencido'
  final String tipoEstado; // 'success', 'warning', 'danger', 'info'

  const RegistroSanitario({
    required this.id,
    required this.codigo,
    required this.arete,
    required this.tipo,
    required this.evento,
    required this.fechaAplicacion,
    required this.fechaVencimiento,
    required this.dosis,
    required this.veterinario,
    required this.estado,
    required this.tipoEstado,
  });
}

class SanidadScreen extends StatefulWidget {
  final String vacunacionPorcentaje;
  final String controlesPendientes;
  final String alertasSanitarias;
  final List<RegistroSanitario> registros;
  final Function(Map<String, String>)? onGuardarVacuna;
  final Function(Map<String, String>)? onGuardarTratamiento;

  const SanidadScreen({
    super.key,
    this.vacunacionPorcentaje = '0.0%',
    this.controlesPendientes = '0',
    this.alertasSanitarias = '0',
    this.registros = const [],
    this.onGuardarVacuna,
    this.onGuardarTratamiento,
  });

  @override
  State<SanidadScreen> createState() => _SanidadScreenState();
}

class _SanidadScreenState extends State<SanidadScreen> {
  // Colores Oficiales GAVAC Design System
  static const Color primaryColor = Color(0xFF1A3A32); // Deep Forest Green
  // ignore: unused_field
  static const Color accentColor = Color(0xFF2E5A4D);  // Dark Emerald Accent
  static const Color backgroundColor = Color(0xFFF7F9F7); // Soft Clean Off-White
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF94A3B8);

  String _filtroSeleccionado = 'Todos'; // 'Todos', 'Vacunas', 'Tratamientos', 'Alertas'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              _buildKpiMetricsRow(),
              const SizedBox(height: 32),
              _buildAlertasVencimientoSection(), // Criterio 4: Alertas de Vencimiento
              const SizedBox(height: 32),
              _buildHistorialSanitarioSection(context), // Criterios 1, 2 y 3
            ],
          ),
        ),
      ),
    );
  }

  // Encabezado principal con botones de acción para Vacunas y Tratamientos
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Control y Sanidad Ganadera',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gestión de vacunas, tratamientos y alertas de vencimiento oficial ICA.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Criterio 1: Registrar Vacunas
            ElevatedButton.icon(
              onPressed: () => _mostrarModalRegistrarVacuna(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: const Icon(Icons.vaccines_rounded, size: 20),
              label: Text(
                'Registrar Vacuna',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            // Criterio 2: Registrar Tratamientos
            OutlinedButton.icon(
              onPressed: () => _mostrarModalRegistrarTratamiento(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(color: primaryColor, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.medication_liquid_rounded, size: 20),
              label: Text(
                'Registrar Tratamiento',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Métricas KPI
  Widget _buildKpiMetricsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 900;
        return Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
          children: [
            _buildKpiCard(
              title: 'Vacunación Vigente',
              value: widget.vacunacionPorcentaje,
              subtitle: 'Esquema oficial reportado',
              icon: Icons.shield_rounded,
              iconBgColor: const Color(0xFFECFDF5),
              iconColor: const Color(0xFF059669),
            ),
            SizedBox(height: isWide ? 0 : 16, width: isWide ? 16 : 0),
            _buildKpiCard(
              title: 'Tratamientos Activos',
              value: widget.controlesPendientes,
              subtitle: 'En seguimiento veterinario',
              icon: Icons.health_and_safety_rounded,
              iconBgColor: const Color(0xFFEFF6FF),
              iconColor: const Color(0xFF2563EB),
            ),
            SizedBox(height: isWide ? 0 : 16, width: isWide ? 16 : 0),
            _buildKpiCard(
              title: 'Alertas de Vencimiento',
              value: widget.alertasSanitarias,
              subtitle: 'Requiere atención urgente',
              icon: Icons.warning_amber_rounded,
              iconBgColor: const Color(0xFFFEF2F2),
              iconColor: const Color(0xFFDC2626),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textMuted,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Criterio 4: Banner/Sección de Alertas de Vencimiento
  Widget _buildAlertasVencimientoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Amber soft bg
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Control de Alertas de Vencimiento',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'El sistema notificará automáticamente las vacunas y tratamientos próximos a vencer para asegurar el cumplimiento del ciclo ICA.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Criterio 3: Historial Sanitario con Filtros
  Widget _buildHistorialSanitarioSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historial Sanitario del Ganado',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
              // Filtros de navegación
              Row(
                children: ['Todos', 'Vacunas', 'Tratamientos'].map((filtro) {
                  final isSelected = _filtroSeleccionado == filtro;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ChoiceChip(
                      label: Text(filtro),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _filtroSeleccionado = filtro);
                      },
                      selectedColor: primaryColor,
                      backgroundColor: backgroundColor,
                      labelStyle: GoogleFonts.plusJakartaSans(
                        color: isSelected ? Colors.white : primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.registros.isEmpty) _buildEmptyState() else SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(backgroundColor),
              // ignore: deprecated_member_use
              dataRowHeight: 64,
              columns: [
                DataColumn(label: _buildTableHeader('ANIMAL / ARETE')),
                DataColumn(label: _buildTableHeader('TIPO')),
                DataColumn(label: _buildTableHeader('EVENTO / DIAGNÓSTICO')),
                DataColumn(label: _buildTableHeader('APLICACIÓN')),
                DataColumn(label: _buildTableHeader('VENCIMIENTO')),
                DataColumn(label: _buildTableHeader('DOSIS')),
                DataColumn(label: _buildTableHeader('VETERINARIO')),
                DataColumn(label: _buildTableHeader('ESTADO')),
              ],
              rows: widget.registros.map((registro) {
                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            registro.codigo,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            registro.arete,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: registro.tipo == 'Vacuna' ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          registro.tipo,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: registro.tipo == 'Vacuna' ? const Color(0xFF059669) : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(registro.evento, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600))),
                    DataCell(Text(registro.fechaAplicacion, style: GoogleFonts.plusJakartaSans(fontSize: 13))),
                    DataCell(Text(registro.fechaVencimiento, style: GoogleFonts.plusJakartaSans(fontSize: 13))),
                    DataCell(Text(registro.dosis, style: GoogleFonts.plusJakartaSans(fontSize: 13))),
                    DataCell(Text(registro.veterinario, style: GoogleFonts.plusJakartaSans(fontSize: 13))),
                    DataCell(_buildStatusBadge(registro.estado, registro.tipoEstado)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: textMuted),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.folder_open_rounded, size: 48, color: textMuted),
            const SizedBox(height: 12),
            Text(
              'No hay registros sanitarios disponibles',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, String type) {
    Color bgColor;
    Color textColor;

    switch (type) {
      case 'success':
        bgColor = const Color(0xFFECFDF5);
        textColor = const Color(0xFF059669);
        break;
      case 'warning':
        bgColor = const Color(0xFFFFFBEB);
        textColor = const Color(0xFFD97706);
        break;
      case 'danger':
        bgColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFDC2626);
        break;
      default:
        bgColor = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF2563EB);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  // --- MODAL CRITERIO 1: REGISTRAR VACUNA ---
  void _mostrarModalRegistrarVacuna(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Registrar Vacuna (HU-007)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: primaryColor)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Código Animal / Arete', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Nombre de la Vacuna (Ej: Aftosa, Brucelosis)', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Dosis (ml)', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Fecha de Vencimiento / Próximo Ciclo', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vacuna registrada correctamente')));
            },
            child: const Text('Guardar Vacuna', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- MODAL CRITERIO 2: REGISTRAR TRATAMIENTO ---
  void _mostrarModalRegistrarTratamiento(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Registrar Tratamiento (HU-007)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: primaryColor)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Código Animal / Arete', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Diagnóstico / Enfermedad', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Medicamento / Tratamiento', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Duración (Días) / Vencimiento', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tratamiento registrado correctamente')));
            },
            child: const Text('Guardar Tratamiento', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
