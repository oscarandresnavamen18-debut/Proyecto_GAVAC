import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestion_ganadera/core/theme/gavac_colors.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  // Cero datos de prueba estáticos (lista vacía)
  final List<Map<String, dynamic>> _inventario = [];

  void _showRegistrarInsumoModal() {
    final nombreController = TextEditingController();
    final cantidadController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Registrar Insumo / Recurso',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, color: GavacColors.primary)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                      labelText: 'Nombre del Insumo *',
                      hintText: 'Ej. Vacuna Aftosa / Alimento')),
              const SizedBox(height: 12),
              TextField(
                  controller: cantidadController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Cantidad *', hintText: '50 unidades')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GavacColors.primary,
                foregroundColor: Colors.white),
            onPressed: () {
              if (nombreController.text.trim().isNotEmpty) {
                setState(() {
                  _inventario.add({
                    'nombre': nombreController.text.trim(),
                    'cantidad': cantidadController.text.trim().isNotEmpty
                        ? cantidadController.text.trim()
                        : '1',
                    'estado': 'Disponible',
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Insumo registrado con éxito'),
                      backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Guardar Insumo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GavacColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Superior
              Container(
                width: double.infinity,
                height: MediaQuery.sizeOf(context).width < 600 ? 180 : 160,
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
                        GavacColors.primary.withValues(alpha: 0.95),
                        GavacColors.primary.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        MediaQuery.sizeOf(context).width < 600 ? 16 : 32,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.inventory_2_outlined,
                            color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Módulo de Inventario',
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.sizeOf(context).width < 600
                                            ? 20
                                            : 24,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(
                                'Control de insumos, alimentos y recursos de la finca.',
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // KPIs en ceros
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth < 600
                      ? (constraints.maxWidth - 16) / 2
                      : (constraints.maxWidth - 32) / 3;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildKpiCard(
                            '0',
                            'Total Insumos',
                            Icons.inventory,
                            const Color(0xFFEFF6FF),
                            const Color(0xFF2563EB)),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildKpiCard(
                            '0',
                            'Stock Óptimo',
                            Icons.check_circle,
                            const Color(0xFFECFDF5),
                            const Color(0xFF059669)),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildKpiCard('0', 'Stock Bajo', Icons.warning,
                            const Color(0xFFFEF2F2), const Color(0xFFDC2626)),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Tabla de Inventario
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final title = Text('Listado de Inventario',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: GavacColors.primary));
                        final addButton = ElevatedButton.icon(
                          onPressed: _showRegistrarInsumoModal,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: GavacColors.primary,
                              foregroundColor: Colors.white),
                          icon: const Icon(Icons.add),
                          label: const Text('Registrar Insumo'),
                        );
                        if (constraints.maxWidth < 600) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              title,
                              const SizedBox(height: 12),
                              addButton
                            ],
                          );
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [title, addButton],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _inventario.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text('Inventario vacío',
                                  style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('NOMBRE')),
                                DataColumn(label: Text('CANTIDAD')),
                                DataColumn(label: Text('ESTADO')),
                                DataColumn(label: Text('ACCIONES')),
                              ],
                              rows: _inventario.map((item) {
                                return DataRow(cells: [
                                  DataCell(Text(item['nombre'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold))),
                                  DataCell(Text(item['cantidad'])),
                                  DataCell(Chip(
                                      label: Text(item['estado']),
                                      backgroundColor: Colors.blue[50],
                                      labelStyle: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold))),
                                  DataCell(IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      onPressed: () => setState(
                                          () => _inventario.remove(item)))),
                                ]);
                              }).toList(),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(
      String value, String label, IconData icon, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: GavacColors.primary)),
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: fg, size: 20)),
            ],
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: GavacColors.textSecondary)),
        ],
      ),
    );
  }
}
