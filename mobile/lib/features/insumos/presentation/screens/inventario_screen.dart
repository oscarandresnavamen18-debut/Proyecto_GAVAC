import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/gavac_colors.dart';
import '../../../../core/widgets/feature_page_widgets.dart';
import '../../data/services/inventory_api_service.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({
    super.key,
    this.repository = const InventoryApiService(),
  });

  final InventoryRepository repository;

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  static const Color primaryColor = Color(0xFF1A3A32);
  static const Color backgroundColor = Color(0xFFF7F9F7);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF64748B);

  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  List<InventoryItem> _items = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await widget.repository.listItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      _setLoadError(error.message);
    } on FormatException catch (error) {
      _setLoadError(error.message);
    } on Exception catch (error) {
      _setLoadError('No se pudo cargar el inventario: $error');
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
    final formKey = GlobalKey<FormState>();
    _nameController.clear();
    _quantityController.clear();

    final draft = await showDialog<_InventoryDraft>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Registrar Insumo',
          style: GoogleFonts.plusJakartaSans(
            color: primaryColor,
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
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del insumo',
                    hintText: 'Ej. Alimento para ganado',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa el nombre del insumo.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Cantidad inicial',
                    hintText: 'Ej. 50',
                    suffixText: 'unidades',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa la cantidad.';
                    }
                    final quantity = _parseQuantity(value);
                    if (quantity == null || quantity <= 0) {
                      return 'La cantidad debe ser mayor que cero.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: OutlinedButton.styleFrom(foregroundColor: primaryColor),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: _isSaving
                ? null
                : () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(
                      dialogContext,
                      _InventoryDraft(
                        name: _nameController.text.trim(),
                        quantity: _parseQuantity(_quantityController.text)!,
                      ),
                    );
                  },
            icon: const Icon(Icons.check),
            label: const Text('Guardar insumo'),
          ),
        ],
      ),
    );

    if (draft == null || !mounted) return;
    setState(() => _isSaving = true);
    try {
      final item = await widget.repository.createItem(
        draft.name,
        draft.quantity,
      );
      if (!mounted) return;
      setState(() {
        _items.insert(0, item);
        _isSaving = false;
      });
      _showMessage('Insumo guardado correctamente.');
    } on ApiException catch (error) {
      _finishSaveWithError(error.message);
    } on FormatException catch (error) {
      _finishSaveWithError(error.message);
    } on Exception catch (error) {
      _finishSaveWithError('No se pudo guardar el insumo: $error');
    }
  }

  Future<void> _deactivateItem(InventoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Retirar insumo'),
        content: Text('¿Quieres retirar "${item.name}" del inventario activo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await widget.repository.deactivateItem(item.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((current) => current.id == item.id));
      _showMessage('Insumo retirado del inventario activo.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    } on Exception catch (error) {
      _showMessage('No se pudo retirar el insumo: $error');
    }
  }

  double? _parseQuantity(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  void _finishSaveWithError(String message) {
    if (!mounted) return;
    setState(() => _isSaving = false);
    _showMessage(message);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
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
                    title: 'Listado de Inventario',
                    subtitle:
                        'El inventario se actualiza y sincroniza con la finca.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isSaving ? null : _showRegisterDialog,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.add, size: 18),
                            label: Text(
                              _isSaving ? 'Guardando...' : 'Registrar Insumo',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_error != null)
                          _LoadError(message: _error!, onRetry: _loadItems)
                        else if (_items.isEmpty)
                          const _InventoryEmptyState()
                        else
                          ..._items.map(
                            (item) => _InventoryItemTile(
                              item: item,
                              onDelete: () => _deactivateItem(item),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
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
              primaryColor.withValues(alpha: 0.95),
              primaryColor.withValues(alpha: 0.65),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Módulo de Inventario',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Organiza y lleva el control de los insumos y recursos de tu finca.',
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
    final lowStockCount = _items.where((item) => item.isLowStock).length;
    final optimalStockCount = _items.where((item) => !item.isLowStock).length;

    final cards = [
      _buildKpiCard(
        title: 'Total Insumos',
        value: _isLoading ? '0' : '${_items.length}',
        subtitle: 'Total Insumos',
        icon: Icons.inventory_2_outlined,
        iconBgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _buildKpiCard(
        title: 'Stock Óptimo',
        value: _isLoading ? '0' : '$optimalStockCount',
        subtitle: 'Stock Óptimo',
        icon: Icons.check_circle_outline_rounded,
        iconBgColor: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
      ),
      _buildKpiCard(
        title: 'Stock Bajo',
        value: _isLoading ? '0' : '$lowStockCount',
        subtitle: 'Stock Bajo',
        icon: Icons.warning_amber_rounded,
        iconBgColor: const Color(0xFFFEF2F2),
        iconColor: const Color(0xFFDC2626),
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
      cardColor: cardColor,
      borderColor: borderColor,
      textColor: textMuted,
      valueColor: primaryColor,
    );
  }
}

class _InventoryDraft {
  const _InventoryDraft({required this.name, required this.quantity});

  final String name;
  final double quantity;
}

class _InventoryItemTile extends StatelessWidget {
  const _InventoryItemTile({required this.item, required this.onDelete});

  final InventoryItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isLowStock = item.isLowStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: GavacColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLowStock
              ? GavacColors.warningBg
              : GavacColors.infoBg,
          child: Icon(
            Icons.inventory_2_outlined,
            color: isLowStock ? GavacColors.warningText : GavacColors.infoText,
          ),
        ),
        title: Text(
          item.name,
          style: GoogleFonts.plusJakartaSans(
            color: GavacColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${_formatQuantity(item.quantity)} ${item.unit} · ${item.category}',
          style: const TextStyle(color: GavacColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StockBadge(isLowStock: isLowStock),
            IconButton(
              tooltip: 'Retirar insumo',
              onPressed: onDelete,
              icon: const Icon(
                Icons.archive_outlined,
                color: GavacColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.isLowStock});

  final bool isLowStock;

  @override
  Widget build(BuildContext context) {
    final color = isLowStock
        ? GavacColors.warningText
        : GavacColors.successText;
    final background = isLowStock
        ? GavacColors.warningBg
        : GavacColors.successBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isLowStock ? 'Stock bajo' : 'Disponible',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InventoryEmptyState extends StatelessWidget {
  const _InventoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 38,
            color: GavacColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'Inventario vacío',
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

String _formatQuantity(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
