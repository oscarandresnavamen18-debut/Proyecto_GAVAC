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
          scrollable: true,
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
                child: const Icon(Icons.water_drop_outlined,
                    color: Color(0xFF1A3A32), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Registrar Producción',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF1A3A32),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: selectedAnimalId,
                      dropdownColor: Colors.white,
                      style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF1E293B), fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Animal / Chapeta *',
                        prefixIcon: Icon(Icons.pets_outlined),
                        border: OutlineInputBorder(),
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
                      style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF1E293B), fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Leche producida (L)',
                        hintText: 'Ej. 15.5',
                        suffixText: 'L',
                        prefixIcon: Icon(Icons.water_drop_outlined),
                        border: OutlineInputBorder(),
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
                      style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF1E293B), fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Peso actual (kg)',
                        hintText: 'Ej. 450',
                        suffixText: 'kg',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                        border: OutlineInputBorder(),
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
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Cancelar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A3A32),
                side: const BorderSide(color: Color(0xFF1A3A32)),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A32),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(
                  dialogContext,
                  _ProductionDraft(
                    animalId: selectedAnimalId,
                    milkLiters: _parseOptionalNumber(_litersController.text),
                    weightKg: _parseOptionalNumber(_weightController.text),
                  ),
                );
              },
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Guardar Registro'),
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
    } on FormatException catch (error) {
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
    return Scaffold(
      backgroundColor: GavacColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 28),
                        _buildMetrics(),
                        const SizedBox(height: 28),
                        FeaturePanel(
                          title: 'Historial de Producción',
                          subtitle:
                              'Información sincronizada con los animales de tu finca.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A3A32),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  onPressed: _isLoading ||
                                          _isSaving ||
                                          _animals.isEmpty
                                      ? null
                                      : _showRegisterDialog,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: Text(
                                    'Registrar Producción',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (!_isLoading &&
                                  _animals.isEmpty &&
                                  _error == null)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    'Registra un animal primero para agregar datos de producción.',
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              if (_isLoading)
                                const Center(child: CircularProgressIndicator())
                              else if (_error != null)
                                _LoadError(
                                  message: _error!,
                                  onRetry: _loadData,
                                )
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: const AssetImage('assets/imagenes/imagenganado.png'),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {},
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFF1A3A32).withValues(alpha: 0.95),
              const Color(0xFF1A3A32).withValues(alpha: 0.65),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.water_drop_outlined,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Módulo de Producción',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Registra la producción diaria y consulta el rendimiento del ganado.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetrics() {
    final cards = [
      _buildKpiCard(
        title: 'Leche Hoy',
        value: _isLoading ? '0 L' : '${_formatNumber(_totalMilk) ?? '0'} L',
        subtitle: 'Leche Hoy',
        icon: Icons.water_drop_outlined,
        iconBgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _buildKpiCard(
        title: 'Promedio Vaca',
        value: _isLoading ? '0 L' : '${_formatNumber(_totalMilk) ?? '0'} L',
        subtitle: 'Promedio Vaca',
        icon: Icons.bar_chart_outlined,
        iconBgColor: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
      ),
      _buildKpiCard(
        title: 'Peso Promedio',
        value: _isLoading
            ? '0 kg'
            : _averageWeight == null
                ? '0 kg'
                : '${_formatNumber(_averageWeight)} kg',
        subtitle: 'Peso Promedio',
        icon: Icons.monitor_weight_outlined,
        iconBgColor: const Color(0xFFFFFBEB),
        iconColor: const Color(0xFFD97706),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) => FeatureMetricLayout(
        cards: cards,
        isCompact: constraints.maxWidth < 800,
        horizontalSpacing: 14,
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
      cardColor: Colors.white,
      borderColor: const Color(0xFFF1F5F9),
      textColor: const Color(0xFF64748B),
      valueColor: const Color(0xFF1A3A32),
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

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 38,
            color: GavacColors.textMuted,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Intentar de nuevo'),
          ),
        ],
      ),
    );
  }
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
          Text(
            'No hay registros de producción',
            style: GoogleFonts.plusJakartaSans(
              color: GavacColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
