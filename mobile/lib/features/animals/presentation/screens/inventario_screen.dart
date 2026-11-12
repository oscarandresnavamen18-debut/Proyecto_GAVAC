import 'package:flutter/material.dart';
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
        title: Text(
          'Registrar insumo',
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
                    icon: Icons.inventory_2_outlined,
                    title: 'Inventario',
                    subtitle:
                        'Organiza y lleva el control de los insumos y recursos de tu finca.',
                  ),
                  const SizedBox(height: 24),
                  _buildMetrics(),
                  const SizedBox(height: 24),
                  FeaturePanel(
                    title: 'Insumos registrados',
                    subtitle:
                        'El inventario se actualiza y sincroniza con la finca.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _showRegisterDialog,
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
                              _isSaving ? 'Guardando...' : 'Nuevo insumo',
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

  Widget _buildMetrics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;
        final lowStockCount = _items.where((item) => item.isLowStock).length;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: FeatureMetricCard(
                value: _isLoading ? '—' : '${_items.length}',
                label: 'Insumos activos',
                icon: Icons.inventory_2_outlined,
                color: GavacColors.infoText,
                backgroundColor: GavacColors.infoBg,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: FeatureMetricCard(
                value: _isLoading ? '—' : '$lowStockCount',
                label: 'En nivel mínimo',
                icon: Icons.warning_amber_outlined,
                color: lowStockCount > 0
                    ? GavacColors.warningText
                    : GavacColors.successText,
                backgroundColor: lowStockCount > 0
                    ? GavacColors.warningBg
                    : GavacColors.successBg,
              ),
            ),
          ],
        );
      },
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
          backgroundColor:
              isLowStock ? GavacColors.warningBg : GavacColors.infoBg,
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
    final color =
        isLowStock ? GavacColors.warningText : GavacColors.successText;
    final background =
        isLowStock ? GavacColors.warningBg : GavacColors.successBg;
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
            'Tu inventario está vacío',
            style: GoogleFonts.plusJakartaSans(
              color: GavacColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Registra el primer insumo para comenzar a organizar tus recursos.',
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

String _formatQuantity(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
