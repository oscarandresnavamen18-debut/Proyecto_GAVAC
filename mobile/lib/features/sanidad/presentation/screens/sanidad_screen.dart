import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/feature_page_widgets.dart';

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
  static const Color primaryColor = Color(0xFF1A3A32);
  static const Color backgroundColor = Color(0xFFF7F9F7);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF64748B);

  late List<RegistroSanitario> _listaRegistros;

  @override
  void initState() {
    super.initState();
    _listaRegistros = List.from(widget.registros);
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 28),
              _buildKpiMetricsRow(),
              const SizedBox(height: 28),
              _buildActionButtons(context),
              const SizedBox(height: 32),
              _buildHistorialSanitarioSection(context),
            ],
          ),
        ),
      ),
    );
  }

  // Encabezado principal Banner
  Widget _buildHeader(bool isCompact) {
    return FeaturePageBanner(
      title: 'Control y Sanidad Ganadera',
      subtitle: 'Gestión de vacunas, tratamientos y prevención sanitaria.',
      icon: Icons.shield_outlined,
      isCompact: isCompact,
    );
  }

  // Métricas KPI Horizontales con Adaptabilidad Responsiva
  Widget _buildKpiMetricsRow() {
    final cards = [
      _buildKpiCard(
        title: 'Vacunación Vigente',
        value: widget.vacunacionPorcentaje,
        subtitle: 'Vacunación Vigente',
        icon: Icons.shield_rounded,
        iconBgColor: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
      ),
      _buildKpiCard(
        title: 'Tratamientos Activos',
        value: widget.controlesPendientes,
        subtitle: 'Tratamientos Activos',
        icon: Icons.add_box_rounded,
        iconBgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _buildKpiCard(
        title: 'Alertas Vencimiento',
        value: widget.alertasSanitarias,
        subtitle: 'Alertas Vencimiento',
        icon: Icons.warning_amber_rounded,
        iconBgColor: const Color(0xFFFEF2F2),
        iconColor: const Color(0xFFDC2626),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) => FeatureMetricLayout(
        cards: cards,
        isCompact: constraints.maxWidth < 800,
        horizontalSpacing: 12,
        verticalSpacing: 12,
      ),
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
    return FeatureKpiCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      iconBgColor: iconBgColor,
      iconColor: iconColor,
      cardColor: cardColor,
      borderColor: borderColor,
      textColor: textMuted,
      valueColor: primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  // Botonera de Acción
  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: () => _mostrarModalRegistrarVacuna(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          icon: const Icon(Icons.vaccines_rounded, size: 18),
          label: Text(
            'Registrar Vacuna',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _mostrarModalRegistrarTratamiento(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: const BorderSide(color: primaryColor, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.medical_services_outlined, size: 18),
          label: Text(
            'Registrar Tratamiento',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  // Historial Sanitario
  Widget _buildHistorialSanitarioSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
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
          Text(
            'Historial Sanitario del Ganado',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          if (_listaRegistros.isEmpty)
            _buildEmptyState()
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(backgroundColor),
                dataRowMinHeight: 64,
                dataRowMaxHeight: 64,
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
                rows: _listaRegistros.map((registro) {
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: registro.tipo == 'Vacuna'
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            registro.tipo,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: registro.tipo == 'Vacuna'
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(registro.evento,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, fontWeight: FontWeight.w600))),
                      DataCell(Text(registro.fechaAplicacion,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13))),
                      DataCell(Text(registro.fechaVencimiento,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13))),
                      DataCell(Text(registro.dosis,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13))),
                      DataCell(Text(registro.veterinario,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13))),
                      DataCell(_buildStatusBadge(
                          registro.estado, registro.tipoEstado)),
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
      style: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w800, color: textMuted),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.folder_open_rounded, size: 48, color: textMuted),
            const SizedBox(height: 12),
            Text(
              'No hay registros sanitarios disponibles',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w600, color: textMuted),
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
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  // Modal Registrar Vacuna
  void _mostrarModalRegistrarVacuna(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final animalController = TextEditingController();
    final vacunaController = TextEditingController();
    final dosisController = TextEditingController();
    final fechaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.vaccines_rounded,
                  color: primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Registrar Vacuna',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800, color: primaryColor),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: animalController,
                        decoration: _formDecoration('Animal / Chapeta *')
                            .copyWith(hintText: 'Ej. CH-1024'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Campo obligatorio' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: vacunaController,
                        decoration: _formDecoration('Nombre de Vacuna *')
                            .copyWith(hintText: 'Ej. Aftosa / Brucelosis'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Campo obligatorio' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: dosisController,
                        decoration: _formDecoration('Dosis (ml) *')
                            .copyWith(hintText: 'Ej. 2 ml'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Campo obligatorio' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: fechaController,
                        decoration: _formDecoration('Próximo Ciclo *')
                            .copyWith(hintText: 'DD/MM/YYYY'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Campo obligatorio' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Cancelar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: const BorderSide(color: primaryColor),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              setState(() {
                _listaRegistros.add(
                  RegistroSanitario(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    codigo: animalController.text.trim(),
                    arete: animalController.text.trim(),
                    tipo: 'Vacuna',
                    evento: vacunaController.text.trim(),
                    fechaAplicacion: 'Hoy',
                    fechaVencimiento: fechaController.text.trim(),
                    dosis: dosisController.text.trim(),
                    veterinario: 'Veterinario',
                    estado: 'Vigente',
                    tipoEstado: 'success',
                  ),
                );
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Vacuna registrada correctamente.')));
            },
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('Guardar Vacuna'),
          ),
        ],
      ),
    );
  }

  // Modal Registrar Tratamiento
  void _mostrarModalRegistrarTratamiento(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final animalController = TextEditingController();
    final diagController = TextEditingController();
    final medController = TextEditingController();
    final dosisController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.medical_services_outlined,
                  color: primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Registrar Tratamiento',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800, color: primaryColor),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: animalController,
                        decoration: _formDecoration('Animal / Chapeta *')
                            .copyWith(hintText: 'Ej. CH-1024'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Campo obligatorio' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: diagController,
                        decoration: _formDecoration('Diagnóstico *')
                            .copyWith(hintText: 'Ej. Mastitis / Parasitosis'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Campo obligatorio' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: medController,
                        decoration: _formDecoration('Medicamento *')
                            .copyWith(hintText: 'Ej. Antibiótico / Purgante'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Campo obligatorio' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: dosisController,
                        decoration: _formDecoration('Dosis *')
                            .copyWith(hintText: 'Ej. 5 ml cada 24h'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Campo obligatorio' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Cancelar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: const BorderSide(color: primaryColor),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              setState(() {
                _listaRegistros.add(
                  RegistroSanitario(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    codigo: animalController.text.trim(),
                    arete: animalController.text.trim(),
                    tipo: 'Tratamiento',
                    evento: diagController.text.trim(),
                    fechaAplicacion: 'Hoy',
                    fechaVencimiento: 'En seguimiento',
                    dosis: dosisController.text.trim(),
                    veterinario: 'Veterinario',
                    estado: 'Vigente',
                    tipoEstado: 'info',
                  ),
                );
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Tratamiento registrado correctamente.')));
            },
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('Guardar Tratamiento'),
          ),
        ],
      ),
    );
  }

  InputDecoration _formDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF475569),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF94A3B8),
        fontSize: 13,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }
}
