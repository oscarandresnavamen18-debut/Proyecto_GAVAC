import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/gavac_colors.dart';
import '../../../../core/utils/app_session.dart';
import '../../data/models/finca_model.dart';
import '../../data/services/admin_api_service.dart';

class GestionFincasAdminScreen extends StatefulWidget {
  const GestionFincasAdminScreen({super.key});

  @override
  State<GestionFincasAdminScreen> createState() =>
      _GestionFincasAdminScreenState();
}

class _GestionFincasAdminScreenState extends State<GestionFincasAdminScreen> {
  List<AdminFincaModel> _fincas = [];
  bool _cargando = true;
  String? _error;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarFincas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarFincas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final fincas = await AdminApiService.listarFincas();
      if (mounted) setState(() => _fincas = fincas);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _activarFinca(AdminFincaModel finca) async {
    try {
      await AdminApiService.activarFinca(finca.id);
      AppSession.farmId = finca.id;
      AppSession.farmName = finca.nombre;
      setState(() {});
      _mostrarMensaje('Ahora trabajas en ${finca.nombre}.');
    } catch (error) {
      _mostrarMensaje(error.toString());
    }
  }

  void _showFincaDialog({AdminFincaModel? fincaToEdit}) {
    final formKey = GlobalKey<FormState>();
    final nombreController =
        TextEditingController(text: fincaToEdit?.nombre ?? '');
    final ubicacionController =
        TextEditingController(text: fincaToEdit?.ubicacion ?? '');
    var guardando = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(fincaToEdit == null ? 'Nueva Finca' : 'Editar Finca'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la Finca',
                    hintText: 'Ej. Hato San José',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: ubicacionController,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación',
                    hintText: 'Ej. Vereda El Silencio, Meta',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'La ubicación es obligatoria'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: guardando ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GavacColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: guardando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => guardando = true);
                      try {
                        final nombre = nombreController.text.trim();
                        final ubicacion = ubicacionController.text.trim();
                        if (fincaToEdit == null) {
                          await AdminApiService.crearFinca(nombre, ubicacion);
                        } else {
                          await AdminApiService.editarFinca(
                            fincaToEdit.id,
                            nombre,
                            ubicacion,
                          );
                          if (fincaToEdit.id == AppSession.farmId) {
                            AppSession.farmName = nombre;
                          }
                        }
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        _mostrarMensaje(
                          fincaToEdit == null
                              ? 'Finca creada exitosamente'
                              : 'Finca actualizada',
                        );
                        await _cargarFincas();
                      } catch (error) {
                        setDialogState(() => guardando = false);
                        _mostrarMensaje(error.toString());
                      }
                    },
              child: Text(fincaToEdit == null ? 'Guardar' : 'Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido(List<AdminFincaModel> fincas) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _cargarFincas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (fincas.isEmpty) {
      return const Center(child: Text('Aún no hay fincas registradas.'));
    }
    return RefreshIndicator(
      onRefresh: _cargarFincas,
      child: ListView.builder(
        itemCount: fincas.length,
        itemBuilder: (context, index) {
          final finca = fincas[index];
          final esActiva = finca.id == AppSession.farmId;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor:
                    esActiva ? Colors.green[100] : Colors.grey[200],
                child: Icon(
                  Icons.agriculture,
                  color: esActiva ? GavacColors.primary : Colors.grey,
                ),
              ),
              title: Text(
                finca.nombre,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Ubicación: ${finca.ubicacion.isEmpty ? 'Sin ubicación' : finca.ubicacion}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (esActiva) ...[
                    const SizedBox(height: 4),
                    Chip(
                      label: const Text('Finca activa'),
                      backgroundColor: Colors.green[50],
                      labelStyle: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () => _showFincaDialog(fincaToEdit: finca),
                    tooltip: 'Editar Finca',
                  ),
                  IconButton(
                    icon: Icon(
                      esActiva
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: GavacColors.primary,
                    ),
                    onPressed: esActiva ? null : () => _activarFinca(finca),
                    tooltip: esActiva
                        ? 'Finca con la que trabajas'
                        : 'Trabajar en esta finca',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.toLowerCase();
    final filteredFincas = _fincas
        .where((f) =>
            f.nombre.toLowerCase().contains(query) ||
            f.ubicacion.toLowerCase().contains(query))
        .toList();

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
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Consultar fincas por nombre o ubicación...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showFincaDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva Finca'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GavacColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildContenido(filteredFincas)),
          ],
        ),
      ),
    );
  }
}
