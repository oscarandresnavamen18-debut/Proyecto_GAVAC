import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modelo de datos para el módulo de Reproducción (Basado en Criterios de Aceptación)
class ReproduccionRecord {
  final String id;
  final String chapeta;
  final String evento; // 'Celo', 'Inseminación', 'Preñez', 'Parto'
  final String fecha;
  final String detalleAdicional; // Toro, cría, observaciones
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
  // Colores Oficiales GAVAC Design System
  static const Color primaryColor = Color(0xFF1A3A32); // Deep Forest Green
  static const Color accentColor = Color(0xFF2E5A4D);  // Dark Emerald Accent
  static const Color backgroundColor = Color(0xFFF7F9F7); // Soft Clean Off-White
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF94A3B8);

  // Controlador para el campo de filtro por Chapeta
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late List<ReproduccionRecord> _listaRegistros;

  @override
  void initState() {
    super.initState();
    _listaRegistros = widget.registros ?? const [
      ReproduccionRecord(
        id: '1',
        chapeta: 'CH-1024',
        evento: 'Preñez',
        fecha: '15/01/2026',
        detalleAdicional: 'Diagnóstico positivo por palpación',
        estadoActual: 'Gestante',
      ),
      ReproduccionRecord(
        id: '2',
        chapeta: 'CH-1025',
        evento: 'Inseminación',
        fecha: '10/02/2026',
        detalleAdicional: 'Semen Toro Brahman TR-08',
        estadoActual: 'Inseminada',
      ),
      ReproduccionRecord(
        id: '3',
        chapeta: 'CH-1026',
        evento: 'Celo',
        fecha: '20/02/2026',
        detalleAdicional: 'Se detecta celo activo en corral',
        estadoActual: 'Disponible',
      ),
      ReproduccionRecord(
        id: '4',
        chapeta: 'CH-1020',
        evento: 'Parto',
        fecha: '01/03/2026',
        detalleAdicional: 'Cría hembra nacida sin novedad',
        estadoActual: 'Lactancia',
      ),
    ];

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtrado dinámico por chapeta
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
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 28),
              _buildKpiMetricsRow(),
              const SizedBox(height: 32),
              _buildDataTableSection(context),
            ],
          ),
        ),
      ),
    );
  }

  // Encabezado del Módulo
  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Control de Eventos Reproductivos',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Seguimiento al ciclo reproductivo: celo, inseminación, preñez y parto de cada animal.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        );
        final button = ElevatedButton.icon(
          onPressed: () => _mostrarModalRegistrarEvento(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 2,
          ),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          label: Text(
            'Registrar Evento',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        );
        if (constraints.maxWidth < 850) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 16), button],
          );
        }
        return Row(
          children: [Expanded(child: title), const SizedBox(width: 16), button],
        );
      },
    );
  }

  // Tarjetas de Métricas KPI basadas en los criterios
  Widget _buildKpiMetricsRow() {
    final celos = _listaRegistros.where((r) => r.evento == 'Celo').length;
    final inseminaciones = _listaRegistros.where((r) => r.evento == 'Inseminación').length;
    final preneces = _listaRegistros.where((r) => r.evento == 'Preñez').length;
    final partos = _listaRegistros.where((r) => r.evento == 'Parto').length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100 ? 4 : constraints.maxWidth >= 650 ? 2 : 1;
        const spacing = 16.0;
        final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(width: cardWidth, child: _buildKpiCard('Celos Registrados', '$celos', 'Detección en campo', Icons.notifications_active_outlined, const Color(0xFFEFF6FF), const Color(0xFF2563EB))),
            SizedBox(width: cardWidth, child: _buildKpiCard('Inseminaciones', '$inseminaciones', 'Servicios aplicados', Icons.science_outlined, const Color(0xFFECFDF5), const Color(0xFF059669))),
            SizedBox(width: cardWidth, child: _buildKpiCard('Preñeces', '$preneces', 'Diagnósticos positivos', Icons.favorite_rounded, const Color(0xFFFEE2E2), const Color(0xFFEF4444))),
            SizedBox(width: cardWidth, child: _buildKpiCard('Partos', '$partos', 'Nacimientos registrados', Icons.cake_outlined, const Color(0xFFFEF3C7), const Color(0xFFD97706))),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, IconData icon, Color iconBgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
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
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: textMuted),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w900, color: primaryColor),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: textMuted),
          ),
        ],
      ),
    );
  }

  // Sección de Tabla + Buscador por Chapeta
  Widget _buildDataTableSection(BuildContext context) {
    final registrosMostrados = _filteredRegistros;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(36),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final title = Text(
                'Historial de Eventos Reproductivos',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: primaryColor),
              );
              final search = SizedBox(
                width: constraints.maxWidth < 900 ? constraints.maxWidth : 300,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Filtrar por chapeta (ej. CH-1024)...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: primaryColor, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: textMuted),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
                  ),
                ),
              );
              if (constraints.maxWidth < 900) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 12), search],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Expanded(child: title), const SizedBox(width: 16), search],
              );
            },
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
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: primaryColor),
                      ),
                    ),
                    DataCell(_buildEventoBadge(item.evento)),
                    DataCell(Text(item.fecha, style: GoogleFonts.plusJakartaSans(fontSize: 14))),
                    DataCell(Text(item.detalleAdicional, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textMuted))),
                    DataCell(Text(item.estadoActual, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor))),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, color: primaryColor, size: 20),
                        tooltip: 'Ver Detalle',
                        onPressed: () => _mostrarModalDetalle(context, item),
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
    return Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: textMuted));
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: textMuted),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty ? 'No hay eventos registrados' : 'No se encontraron registros para la chapeta "$_searchQuery"',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: textMuted),
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        evento,
        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  // --- MODAL DETALLE ---
  void _mostrarModalDetalle(BuildContext context, ReproduccionRecord item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.pets_rounded, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detalle del Evento', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: primaryColor)),
                Text('Chapeta: ${item.chapeta}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: textMuted)),
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
              _buildDetailRow('Tipo de Evento', item.evento, Icons.event_note_rounded),
              _buildDetailRow('Fecha', item.fecha, Icons.calendar_today_outlined),
              _buildDetailRow('Estado Actual', item.estadoActual, Icons.info_outline_rounded),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detalle / Observaciones:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: textMuted)),
                    const SizedBox(height: 4),
                    Text(item.detalleAdicional, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, color: primaryColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
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
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label:',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: textMuted, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: primaryColor, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODAL DE REGISTRO (Criterios de Aceptación: Celo, Inseminación, Preñez, Parto) ---
  void _mostrarModalRegistrarEvento(BuildContext context) {
    String eventoSeleccionado = 'Celo';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          title: Text(
            'Registrar Evento Reproductivo',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: primaryColor),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Chapeta / Arete Único',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Seleccione el Evento:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: textMuted)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: eventoSeleccionado,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  items: ['Celo', 'Inseminación', 'Preñez', 'Parto']
                      .map((evento) => DropdownMenuItem(value: evento, child: Text(evento, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setStateModal(() => eventoSeleccionado = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Detalle (Toro, observaciones, cría)',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Evento de "$eventoSeleccionado" registrado exitosamente')),
                );
              },
              child: Text('Guardar Evento', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}