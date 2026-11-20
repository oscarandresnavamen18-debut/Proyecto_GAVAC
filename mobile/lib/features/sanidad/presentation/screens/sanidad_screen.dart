import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/feature_page_widgets.dart';
import '../../data/services/health_api_service.dart';

const Map<String, String> _statusLabels = {
  'VIGENTE': 'Vigente',
  'PROXIMO_A_VENCER': 'Próximo a vencer',
  'VENCIDO': 'Vencido',
  'EN_TRATAMIENTO': 'En tratamiento',
  'FINALIZADO': 'Finalizado',
};

class SanidadScreen extends StatefulWidget {
  const SanidadScreen({super.key, this.repository = const HealthApiService()});

  final HealthRepository repository;

  @override
  State<SanidadScreen> createState() => _SanidadScreenState();
}

class _SanidadScreenState extends State<SanidadScreen> {
  static const Color primaryColor = Color(0xFF1A3A32);
  static const Color backgroundColor = Color(0xFFF7F9F7);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF64748B);

  List<AnimalOption> _animals = [];
  List<HealthRecord> _records = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
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
        _animals = results[0] as List<AnimalOption>;
        _records = results[1] as List<HealthRecord>;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      _setError(error.message);
    } on FormatException catch (error) {
      _setError(error.message);
    } on Exception catch (error) {
      _setError('No se pudo cargar la sanidad: $error');
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

  /// Último registro de cada vacuna por animal: una vacuna renovada no debe
  /// seguir generando alertas por su aplicación anterior.
  List<HealthRecord> get _latestVaccines {
    final latest = <String, HealthRecord>{};
    for (final record in _records.where((r) => r.isVaccine)) {
      final key = '${record.animalId}|${record.diagnosis.toLowerCase().trim()}';
      final current = latest[key];
      if (current == null || record.recordedAt.isAfter(current.recordedAt)) {
        latest[key] = record;
      }
    }
    return latest.values.toList();
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
                  title: 'Control y Sanidad Ganadera',
                  subtitle: 'Gestión de vacunas, tratamientos y prevención sanitaria.',
                  icon: Icons.shield_outlined,
                  isCompact: isCompact,
                ),
                const SizedBox(height: 28),
                _buildKpiMetricsRow(),
                const SizedBox(height: 28),
                _buildActionButtons(),
                const SizedBox(height: 32),
                _buildHistorialSanitarioSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiMetricsRow() {
    final vaccines = _latestVaccines;
    final protectedAnimals = vaccines
        .where((r) => r.status == 'VIGENTE' || r.status == 'PROXIMO_A_VENCER')
        .map((r) => r.animalId)
        .toSet()
        .length;
    final coverage = _animals.isEmpty
        ? '0%'
        : '${(protectedAnimals * 100 / _animals.length).toStringAsFixed(0)}%';
    final activeTreatments = _records
        .where((r) => r.status == 'EN_TRATAMIENTO')
        .length;
    final alerts = vaccines
        .where((r) => r.status == 'VENCIDO' || r.status == 'PROXIMO_A_VENCER')
        .length;

    final cards = [
      _buildKpiCard(
        title: 'Vacunación Vigente',
        value: coverage,
        subtitle: 'Animales con vacuna vigente',
        icon: Icons.shield_rounded,
        iconBgColor: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
      ),
      _buildKpiCard(
        title: 'Tratamientos Activos',
        value: '$activeTreatments',
        subtitle: 'Tratamientos Activos',
        icon: Icons.add_box_rounded,
        iconBgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _buildKpiCard(
        title: 'Alertas Vencimiento',
        value: '$alerts',
        subtitle: 'Vacunas vencidas o por vencer',
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

  Widget _buildActionButtons() {
    final enabled = !_isLoading && _error == null;
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: enabled ? () => _openRecordDialog(vaccine: true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.vaccines_rounded, size: 18),
          label: Text(
            'Registrar Vacuna',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: enabled ? () => _openRecordDialog(vaccine: false) : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: const BorderSide(color: primaryColor, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.medical_services_outlined, size: 18),
          label: Text(
            'Registrar Tratamiento',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorialSanitarioSection() {
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
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _buildMessage(
              icon: Icons.cloud_off_outlined,
              text: _error!,
              action: OutlinedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Intentar de nuevo'),
              ),
            )
          else if (_records.isEmpty)
            _buildMessage(
              icon: Icons.folder_open_rounded,
              text: _animals.isEmpty
                  ? 'Registra primero un animal en el módulo de Registro.'
                  : 'No hay registros sanitarios disponibles',
            )
          else
            _buildTable(),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(backgroundColor),
        dataRowMinHeight: 64,
        dataRowMaxHeight: 64,
        columns: [
          for (final title in const [
            'ANIMAL / CHAPETA',
            'TIPO',
            'VACUNA / DIAGNÓSTICO',
            'APLICACIÓN',
            'PRÓXIMA FECHA',
            'DOSIS',
            'VETERINARIO',
            'ESTADO',
            '',
          ])
            DataColumn(label: _buildTableHeader(title)),
        ],
        rows: _records.map((record) {
          return DataRow(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      record.animalTag,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    if (record.animalName != null)
                      Text(
                        record.animalName!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              DataCell(_buildTypeBadge(record.isVaccine)),
              DataCell(
                Text(
                  record.isVaccine
                      ? record.diagnosis
                      : '${record.diagnosis}${record.treatment == null ? '' : ' · ${record.treatment}'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(_cellText(formatDate(record.recordedAt))),
              DataCell(_cellText(formatDate(record.nextCheckAt))),
              DataCell(_cellText(record.dose ?? '—')),
              DataCell(_cellText(record.veterinarian ?? '—')),
              DataCell(_buildStatusBadge(record.status)),
              DataCell(
                IconButton(
                  tooltip: 'Eliminar registro',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFDC2626),
                    size: 20,
                  ),
                  onPressed: () => _confirmDelete(record),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _cellText(String value) =>
      Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13));

  Widget _buildTableHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: textMuted,
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String text,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: textMuted),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(bool vaccine) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: vaccine ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        vaccine ? 'Vacuna' : 'Tratamiento',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: vaccine ? const Color(0xFF059669) : const Color(0xFF2563EB),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final (bgColor, textColor) = switch (status) {
      'VIGENTE' => (const Color(0xFFECFDF5), const Color(0xFF059669)),
      'PROXIMO_A_VENCER' => (const Color(0xFFFFFBEB), const Color(0xFFD97706)),
      'VENCIDO' => (const Color(0xFFFEF2F2), const Color(0xFFDC2626)),
      'FINALIZADO' => (const Color(0xFFF1F5F9), textMuted),
      _ => (const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _statusLabels[status] ?? status,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(HealthRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text(
          '¿Eliminar ${record.isVaccine ? 'la vacuna' : 'el tratamiento'} '
          '"${record.diagnosis}" de ${record.animalTag}?',
        ),
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
      await widget.repository.deleteRecord(record.id);
      if (!mounted) return;
      setState(() => _records.removeWhere((r) => r.id == record.id));
      _showMessage('Registro eliminado.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  /// Formulario para registrar una vacuna o un tratamiento.
  Future<void> _openRecordDialog({required bool vaccine}) async {
    if (_animals.isEmpty) {
      _showMessage('Registra primero un animal en el módulo de Registro.');
      return;
    }
    final formKey = GlobalKey<FormState>();
    final diagnosisController = TextEditingController();
    final treatmentController = TextEditingController();
    final doseController = TextEditingController();
    final vetController = TextEditingController();
    var animalId = _animals.first.id;
    var appliedAt = DateTime.now();
    DateTime? nextAt;
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickDate({required bool next}) async {
            final picked = await showDatePicker(
              context: context,
              initialDate: next ? (nextAt ?? appliedAt) : appliedAt,
              firstDate: next ? appliedAt : DateTime(2000),
              lastDate: next ? DateTime(2100) : DateTime.now(),
            );
            if (picked != null) {
              setDialogState(() {
                if (next) {
                  nextAt = picked;
                } else {
                  appliedAt = picked;
                  if (nextAt != null && nextAt!.isBefore(picked)) nextAt = null;
                }
              });
            }
          }

          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;
            setDialogState(() => saving = true);
            try {
              final created = await widget.repository.createRecord(
                animalId: animalId,
                recordType: vaccine ? 'VACUNA' : 'TRATAMIENTO',
                diagnosis: diagnosisController.text.trim(),
                treatment: vaccine ? null : treatmentController.text.trim(),
                dose: doseController.text.trim(),
                veterinarian: vetController.text.trim(),
                recordedAt: appliedAt,
                nextCheckAt: nextAt,
              );
              if (!mounted) return;
              setState(() => _records = [created, ..._records]);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              _showMessage(
                vaccine
                    ? 'Vacuna registrada correctamente.'
                    : 'Tratamiento registrado correctamente.',
              );
            } on ApiException catch (error) {
              setDialogState(() => saving = false);
              _showMessage(error.message);
            }
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: vaccine
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    vaccine
                        ? Icons.vaccines_rounded
                        : Icons.medical_services_outlined,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vaccine ? 'Registrar Vacuna' : 'Registrar Tratamiento',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
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
                        decoration: _formDecoration('Animal / Chapeta *'),
                        items: [
                          for (final animal in _animals)
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
                      TextFormField(
                        controller: diagnosisController,
                        decoration:
                            _formDecoration(
                              vaccine ? 'Nombre de Vacuna *' : 'Diagnóstico *',
                            ).copyWith(
                              hintText: vaccine
                                  ? 'Ej. Aftosa / Brucelosis'
                                  : 'Ej. Mastitis / Parasitosis',
                            ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Campo obligatorio'
                            : null,
                      ),
                      if (!vaccine) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: treatmentController,
                          decoration: _formDecoration('Medicamento *')
                              .copyWith(hintText: 'Ej. Antibiótico / Purgante'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Campo obligatorio'
                              : null,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: doseController,
                              decoration:
                                  _formDecoration(
                                    vaccine ? 'Dosis (ml) *' : 'Dosis *',
                                  ).copyWith(
                                    hintText: vaccine
                                        ? 'Ej. 2 ml'
                                        : 'Ej. 5 ml cada 24h',
                                  ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Campo obligatorio'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: vetController,
                              decoration: _formDecoration('Veterinario')
                                  .copyWith(hintText: 'Por defecto: tu nombre'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              label: 'Fecha de aplicación *',
                              value: appliedAt,
                              decoration: _formDecoration,
                              onTap: () => pickDate(next: false),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DateField(
                              label: vaccine
                                  ? 'Próxima dosis'
                                  : 'Fin del seguimiento',
                              value: nextAt,
                              decoration: _formDecoration,
                              onTap: () => pickDate(next: true),
                            ),
                          ),
                        ],
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
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 16),
                label: Text(vaccine ? 'Guardar Vacuna' : 'Guardar Tratamiento'),
              ),
            ],
          );
        },
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

/// Campo de solo lectura que abre un selector de fecha.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.decoration,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final InputDecoration Function(String) decoration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: decoration(label).copyWith(
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(value == null ? 'Sin fecha' : formatDate(value)),
      ),
    );
  }
}
