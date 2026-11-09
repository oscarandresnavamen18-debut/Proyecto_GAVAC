import 'package:flutter/material.dart';
import '../../../../core/theme/gavac_colors.dart';
import '../../data/models/finca_model.dart';

class GestionFincasAdminScreen extends StatefulWidget {
  const GestionFincasAdminScreen({super.key});

  @override
  State<GestionFincasAdminScreen> createState() => _GestionFincasAdminScreenState();
}

class _GestionFincasAdminScreenState extends State<GestionFincasAdminScreen> {
  // Lista inicial vacía (sin datos de prueba)
  final List<AdminFincaModel> _fincas = [];

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFincaDialog({AdminFincaModel? fincaToEdit, int? index}) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: fincaToEdit?.nombre ?? '');
    final ubicacionController = TextEditingController(text: fincaToEdit?.ubicacion ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(fincaToEdit == null ? 'Nueva Finca' : 'Editar Finca'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre de la Finca', hintText: 'Ej. Hato San José'),
                validator: (v) => v == null || v.isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: ubicacionController,
                decoration: const InputDecoration(labelText: 'Ubicación', hintText: 'Ej. Vereda El Silencio, Meta'),
                validator: (v) => v == null || v.isEmpty ? 'La ubicación es obligatoria' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GavacColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  if (fincaToEdit == null) {
                    _fincas.add(
                      AdminFincaModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        nombre: nombreController.text.trim(),
                        ubicacion: ubicacionController.text.trim(),
                        activa: true,
                      ),
                    );
                  } else {
                    _fincas[index!] = AdminFincaModel(
                      id: fincaToEdit.id,
                      nombre: nombreController.text.trim(),
                      ubicacion: ubicacionController.text.trim(),
                      activa: fincaToEdit.activa,
                    );
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(fincaToEdit == null ? 'Finca creada exitosamente' : 'Finca actualizada')),
                );
              }
            },
            child: Text(fincaToEdit == null ? 'Guardar' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredFincas = _fincas.where((f) =>
        f.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        f.ubicacion.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Fincas'),
        backgroundColor: GavacColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Consultar fincas por nombre o ubicación...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showFincaDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva Finca'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GavacColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: filteredFincas.length,
                itemBuilder: (context, index) {
                  final finca = filteredFincas[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: finca.activa ? Colors.green[100] : Colors.grey[200],
                        child: Icon(Icons.agriculture, color: finca.activa ? GavacColors.primary : Colors.grey),
                      ),
                      title: Text(finca.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Ubicación: ${finca.ubicacion}', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(finca.activa ? 'Activa' : 'Desactivada'),
                            backgroundColor: finca.activa ? Colors.green[50] : Colors.red[50],
                            labelStyle: TextStyle(
                              color: finca.activa ? Colors.green[700] : Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            onPressed: () => _showFincaDialog(fincaToEdit: finca, index: index),
                            tooltip: 'Editar Finca',
                          ),
                          Switch(
                            value: finca.activa,
                            activeThumbColor: GavacColors.primary,
                            onChanged: (val) {
                              setState(() {
                                finca.activa = val;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(val ? 'Finca activada' : 'Finca desactivada')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
