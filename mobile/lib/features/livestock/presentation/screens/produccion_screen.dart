import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/gavac_colors.dart';
import '../../../../core/widgets/feature_page_widgets.dart';

class ProduccionScreen extends StatefulWidget {
  const ProduccionScreen({super.key});

  @override
  State<ProduccionScreen> createState() => _ProduccionScreenState();
}

class _ProduccionScreenState extends State<ProduccionScreen> {
  final List<_ProductionRecord> _records = [];
  final _tagController = TextEditingController();
  final _litersController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    _litersController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  double get _totalMilk =>
      _records.fold(0, (total, record) => total + (record.liters ?? 0));

  double? get _averageWeight {
    final weights = _records
        .where((record) => record.weight != null)
        .map((record) => record.weight!)
        .toList();
    if (weights.isEmpty) return null;
    return weights.reduce((total, weight) => total + weight) / weights.length;
  }

  Future<void> _showRegisterDialog() async {
    final formKey = GlobalKey<FormState>();
    _tagController.clear();
    _litersController.clear();
    _weightController.clear();

    final record = await showDialog<_ProductionRecord>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Nuevo registro',
          style: GoogleFonts.plusJakartaSans(
            color: GavacColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _tagController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Identificación del animal',
                    hintText: 'Ej. CH-1024',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa la identificación del animal.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _litersController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Leche producida',
                    hintText: 'Ej. 15.5',
                    suffixText: 'L',
                    prefixIcon: Icon(Icons.water_drop_outlined),
                  ),
                  validator: (value) => _validateOptionalNumber(
                    value,
                    'Ingresa una cantidad válida de litros.',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Peso actual',
                    hintText: 'Ej. 450',
                    suffixText: 'kg',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                  ),
                  validator: (value) => _validateOptionalNumber(
                    value,
                    'Ingresa un peso válido.',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                dialogContext,
                _ProductionRecord(
                  tag: _tagController.text.trim().toUpperCase(),
                  liters: _parseOptionalNumber(_litersController.text),
                  weight: _parseOptionalNumber(_weightController.text),
                ),
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Guardar registro'),
          ),
        ],
      ),
    );

    if (record == null || !mounted) return;
    setState(() => _records.insert(0, record));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro guardado en esta sesión.')),
    );
  }

  String? _validateOptionalNumber(String? value, String message) {
    if (value == null || value.trim().isEmpty) return null;
    final number = _parseOptionalNumber(value);
    if (number == null || number <= 0) return message;
    return null;
  }

  double? _parseOptionalNumber(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

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
                    icon: Icons.water_drop_outlined,
                    title: 'Producción',
                    subtitle:
                        'Registra la producción diaria y consulta el rendimiento del ganado.',
                  ),
                  const SizedBox(height: 24),
                  _buildMetrics(),
                  const SizedBox(height: 24),
                  FeaturePanel(
                    title: 'Registros de producción',
                    subtitle:
                        'Control de leche y peso registrado durante esta sesión.',
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _showRegisterDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Nuevo registro'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_records.isEmpty)
                          const _EmptyState(
                            icon: Icons.query_stats,
                            title: 'Aún no hay registros',
                            message:
                                'Agrega el primer registro para ver aquí la producción de tu ganado.',
                          )
                        else
                          ..._records.map(
                            (record) => _ProductionRecordTile(
                              record: record,
                              onDelete: () =>
                                  setState(() => _records.remove(record)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _SessionNotice(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetrics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final cardWidth = constraints.maxWidth < 520
            ? (constraints.maxWidth - spacing) / 2
            : (constraints.maxWidth - (spacing * 2)) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: FeatureMetricCard(
                value: '${_formatNumber(_totalMilk)} L',
                label: 'Leche registrada',
                icon: Icons.water_drop_outlined,
                color: GavacColors.infoText,
                backgroundColor: GavacColors.infoBg,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: FeatureMetricCard(
                value: '${_records.length}',
                label: 'Registros de producción',
                icon: Icons.receipt_long_outlined,
                color: GavacColors.successText,
                backgroundColor: GavacColors.successBg,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: FeatureMetricCard(
                value: _averageWeight == null
                    ? '—'
                    : '${_formatNumber(_averageWeight!)} kg',
                label: 'Peso promedio registrado',
                icon: Icons.monitor_weight_outlined,
                color: GavacColors.warningText,
                backgroundColor: GavacColors.warningBg,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProductionRecord {
  const _ProductionRecord({
    required this.tag,
    required this.liters,
    required this.weight,
  });

  final String tag;
  final double? liters;
  final double? weight;
}

class _ProductionRecordTile extends StatelessWidget {
  const _ProductionRecordTile({
    required this.record,
    required this.onDelete,
  });

  final _ProductionRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (record.liters != null) '${_formatNumber(record.liters!)} L de leche',
      if (record.weight != null) '${_formatNumber(record.weight!)} kg',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: GavacColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: GavacColors.successBg,
          child: Icon(Icons.pets_outlined, color: GavacColors.primary),
        ),
        title: Text(
          record.tag,
          style: GoogleFonts.plusJakartaSans(
            color: GavacColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          details.isEmpty
              ? 'Sin datos de producción adicionales'
              : details.join(' · '),
          style: const TextStyle(color: GavacColors.textSecondary),
        ),
        trailing: IconButton(
          tooltip: 'Eliminar registro',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: GavacColors.textMuted),
        ),
      ),
    );
  }
}

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, size: 38, color: GavacColors.textMuted),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: GavacColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GavacColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionNotice extends StatelessWidget {
  const _SessionNotice();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: GavacColors.textMuted),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Los registros se conservan solo durante esta sesión.',
            style: TextStyle(color: GavacColors.textSecondary, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
