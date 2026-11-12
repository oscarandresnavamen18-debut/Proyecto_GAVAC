import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/feature_page_widgets.dart';

/// Modelo de datos para el módulo de Reproducción
class ReproduccionRecord {
  final String id;
  final String chapeta;
  final String evento; // 'Celo', 'Inseminación', 'Preñez', 'Parto'
  final String fecha;
  final String detalleAdicional;
  final String estadoActual;

  const ReproduccionRecord({
    required this.id,
    required this.chapeta,
    required this.evento,
    required this.fecha,
    required this.detalleAdicional,
    required this.estadoActual,
  });
}

class ReproduccionScreen extends StatefulWidget {
  final String? totalGestantes;
  final String? proximasPartoCount;
  final String? vaciasCount;
  final List<ReproduccionRecord>? registros;

  const ReproduccionScreen({
    super.key,
    this.totalGestantes,
    this.proximasPartoCount,
    this.vaciasCount,
    this.registros,
  });

  @override
  State<ReproduccionScreen> createState() => _ReproduccionScreenState();
}

class _ReproduccionScreenState extends State<ReproduccionScreen> {
  static const Color primaryColor = Color(0xFF1A3A32);
  static const Color accentColor = Color(0xFF2E5A4D);
  static const Color backgroundColor = Color(0xFFF7F9F7);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF64748B);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late List<ReproduccionRecord> _listaRegistros;

  @override
  void initState() {
    super.initState();
    _listaRegistros = List.from(widget.registros ?? []);

    _searchController.addListener(() {
      if (!mounted) return;
      setState(
          () => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReproduccionRecord> get _filteredRegistros {
    if (_searchQuery.isEmpty) {
      return _listaRegistros;
    }
    return _listaRegistros
        .where((item) => item.chapeta.toLowerCase().contains(_searchQuery))
        .toList();
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
              _buildDataTableSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    return FeaturePageBanner(
      title: 'Control Reproducción',
      subtitle: 'Seguimiento a celos, inseminaciones, preñeces y partos.',
      icon: Icons.favorite_border,
      isCompact: isCompact,
    );
  }

  Widget _buildKpiMetricsRow() {
    final celos = _listaRegistros.where((r) => r.evento == 'Celo').length;
    final inseminaciones =
        _listaRegistros.where((r) => r.evento == 'Inseminación').length;
    final preneces = _listaRegistros.where((r) => r.evento == 'Preñez').length;
    final partos = _listaRegistros.where((r) => r.evento == 'Parto').length;

    final cards = [
      _buildKpiCard(
        'Celos',
        '$celos',
        'Celos',
        Icons.notifications_active_outlined,
        const Color(0xFFEFF6FF),
        const Color(0xFF2563EB),
      ),
      _buildKpiCard(
        'Inseminaciones',
        '$inseminaciones',
        'Inseminaciones',
        Icons.science_outlined,
        const Color(0xFFECFDF5),
        const Color(0xFF059669),
      ),
      _buildKpiCard(
        'Preñeces',
        '$preneces',
        'Preñeces',
        Icons.favorite_rounded,
        const Color(0xFFFEE2E2),
        const Color(0xFFEF4444),
      ),
      _buildKpiCard(
        'Partos',
        '$partos',
        'Partos',
        Icons.cake_outlined,
        const Color(0xFFFEF3C7),
        const Color(0xFFD97706),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) => FeatureMetricLayout(
        cards: cards,
        isCompact: constraints.maxWidth < 900,
        horizontalSpacing: 14,
        verticalSpacing: 12,
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle,
      IconData icon, Color iconBgColor, Color iconColor) {
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
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        onPressed: () => _mostrarModalRegistrarEvento(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
        label: Text(
          'Registrar Evento',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildDataTableSection(BuildContext context) {
    final registrosMostrados = _filteredRegistros;
    final isNarrow = MediaQuery.sizeOf(context).width < 700;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isNarrow ? 16 : 28),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              if (isNarrow)
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Historial Reproductivo',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: primaryColor),
                  ),
                )
              else
                Text(
                  'Historial Reproductivo',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: primaryColor),
                ),
              ElevatedButton.icon(
                onPressed: () => _mostrarModalRegistrarEvento(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Registrar Evento',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          registrosMostrados.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(backgroundColor),
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 64,
                    columns: [
                      DataColumn(label: _buildTableHeader('CHAPETA ÚNICA')),
                      DataColumn(label: _buildTableHeader('EVENTO REGISTRADO')),
                      DataColumn(label: _buildTableHeader('FECHA')),
                      DataColumn(label: _buildTableHeader('DETALLE ADICIONAL')),
                      DataColumn(label: _buildTableHeader('ESTADO ACTUAL')),
                      DataColumn(label: _buildTableHeader('ACCIONES')),
                    ],
                    rows: registrosMostrados.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              item.chapeta,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor),
                            ),
                          ),
                          DataCell(_buildEventoBadge(item.evento)),
                          DataCell(Text(item.fecha,
                              style:
                                  GoogleFonts.plusJakartaSans(fontSize: 14))),
                          DataCell(Text(item.detalleAdicional,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, color: textMuted))),
                          DataCell(Text(item.estadoActual,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor))),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined,
                                  color: primaryColor, size: 20),
                              tooltip: 'Ver Detalle',
                              onPressed: () =>
                                  _mostrarModalDetalle(context, item),
                            ),
                          ),
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
    return Text(title,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w800, color: textMuted));
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Center(
        child: Column(
          children: [
            Text(
              'No hay eventos reproductivos registrados',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w600, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventoBadge(String evento) {
    Color bg;
    Color fg;
    switch (evento) {
      case 'Celo':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        break;
      case 'Inseminación':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        break;
      case 'Preñez':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFEF4444);
        break;
      case 'Parto':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        evento,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  // --- MODAL REGISTRAR EVENTO REPRODUCTIVO ---
  void _mostrarModalRegistrarEvento(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final chapetaController = TextEditingController();
    final fechaController = TextEditingController();
    final detalleController = TextEditingController();
    String eventoSeleccionado = 'Celo';
    DateTime fechaEvento = DateTime.now();
    fechaController.text =
        '${fechaEvento.day.toString().padLeft(2, '0')}/${fechaEvento.month.toString().padLeft(2, '0')}/${fechaEvento.year}';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.favorite_border,
                    color: primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Registrar Evento Reproductivo',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                    fontSize: 18),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(dialogContext),
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
                          controller: chapetaController,
                          style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF1E293B), fontSize: 14),
                          decoration: _formDecoration('Animal / Chapeta *')
                              .copyWith(hintText: 'Ej. CH-1024'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Campo obligatorio'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: eventoSeleccionado,
                          dropdownColor: Colors.white,
                          style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF1E293B), fontSize: 14),
                          decoration: _formDecoration('Tipo de Evento *'),
                          items: const [
                            DropdownMenuItem(
                                value: 'Celo',
                                child: Text('Celo',
                                    style: TextStyle(color: primaryColor))),
                            DropdownMenuItem(
                                value: 'Inseminación',
                                child: Text('Inseminación',
                                    style: TextStyle(color: primaryColor))),
                            DropdownMenuItem(
                                value: 'Preñez',
                                child: Text('Preñez',
                                    style: TextStyle(color: primaryColor))),
                            DropdownMenuItem(
                                value: 'Parto',
                                child: Text('Parto',
                                    style: TextStyle(color: primaryColor))),
                          ],
                          onChanged: (v) => setDialogState(
                              () => eventoSeleccionado = v ?? 'Celo'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: fechaController,
                          readOnly: true,
                          style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF1E293B), fontSize: 14),
                          decoration: _formDecoration('Fecha *').copyWith(
                            suffixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: accentColor),
                          ),
                          onTap: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: fechaEvento,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (selectedDate != null) {
                              setDialogState(() {
                                fechaEvento = selectedDate;
                                fechaController.text =
                                    '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: detalleController,
                          style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF1E293B), fontSize: 14),
                          decoration: _formDecoration('Detalle / Observaciones')
                              .copyWith(hintText: 'Ej. Toro 102'),
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
              onPressed: () => Navigator.pop(dialogContext),
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
                Navigator.pop(dialogContext);
                setState(() {
                  _listaRegistros.insert(
                    0,
                    ReproduccionRecord(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      chapeta: chapetaController.text.trim(),
                      evento: eventoSeleccionado,
                      fecha: fechaController.text.trim(),
                      detalleAdicional: detalleController.text.trim().isNotEmpty
                          ? detalleController.text.trim()
                          : 'Sin observaciones',
                      estadoActual: 'En seguimiento',
                    ),
                  );
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Evento reproductivo registrado.')));
              },
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Guardar Evento'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarModalDetalle(BuildContext context, ReproduccionRecord item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14)),
              child:
                  const Icon(Icons.pets_rounded, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detalle del Evento',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: primaryColor)),
                Text('Chapeta: ${item.chapeta}',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: textMuted)),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(color: borderColor),
              const SizedBox(height: 12),
              _buildDetailRow(
                  'Tipo de Evento', item.evento, Icons.event_note_rounded),
              _buildDetailRow(
                  'Fecha', item.fecha, Icons.calendar_today_outlined),
              _buildDetailRow('Estado Actual', item.estadoActual,
                  Icons.info_outline_rounded),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detalle / Observaciones:',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: textMuted)),
                    const SizedBox(height: 4),
                    Text(item.detalleAdicional,
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: primaryColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label:',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600, color: textMuted, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  fontSize: 14),
            ),
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
