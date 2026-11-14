import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/feature_page_widgets.dart';
import '../../data/services/breeding_api_service.dart';

class ReproduccionScreen extends StatefulWidget {
  const ReproduccionScreen({
    super.key,
    this.repository = const BreedingApiService(),
  });

  final BreedingRepository repository;

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

  List<AnimalOption> _females = [];
  List<BreedingRecord> _records = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(
          () => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.repository.listAnimals(),
        widget.repository.listRecords(),
      ]);
      if (!mounted) return;
      setState(() {
        _females = (results[0] as List<AnimalOption>)
            .where((animal) => animal.isFemale)
            .toList();
        _records = results[1] as List<BreedingRecord>;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      _setError(error.message);
    } on FormatException catch (error) {
      _setError(error.message);
    } on Exception catch (error) {
      _setError('No se pudo cargar la reproducción: $error');
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _isLoading = false;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  List<BreedingRecord> get _filteredRecords {
    if (_searchQuery.isEmpty) return _records;
    return _records
        .where((item) =>
            item.animalTag.toLowerCase().contains(_searchQuery) ||
            (item.animalName ?? '').toLowerCase().contains(_searchQuery))
        .toList();
  }

  /// Vacas cuyo evento más reciente es una preñez confirmada.
  int get _pregnantCount {
    final latest = <int, BreedingRecord>{};
    for (final record in _records) {
      final current = latest[record.animalId];
      if (current == null || record.recordedAt.isAfter(current.recordedAt)) {
        latest[record.animalId] = record;
      }
    }
    return latest.values.where((r) => r.recordType == 'PRENEZ').length;
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isCompact ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FeaturePageBanner(
                  title: 'Control Reproducción',
                  subtitle:
                      'Seguimiento a celos, inseminaciones, preñeces y partos.',
                  icon: Icons.favorite_border,
                  isCompact: isCompact,
                ),
                const SizedBox(height: 28),
                _buildKpiMetricsRow(),
                const SizedBox(height: 32),
                _buildDataTableSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiMetricsRow() {
    int count(String type) => _records.where((r) => r.recordType == type).length;

    final cards = [
      _buildKpiCard('Celos', '${count('CELO')}', 'Celos registrados',
          Icons.notifications_active_outlined,
          const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
      _buildKpiCard('Inseminaciones', '${count('INSEMINACION')}',
          'Inseminaciones', Icons.science_outlined,
          const Color(0xFFECFDF5), const Color(0xFF059669)),
      _buildKpiCard('Gestantes', '$_pregnantCount', 'Vacas gestantes hoy',
          Icons.favorite_rounded,
          const Color(0xFFFEE2E2), const Color(0xFFEF4444)),
      _buildKpiCard('Partos', '${count('PARTO')}', 'Partos registrados',
          Icons.cake_outlined,
          const Color(0xFFFEF3C7), const Color(0xFFD97706)),
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

  Widget _buildDataTableSection() {
    final isNarrow = MediaQuery.sizeOf(context).width < 700;
    final canRegister = !_isLoading && _error == null;

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
            spacing: 16,
            runSpacing: 12,
            children: [
              Text(
                'Historial Reproductivo',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: primaryColor),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: TextField(
                  controller: _searchController,
                  decoration: _formDecoration('Buscar por chapeta')
                      .copyWith(prefixIcon: const Icon(Icons.search, size: 18)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: canRegister ? _openEventDialog : null,
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
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _buildMessage(
              _error!,
              action: OutlinedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Intentar de nuevo'),
              ),
            )
          else if (_filteredRecords.isEmpty)
            _buildMessage(_females.isEmpty && _records.isEmpty
                ? 'Registra primero una hembra en el módulo de Registro.'
                : 'No hay eventos reproductivos registrados')
          else
            _buildTable(_filteredRecords),
        ],
      ),
    );
  }

  Widget _buildTable(List<BreedingRecord> records) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(backgroundColor),
        dataRowMinHeight: 64,
        dataRowMaxHeight: 64,
        columns: [
          for (final title in const [
            'CHAPETA',
            'EVENTO',
            'FECHA',
            'FECHA ESPERADA',
            'DETALLE',
            'ESTADO ACTUAL',
            'ACCIONES',
          ])
            DataColumn(label: _buildTableHeader(title)),
        ],
        rows: records.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(
                item.animalTag,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryColor),
              )),
              DataCell(_buildEventoBadge(item)),
              DataCell(Text(formatDate(item.recordedAt),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14))),
              DataCell(Text(formatDate(item.expectedAt),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14))),
              DataCell(Text(item.notes ?? 'Sin observaciones',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: textMuted))),
              DataCell(Text(item.status,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor))),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined,
                        color: primaryColor, size: 20),
                    tooltip: 'Ver Detalle',
                    onPressed: () => _showDetail(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFFDC2626), size: 20),
                    tooltip: 'Eliminar',
                    onPressed: () => _confirmDelete(item),
                  ),
                ],
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTableHeader(String title) {
    return Text(title,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w800, color: textMuted));
  }

  Widget _buildMessage(String text, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Center(
        child: Column(
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w600, color: textMuted),
            ),
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }

  Widget _buildEventoBadge(BreedingRecord item) {
    final (bg, fg) = switch (item.recordType) {
      'CELO' => (const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
      'INSEMINACION' => (const Color(0xFFECFDF5), const Color(0xFF059669)),
      'PRENEZ' => (const Color(0xFFFEE2E2), const Color(0xFFEF4444)),
      _ => (const Color(0xFFFEF3C7), const Color(0xFFD97706)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        item.label,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Future<void> _confirmDelete(BreedingRecord item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: Text(
            '¿Eliminar el evento "${item.label}" de ${item.animalTag}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.deleteRecord(item.id);
      if (!mounted) return;
      setState(() => _records.removeWhere((r) => r.id == item.id));
      _showMessage('Evento eliminado.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _openEventDialog() async {
    if (_females.isEmpty) {
      _showMessage('Registra primero una hembra en el módulo de Registro.');
      return;
    }
    final formKey = GlobalKey<FormState>();
    final detalleController = TextEditingController();
    var animalId = _females.first.id;
    var eventType = breedingEventLabels.keys.first;
    var eventDate = DateTime.now();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;
            setDialogState(() => saving = true);
            try {
              final created = await widget.repository.createRecord(
                animalId: animalId,
                recordType: eventType,
                recordedAt: eventDate,
                notes: detalleController.text.trim(),
              );
              if (!mounted) return;
              setState(() => _records = [created, ..._records]
                ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt)));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              _showMessage('Evento reproductivo registrado.');
            } on ApiException catch (error) {
              setDialogState(() => saving = false);
              _showMessage(error.message);
            }
          }

          return AlertDialog(
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
                Expanded(
                  child: Text(
                    'Registrar Evento Reproductivo',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                        fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed:
                      saving ? null : () => Navigator.pop(dialogContext),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: animalId,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        decoration: _formDecoration('Hembra / Chapeta *'),
                        items: [
                          for (final animal in _females)
                            DropdownMenuItem(
                              value: animal.id,
                              child: Text(animal.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => animalId = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: eventType,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        decoration: _formDecoration('Tipo de Evento *'),
                        items: [
                          for (final entry in breedingEventLabels.entries)
                            DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => eventType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: eventDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => eventDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: _formDecoration('Fecha *').copyWith(
                            suffixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: accentColor),
                          ),
                          child: Text(formatDate(eventDate)),
                        ),
                      ),
                      if (eventType == 'PRENEZ')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Parto estimado: ${formatDate(eventDate.add(const Duration(days: 283)))} (283 días de gestación).',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, color: textMuted),
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: detalleController,
                        maxLines: 2,
                        decoration: _formDecoration('Detalle / Observaciones')
                            .copyWith(hintText: 'Ej. Toro 102, pajilla Gyr'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              OutlinedButton.icon(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
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
                onPressed: saving ? null : save,
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined, size: 16),
                label: const Text('Guardar Evento'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDetail(BreedingRecord item) {
    showDialog<void>(
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
                Text('Chapeta: ${item.animalTag}',
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
                  'Tipo de Evento', item.label, Icons.event_note_rounded),
              _buildDetailRow('Fecha', formatDate(item.recordedAt),
                  Icons.calendar_today_outlined),
              if (item.expectedAt != null)
                _buildDetailRow('Fecha esperada', formatDate(item.expectedAt),
                    Icons.event_available_outlined),
              _buildDetailRow(
                  'Estado Actual', item.status, Icons.info_outline_rounded),
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
                    Text(item.notes ?? 'Sin observaciones',
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
