import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/dueno_models.dart';
import '../../data/services/dueno_api_service.dart';

class GestionFincasDuenoTab extends StatefulWidget {
  final DuenoRepository repository;
  final VoidCallback onRefresh;
  final ValueChanged<Widget>? onOpenModal;
  final VoidCallback? onCloseModal;

  const GestionFincasDuenoTab({
    super.key,
    required this.repository,
    required this.onRefresh,
    this.onOpenModal,
    this.onCloseModal,
  });

  @override
  State<GestionFincasDuenoTab> createState() => _GestionFincasDuenoTabState();
}

class _GestionFincasDuenoTabState extends State<GestionFincasDuenoTab> {
  static const Color primaryColor = Color(0xFF1A3A32);
  static const Color textMuted = Color(0xFF64748B);

  List<FincaDuenoModel> _fincas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFincas();
  }

  Future<void> _loadFincas() async {
    setState(() => _isLoading = true);
    final list = await widget.repository.listFincas();
    if (!mounted) return;
    setState(() {
      _fincas = list;
      _isLoading = false;
    });
  }

  void _showCreateFincaModal() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final locCtrl = TextEditingController();

    final modalWidget = StatefulBuilder(
      builder: (context, setModalState) => Container(
        width: 480,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.agriculture_outlined,
                      color: primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Registrar Nueva Finca',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => widget.onCloseModal?.call(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Finca *',
                      hintText: 'Ej. Hacienda El Paraíso',
                      prefixIcon: Icon(Icons.agriculture_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: locCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación / Municipio *',
                      hintText: 'Ej. Montería, Córdoba',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => widget.onCloseModal?.call(),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Cancelar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: const BorderSide(color: primaryColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          widget.onCloseModal?.call();
                          final newFinca = await widget.repository.createFinca(
                            name: nameCtrl.text.trim(),
                            location: locCtrl.text.trim(),
                          );
                          if (!mounted) return;
                          setState(() => _fincas.insert(0, newFinca));
                          widget.onRefresh();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Finca registrada correctamente.')),
                          );
                        },
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: const Text('Guardar Finca'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    widget.onOpenModal?.call(modalWidget);
  }

  void _showEditFincaModal(FincaDuenoModel finca, int index) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: finca.name);
    final locCtrl = TextEditingController(text: finca.location);

    final modalWidget = StatefulBuilder(
      builder: (context, setModalState) => Container(
        width: 480,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Editar Finca',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => widget.onCloseModal?.call(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Finca *',
                      prefixIcon: Icon(Icons.agriculture_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: locCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación / Municipio *',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => widget.onCloseModal?.call(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          widget.onCloseModal?.call();
                          final updated = await widget.repository.updateFinca(
                            id: finca.id,
                            name: nameCtrl.text.trim(),
                            location: locCtrl.text.trim(),
                          );
                          if (!mounted) return;
                          setState(() => _fincas[index] = updated.copyWith(
                                name: nameCtrl.text.trim(),
                                location: locCtrl.text.trim(),
                              ));
                          widget.onRefresh();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Finca actualizada.')),
                          );
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Actualizar Finca'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    widget.onOpenModal?.call(modalWidget);
  }

  void _toggleFincaStatus(FincaDuenoModel finca, int index) async {
    final updated = await widget.repository.updateFinca(
      id: finca.id,
      isActive: !finca.isActive,
    );
    if (!mounted) return;
    setState(() => _fincas[index] = updated.copyWith(isActive: !finca.isActive));
    widget.onRefresh();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !finca.isActive ? 'Finca activada.' : 'Finca desactivada.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestión de Fincas',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateFincaModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva Finca'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_fincas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No hay fincas registradas en tu cuenta.',
                  style: GoogleFonts.plusJakartaSans(
                    color: textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('NOMBRE FINCA')),
                  DataColumn(label: Text('UBICACIÓN')),
                  DataColumn(label: Text('ESTADO')),
                  DataColumn(label: Text('ACCIONES')),
                ],
                rows: _fincas.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final finca = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text(finca.name,
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700))),
                      DataCell(Text(finca.location)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: finca.isActive
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            finca.isActive ? 'Activa' : 'Inactiva',
                            style: TextStyle(
                              color: finca.isActive
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Color(0xFF2563EB)),
                              tooltip: 'Editar Finca',
                              onPressed: () => _showEditFincaModal(finca, idx),
                            ),
                            IconButton(
                              icon: Icon(
                                finca.isActive
                                    ? Icons.block
                                    : Icons.check_circle_outline,
                                color: finca.isActive ? Colors.orange : Colors.green,
                              ),
                              tooltip: finca.isActive ? 'Desactivar' : 'Activar',
                              onPressed: () => _toggleFincaStatus(finca, idx),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
