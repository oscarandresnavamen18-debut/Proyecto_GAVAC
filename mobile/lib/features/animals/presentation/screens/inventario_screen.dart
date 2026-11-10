import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/gavac_colors.dart';
import '../../../../core/widgets/feature_page_widgets.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final List<_InventoryItem> _items = [];
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _showRegisterDialog() async {
    final formKey = GlobalKey<FormState>();
    _nameController.clear();
    _quantityController.clear();

    final item = await showDialog<_InventoryItem>(
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
                    labelText: 'Cantidad',
                    hintText: 'Ej. 50',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa la cantidad.';
                    }
                    final quantity = _parseQuantity(value);
                    if (quantity == null || quantity <= 0) {
                      return 'La cantidad debe ser un número mayor que cero.';
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
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                dialogContext,
                _InventoryItem(
                  name: _nameController.text.trim(),
                  quantity: _formatQuantity(
                    _parseQuantity(_quantityController.text)!,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Guardar insumo'),
          ),
        ],
      ),
    );

    if (item == null || !mounted) return;
    setState(() => _items.insert(0, item));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Insumo guardado en esta sesión.')),
    );
  }

  double? _parseQuantity(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  String _formatQuantity(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

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
                        'Consulta y administra los elementos de tu inventario.',
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _showRegisterDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Nuevo insumo'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_items.isEmpty)
                          const _InventoryEmptyState()
                        else
                          ..._items.map(
                            (item) => _InventoryItemTile(
                              item: item,
                              onDelete: () =>
                                  setState(() => _items.remove(item)),
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
        final cardWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: FeatureMetricCard(
                value: '${_items.length}',
                label: 'Insumos registrados',
                icon: Icons.inventory_2_outlined,
                color: GavacColors.infoText,
                backgroundColor: GavacColors.infoBg,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: FeatureMetricCard(
                value: _items.isEmpty ? '—' : 'Hoy',
                label: 'Último movimiento',
                icon: Icons.schedule_outlined,
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

class _InventoryItem {
  const _InventoryItem({required this.name, required this.quantity});

  final String name;
  final String quantity;
}

class _InventoryItemTile extends StatelessWidget {
  const _InventoryItemTile({required this.item, required this.onDelete});

  final _InventoryItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: GavacColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: GavacColors.infoBg,
          child: Icon(
            Icons.inventory_2_outlined,
            color: GavacColors.infoText,
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
          'Cantidad: ${item.quantity}',
          style: const TextStyle(color: GavacColors.textSecondary),
        ),
        trailing: IconButton(
          tooltip: 'Eliminar insumo',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: GavacColors.textMuted),
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
            'Los insumos se conservan solo durante esta sesión.',
            style: TextStyle(color: GavacColors.textSecondary, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
