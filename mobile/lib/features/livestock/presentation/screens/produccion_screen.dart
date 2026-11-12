import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/gavac_colors.dart';
import '../../../../core/widgets/feature_page_widgets.dart';
import '../../data/services/production_api_service.dart';

class ProduccionScreen extends StatefulWidget {
  const ProduccionScreen({
    super.key,
    this.repository = const ProductionApiService(),
  });

  final ProductionRepository repository;

  @override
  State<ProduccionScreen> createState() => _ProduccionScreenState();
}

class _ProduccionScreenState extends State<ProduccionScreen> {
  final _litersController = TextEditingController();
  final _weightController = TextEditingController();
  List<AnimalOption> _animals = [];
  List<ProductionRecord> _records = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _litersController.dispose();
    _weightController.dispose();
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
        _animals = results[0] as List<AnimalOption>;
        _records = results[1] as List<ProductionRecord>;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      _setLoadError(error.message);
    } on FormatException catch (error) {
      _setLoadError(error.message);
    } on Exception catch (error) {
      _setLoadError('No se pudo cargar la producción: $error');
    }
  }

  void _setLoadError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _isLoading = false;
    });
  }

  Future<void> _showRegisterDialog() async {
    if (_animals.isEmpty) return;
    final formKey = GlobalKey<FormState>();
    int selectedAnimalId = _animals.first.id;
    _litersController.clear();
    _weightController.clear();

    final draft = await showDialog<_ProductionDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                  DropdownButtonFormField<int>(
                    initialValue: selectedAnimalId,
                    decoration: const InputDecoration(
                      labelText: 'Animal',
                      prefixIcon: Icon(Icons.pets_outlined),
                    ),
                    items: _animals
                        .map(
                          (animal) => DropdownMenuItem(
                            value: animal.id,
                            child: Text(animal.tag),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedAnimalId = value);
                      }
                    },
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
                    validator: (value) => _validateMeasurement(
                      value,
                      _weightController.text,
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
                    validator: (value) => _validateMeasurement(
                      value,
                      _litersController.text,
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
              onPressed: _isSaving
                  ? null
                  : () {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(
                        dialogContext,
                        _ProductionDraft(
                          animalId: selectedAnimalId,
                          milkLiters: _parseOptionalNumber(
                            _litersController.text,
                          ),
                          weightKg: _parseOptionalNumber(
                            _weightController.text,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.check),
              label: const Text('Guardar registro'),
            ),
          ],
        ),
      ),
    );

    if (draft == null || !mounted) return;
    setState(() => _isSaving = true);
    try {
      final records = await widget.repository.createRecords(
        animalId: draft.animalId,
        milkLiters: draft.milkLiters,
        weightKg: draft.weightKg,
      );
      if (!mounted) return;
      setState(() {
        _records.insertAll(0, records);
        _isSaving = false;
      });
      _showMessage('Registro guardado correctamente.');
    } on ApiException catch (error) {
      _finishSaveWithError(error.message);
    } on FormatException catch (error) {
      _finishSaveWithError(error.message);
    } on Exception catch (error) {
      _finishSaveWithError('No se pudo guardar el registro: $error');
    }
  }

  String? _validateMeasurement(
    String? value,
    String otherValue,
    String invalidMessage,
  ) {
    if ((value == null || value.trim().isEmpty) && otherValue.trim().isEmpty) {
      return 'Registra litros de leche o peso.';
    }
    if (value == null || value.trim().isEmpty) return null;
    final number = _parseOptionalNumber(value);
    if (number == null || number <= 0) return invalidMessage;
    return null;
  }

  double? _parseOptionalNumber(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  Future<void> _deleteRecord(ProductionRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text(
          '¿Quieres eliminar el registro de ${record.animalTag}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await widget.repository.deleteRecord(record.id);
      if (!mounted) return;
      setState(() => _records.removeWhere((item) => item.id == record.id));
      _showMessage('Registro eliminado.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    } on Exception catch (error) {
      _showMessage('No se pudo eliminar el registro: $error');
    }
  }

  double get _totalMilk => _records
      .where((record) => record.isMilk)
      .fold(0, (total, record) => total + record.quantity);

  double? get _averageWeight {
    final weights = _records.where((record) => !record.isMilk).toList();
    if (weights.isEmpty) return null;
    return weights.fold(0.0, (total, record) => total + record.quantity) /
        weights.length;
  }

  String? _formatNumber(double? value) {
    if (value == null) return null;
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  void _finishSaveWithError(String message) {
    if (!mounted) return;
    setState(() => _isSaving = false);
    _showMessage(message);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                        'Información sincronizada con los animales de tu finca.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed:
                                _isSaving || _animals.isEmpty || _isLoading
                                    ? null
                                    : _showRegisterDialog,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            label: Text(
                              _isSaving ? 'Guardando...' : 'Nuevo registro',
                            ),
                          ),
                        ),
                        if (!_isLoading && _animals.isEmpty && _error == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              'Registra un animal primero para agregar datos de producción.',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: GavacColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_error != null)
                          _LoadError(message: _error!, onRetry: _loadData)
                        else if (_records.isEmpty)
                          const _EmptyState()
                        else
                          ..._records.map(
                            (record) => _ProductionRecordTile(
                              record: record,
                              onDelete: () => _deleteRecord(record),
                              formattedQuantity:
                                  _formatNumber(record.quantity) ?? '0',
                            ),
                          ),
                      ],
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
                value: _isLoading ? '—' : '${_formatNumber(_totalMilk)} L',
                label: 'Leche registrada',
                icon: Icons.water_drop_outlined,
                color: GavacColors.infoText,
                backgroundColor: GavacColors.infoBg,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: FeatureMetricCard(
                value: _isLoading ? '—' : '${_records.length}',
                label: 'Mediciones registradas',
                icon: Icons.receipt_long_outlined,
                color: GavacColors.successText,
                backgroundColor: GavacColors.successBg,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: FeatureMetricCard(
                value: _isLoading
                    ? '—'
                    : _averageWeight == null
                        ? '—'
                        : '${_formatNumber(_averageWeight)} kg',
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

class _ProductionDraft {
  const _ProductionDraft({
    required this.animalId,
    required this.milkLiters,
    required this.weightKg,
  });

  final int animalId;
  final double? milkLiters;
  final double? weightKg;
}

class _ProductionRecordTile extends StatelessWidget {
  const _ProductionRecordTile({
    required this.record,
    required this.onDelete,
    required this.formattedQuantity,
  });

  final ProductionRecord record;
  final VoidCallback onDelete;
  final String formattedQuantity;

  @override
  Widget build(BuildContext context) {
    final isMilk = record.isMilk;
    final date = record.recordedAt.toLocal();
    final dateText = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: GavacColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isMilk ? GavacColors.infoBg : GavacColors.warningBg,
          child: Icon(
            isMilk ? Icons.water_drop_outlined : Icons.monitor_weight_outlined,
            color: isMilk ? GavacColors.infoText : GavacColors.warningText,
          ),
        ),
        title: Text(
          record.animalTag,
          style: GoogleFonts.plusJakartaSans(
            color: GavacColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${isMilk ? 'Leche' : 'Peso'} · $dateText',
          style: const TextStyle(color: GavacColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$formattedQuantity ${record.unit}',
              style: GoogleFonts.plusJakartaSans(
                color: GavacColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              tooltip: 'Eliminar registro',
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline,
                color: GavacColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: [
          const Icon(
            Icons.query_stats,
            size: 38,
            color: GavacColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'Aún no hay registros',
            style: GoogleFonts.plusJakartaSans(
              color: GavacColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Agrega el primer registro para consultar la producción de tu ganado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GavacColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: GavacColors.dangerText),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
