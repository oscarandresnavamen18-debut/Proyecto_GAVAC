import 'package:flutter/material.dart';
import '../../../../core/theme/gavac_colors.dart';
import '../../data/models/usuario_model.dart';
import '../../data/models/finca_model.dart';

class GestionUsuariosAdminScreen extends StatefulWidget {
  final List<AdminFincaModel> fincasDisponibles;

  const GestionUsuariosAdminScreen({
    super.key,
    this.fincasDisponibles = const [],
  });

  @override
  State<GestionUsuariosAdminScreen> createState() => _GestionUsuariosAdminScreenState();
}

class _GestionUsuariosAdminScreenState extends State<GestionUsuariosAdminScreen> {
  // Lista inicial vacía (sin datos de prueba)
  final List<AdminUsuarioModel> _usuarios = [];

  final List<String> _rolesDisponibles = ['Administrador', 'Veterinario', 'Trabajador de campo'];

  void _showUsuarioDialog({AdminUsuarioModel? usuarioToEdit, int? index}) {
    // PRECONDICIÓN HU-003: Debe existir al menos una finca
    final fincasMock = widget.fincasDisponibles.isNotEmpty
        ? widget.fincasDisponibles
        : [
            AdminFincaModel(id: '1', nombre: 'Hacienda El Paraíso', ubicacion: 'Cundinamarca'),
            AdminFincaModel(id: '2', nombre: 'Finca La Esperanza', ubicacion: 'Antioquia'),
          ];

    if (fincasMock.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Aviso'),
          content: const Text('No se puede registrar un usuario porque debe existir al menos una finca registrada previamente.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: GavacColors.primary, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: usuarioToEdit?.nombre ?? '');
    final correoController = TextEditingController(text: usuarioToEdit?.correo ?? '');

    String? selectedFincaId = usuarioToEdit?.fincaId ?? fincasMock.first.id;
    String? selectedRol = usuarioToEdit?.rol ?? _rolesDisponibles.first;
    bool estadoActivo = usuarioToEdit?.activo ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(usuarioToEdit == null ? 'Registrar Usuario' : 'Editar Usuario y Rol'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre completo', hintText: 'Ej. Juan Pérez'),
                    validator: (v) => v == null || v.isEmpty ? 'El nombre es obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: correoController,
                    decoration: const InputDecoration(labelText: 'Correo electrónico', hintText: 'juan@finca.com'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'El correo es obligatorio';
                      if (!v.contains('@')) return 'Ingrese un correo válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Dropdown Finca Asignada (HU-003)
                  DropdownButtonFormField<String>(
                    initialValue: selectedFincaId,
                    decoration: const InputDecoration(labelText: 'Finca Asignada'),
                    items: fincasMock.map((f) => DropdownMenuItem(value: f.id, child: Text(f.nombre))).toList(),
                    onChanged: (val) => setDialogState(() => selectedFincaId = val),
                    validator: (v) => v == null || v.isEmpty ? 'Debe seleccionar una finca' : null,
                  ),
                  const SizedBox(height: 16),
                  // Dropdown Rol Asignado (HU-003 / HU-004 / CU-012)
                  DropdownButtonFormField<String>(
                    initialValue: selectedRol,
                    decoration: const InputDecoration(labelText: 'Rol Asignado'),
                    items: _rolesDisponibles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) => setDialogState(() => selectedRol = val),
                    validator: (v) => v == null || v.isEmpty ? 'Debe seleccionar un rol' : null,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Estado Activo'),
                    value: estadoActivo,
                    activeThumbColor: GavacColors.primary,
                    onChanged: (val) => setDialogState(() => estadoActivo = val),
                  ),
                ],
              ),
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
                    if (usuarioToEdit == null) {
                      _usuarios.add(
                        AdminUsuarioModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          nombre: nombreController.text.trim(),
                          correo: correoController.text.trim(),
                          fincaId: selectedFincaId!,
                          rol: selectedRol!,
                          activo: estadoActivo,
                        ),
                      );
                    } else {
                      _usuarios[index!] = AdminUsuarioModel(
                        id: usuarioToEdit.id,
                        nombre: nombreController.text.trim(),
                        correo: correoController.text.trim(),
                        fincaId: selectedFincaId!,
                        rol: selectedRol!,
                        activo: estadoActivo,
                        permisos: usuarioToEdit.permisos, // Mantiene permisos previos o los del rol
                      );
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(usuarioToEdit == null ? 'Usuario registrado exitosamente' : 'Cambios de rol guardados')),
                  );
                }
              },
              child: Text(usuarioToEdit == null ? 'Registrar' : 'Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }

  // Modal para Asignar Permisos Granulares por Módulo (HU-004 / CU-012)
  void _showAsignarPermisosDialog(AdminUsuarioModel user) {
    Map<String, bool> tempPermisos = Map.from(user.permisos);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Asignar Permisos: ${user.nombre}'),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  children: [
                    const Text('Rol actual: ', style: TextStyle(color: Colors.grey)),
                    Chip(
                      label: Text(user.rol),
                      backgroundColor: Colors.blue[50],
                      labelStyle: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text('Permisos y Restricciones por Módulo:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: GavacColors.primary)),
                const SizedBox(height: 8),
                const Text('Configura qué acciones puede realizar este usuario en el sistema.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Registro'),
                  subtitle: const Text('Permite registrar animales y datos base'),
                  value: tempPermisos['registro'] ?? true,
                  activeThumbColor: GavacColors.primary,
                  onChanged: (val) => setDialogState(() => tempPermisos['registro'] = val),
                ),
                SwitchListTile(
                  title: const Text('Sanidad'),
                  subtitle: const Text('Permite registrar eventos sanitarios y vacunas'),
                  value: tempPermisos['sanidad'] ?? true,
                  activeThumbColor: GavacColors.primary,
                  onChanged: (val) => setDialogState(() => tempPermisos['sanidad'] = val),
                ),
                SwitchListTile(
                  title: const Text('Productividad'),
                  subtitle: const Text('Permite gestionar datos de productividad'),
                  value: tempPermisos['productividad'] ?? true,
                  activeThumbColor: GavacColors.primary,
                  onChanged: (val) => setDialogState(() => tempPermisos['productividad'] = val),
                ),
                SwitchListTile(
                  title: const Text('Reproducción'),
                  subtitle: const Text('Permite gestionar eventos reproductivos'),
                  value: tempPermisos['reproduccion'] ?? true,
                  activeThumbColor: GavacColors.primary,
                  onChanged: (val) => setDialogState(() => tempPermisos['reproduccion'] = val),
                ),
                SwitchListTile(
                  title: const Text('Reportes'),
                  subtitle: const Text('Permite consultar informes y estadísticas'),
                  value: tempPermisos['reportes'] ?? true,
                  activeThumbColor: GavacColors.primary,
                  onChanged: (val) => setDialogState(() => tempPermisos['reportes'] = val),
                ),
                SwitchListTile(
                  title: const Text('Admin'),
                  subtitle: const Text('Permite gestionar fincas y usuarios'),
                  value: tempPermisos['admin'] ?? true,
                  activeThumbColor: GavacColors.primary,
                  onChanged: (val) => setDialogState(() => tempPermisos['admin'] = val),
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
                setState(() {
                  user.permisos = tempPermisos;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Permisos granulares actualizados exitosamente'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Guardar Permisos'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios y Roles'),
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
                const Text(
                  'Usuarios del Sistema',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: GavacColors.primary),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showUsuarioDialog(),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Registrar Usuario'),
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
                itemCount: _usuarios.length,
                itemBuilder: (context, index) {
                  final user = _usuarios[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: user.activo ? Colors.blue[100] : Colors.grey[200],
                        child: Text(user.nombre[0], style: TextStyle(color: user.activo ? GavacColors.primary : Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(user.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Correo: ${user.correo}', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Chip(
                                label: Text('Rol: ${user.rol}'),
                                backgroundColor: Colors.blue[50],
                                labelStyle: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(user.activo ? 'Activo' : 'Inactivo'),
                                backgroundColor: user.activo ? Colors.green[50] : Colors.red[50],
                                labelStyle: TextStyle(
                                  color: user.activo ? Colors.green[700] : Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botón Asignar Permisos (HU-004 / CU-012)
                          IconButton(
                            icon: const Icon(Icons.security, color: Colors.orange),
                            onPressed: () => _showAsignarPermisosDialog(user),
                            tooltip: 'Asignar Permisos y Accesos por Módulo',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            onPressed: () => _showUsuarioDialog(usuarioToEdit: user, index: index),
                            tooltip: 'Editar Rol y Datos',
                          ),
                          Switch(
                            value: user.activo,
                            activeThumbColor: GavacColors.primary,
                            onChanged: (val) {
                              setState(() {
                                user.activo = val;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(val ? 'Usuario activado' : 'Usuario desactivado')),
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
