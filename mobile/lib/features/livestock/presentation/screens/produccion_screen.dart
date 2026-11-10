import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestion_ganadera/core/theme/gavac_colors.dart';

class ProduccionScreen extends StatefulWidget {
  const ProduccionScreen({super.key});

  @override
  State<ProduccionScreen> createState() => _ProduccionScreenState();
}

class _ProduccionScreenState extends State<ProduccionScreen> {
  // Cero datos de prueba estáticos (lista vacía)
  final List<Map<String, dynamic>> _produccionList = [];

  void _showRegistrarProduccionModal() {
    final areteController = TextEditingController();
    final litrosController = TextEditingController();
    final pesoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Registrar Producción',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, color: GavacColors.primary)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: areteController,
                  decoration: const InputDecoration(
                      labelText: 'Arete / Chapeta *', hintText: 'Ej. CH-1024')),
              const SizedBox(height: 12),
              TextField(
                  controller: litrosController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Litros de Leche (Ordeño)', hintText: '15.5')),
              const SizedBox(height: 12),
              TextField(
                  controller: pesoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Peso Actual (kg)', hintText: '450')),
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
              if (areteController.text.trim().isNotEmpty) {
                setState(() {
                  _produccionList.add({
                    'arete': areteController.text.trim(),
                    'leche':
                        '${litrosController.text.trim().isNotEmpty ? litrosController.text.trim() : '0'} L',
                    'peso':
                        '${pesoController.text.trim().isNotEmpty ? pesoController.text.trim() : '0'} kg',
                    'fecha': 'Hoy',
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Registro de producción guardado con éxito'),
                      backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Guardar Registro'),
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
                        child: const Icon(Icons.water_drop_outlined,
                            color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Módulo de Producción',
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.sizeOf(context).width < 600
                                            ? 18
                                            : 24,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(
                                'Control de rendimiento, litros de leche y ganancia de peso.',
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
                            '0 L',
                            'Leche Hoy',
                            Icons.water_drop,
                            const Color(0xFFEFF6FF),
                            const Color(0xFF2563EB)),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildKpiCard(
                            '0 L',
                            'Promedio Vaca',
                            Icons.analytics,
                            const Color(0xFFECFDF5),
                            const Color(0xFF059669)),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildKpiCard(
                            '0 kg',
                            'Peso Promedio',
                            Icons.monitor_weight,
                            const Color(0xFFFEF3C7),
                            const Color(0xFFD97706)),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Tabla de Producción
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
                        final title = Text('Historial de Producción',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: GavacColors.primary));
                        final addButton = ElevatedButton.icon(
                          onPressed: _showRegistrarProduccionModal,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: GavacColors.primary,
                              foregroundColor: Colors.white),
                          icon: const Icon(Icons.add),
                          label: const Text('Registrar Producción'),
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
                          children: [
                            title,
                            addButton,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _produccionList.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text('No hay registros de producción',
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
                                DataColumn(label: Text('ARETE')),
                                DataColumn(label: Text('LECHE (ORDEÑO)')),
                                DataColumn(label: Text('PESO')),
                                DataColumn(label: Text('FECHA')),
                                DataColumn(label: Text('ACCIÓN')),
                              ],
                              rows: _produccionList.map((p) {
                                return DataRow(cells: [
                                  DataCell(Text(p['arete'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold))),
                                  DataCell(Text(p['leche'])),
                                  DataCell(Text(p['peso'])),
                                  DataCell(Text(p['fecha'])),
                                  DataCell(IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      onPressed: () => setState(
                                          () => _produccionList.remove(p)))),
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
              Flexible(
                child: Text(value,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: GavacColors.primary)),
              ),
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
