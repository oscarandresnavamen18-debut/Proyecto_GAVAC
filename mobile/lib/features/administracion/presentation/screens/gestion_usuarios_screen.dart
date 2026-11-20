import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/gavac_colors.dart';
import '../../data/models/finca_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/admin_api_service.dart';

class GestionUsuariosAdminScreen extends StatefulWidget {
  const GestionUsuariosAdminScreen({super.key});

  @override
  State<GestionUsuariosAdminScreen> createState() =>
      _GestionUsuariosAdminScreenState();
}

class _GestionUsuariosAdminScreenState
    extends State<GestionUsuariosAdminScreen> {
  List<AdminUsuarioModel> _usuarios = [];
  List<AdminFincaModel> _fincas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resultados = await Future.wait([
        AdminApiService.listarUsuarios(),
        AdminApiService.listarFincas(),
      ]);
      if (!mounted) return;
      setState(() {
        _usuarios = resultados[0] as List<AdminUsuarioModel>;
        _fincas = resultados[1] as List<AdminFincaModel>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarMensaje(String mensaje, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: color));
  }

  void _reemplazarUsuario(AdminUsuarioModel actualizado) {
    setState(() {
      _usuarios = [
        for (final u in _usuarios) u.id == actualizado.id ? actualizado : u,
      ];
    });
  }

  String _nombreFinca(int? fincaId) {
    for (final finca in _fincas) {
      if (finca.id == fincaId) return finca.nombre;
    }
    return 'Sin finca';
  }

  void _showUsuarioDialog({AdminUsuarioModel? usuarioToEdit}) {
    // PRECONDICIÓN HU-003: debe existir al menos una finca.
    if (_fincas.isEmpty) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Aviso'),
          content: const Text(
            'No se puede registrar un usuario porque debe existir al menos una finca registrada previamente.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GavacColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    final esNuevo = usuarioToEdit == null;
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(
      text: usuarioToEdit?.nombre ?? '',
    );
    final correoController = TextEditingController(
      text: usuarioToEdit?.correo ?? '',
    );
    final passwordController = TextEditingController();

    int? selectedFincaId = usuarioToEdit?.fincaId ?? _fincas.first.id;
    if (!_fincas.any((f) => f.id == selectedFincaId)) {
      selectedFincaId = _fincas.first.id;
    }
    String selectedRol = rolesAsignables.containsKey(usuarioToEdit?.rol)
        ? usuarioToEdit!.rol
        : rolesAsignables.keys.first;
    bool estadoActivo = usuarioToEdit?.activo ?? true;
    var guardando = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(esNuevo ? 'Registrar Usuario' : 'Editar Usuario y Rol'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      hintText: 'Ej. Juan Pérez',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'El nombre es obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: correoController,
                    enabled: esNuevo,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      hintText: 'juan@finca.com',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'El correo es obligatorio';
                      }
                      if (!v.contains('@')) return 'Ingrese un correo válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: esNuevo
                          ? 'Contraseña inicial'
                          : 'Nueva contraseña (opcional)',
                      helperText: 'Mínimo 8 caracteres',
                    ),
                    validator: (v) {
                      final valor = v ?? '';
                      if (esNuevo && valor.isEmpty) {
                        return 'La contraseña es obligatoria';
                      }
                      if (valor.isNotEmpty && valor.length < 8) {
                        return 'Mínimo 8 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Finca asignada (HU-003)
                  DropdownButtonFormField<int>(
                    initialValue: selectedFincaId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Finca Asignada',
                    ),
                    items: [
                      for (final f in _fincas)
                        DropdownMenuItem(value: f.id, child: Text(f.nombre)),
                    ],
                    onChanged: (val) =>
                        setDialogState(() => selectedFincaId = val),
                    validator: (v) =>
                        v == null ? 'Debe seleccionar una finca' : null,
                  ),
                  const SizedBox(height: 16),
                  // Rol asignado (HU-003 / HU-004 / CU-012)
                  DropdownButtonFormField<String>(
                    initialValue: selectedRol,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Rol Asignado',
                    ),
                    items: [
                      for (final rol in rolesAsignables.entries)
                        DropdownMenuItem(
                          value: rol.key,
                          child: Text(rol.value),
                        ),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRol = val);
                    },
                  ),
                  if (!esNuevo) ...[
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Estado Activo'),
                      value: estadoActivo,
                      activeThumbColor: GavacColors.primary,
                      onChanged: (val) =>
                          setDialogState(() => estadoActivo = val),
                    ),
                  ],
                ],
              ),
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
                      final password = passwordController.text;
                      try {
                        if (esNuevo) {
                          final creado = await AdminApiService.crearUsuario(
                            nombre: nombreController.text.trim(),
                            correo: correoController.text.trim(),
                            password: password,
                            rol: selectedRol,
                            fincaId: selectedFincaId!,
                          );
                          setState(() => _usuarios = [..._usuarios, creado]);
                        } else {
                          final actualizado =
                              await AdminApiService.actualizarUsuario(
                                usuarioToEdit.id,
                                nombre: nombreController.text.trim(),
                                rol: selectedRol,
                                fincaId: selectedFincaId,
                                activo: estadoActivo,
                                password: password.isEmpty ? null : password,
                              );
                          _reemplazarUsuario(actualizado);
                        }
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        _mostrarMensaje(
                          esNuevo
                              ? 'Usuario registrado exitosamente'
                              : 'Cambios guardados',
                        );
                      } catch (error) {
                        setDialogState(() => guardando = false);
                        _mostrarMensaje(error.toString());
                      }
                    },
              child: Text(esNuevo ? 'Registrar' : 'Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }

  // Permisos por módulo (HU-004 / CU-012)
  void _showAsignarPermisosDialog(AdminUsuarioModel user) {
    final seleccion = user.permisos.toSet();
    var guardando = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Asignar Permisos: ${user.nombre}'),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  children: [
                    const Text(
                      'Rol actual: ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Chip(
                      label: Text(etiquetaRol(user.rol)),
                      backgroundColor: Colors.blue[50],
                      labelStyle: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text(
                  'Módulos habilitados:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: GavacColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'El usuario solo verá y podrá usar los módulos activados. '
                  'Administración es exclusiva del administrador.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                for (final modulo in modulosConPermiso.entries)
                  SwitchListTile(
                    title: Text(modulo.value),
                    value: seleccion.contains(modulo.key),
                    activeThumbColor: GavacColors.primary,
                    onChanged: (val) => setDialogState(() {
                      if (val) {
                        seleccion.add(modulo.key);
                      } else {
                        seleccion.remove(modulo.key);
                      }
                    }),
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
                      setDialogState(() => guardando = true);
                      try {
                        final actualizado =
                            await AdminApiService.actualizarUsuario(
                              user.id,
                              permisos: [
                                for (final key in modulosConPermiso.keys)
                                  if (seleccion.contains(key)) key,
                              ],
                            );
                        _reemplazarUsuario(actualizado);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        _mostrarMensaje(
                          'Permisos actualizados exitosamente',
                          color: Colors.green,
                        );
                      } catch (error) {
                        setDialogState(() => guardando = false);
                        _mostrarMensaje(error.toString());
                      }
                    },
              child: const Text('Guardar Permisos'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cambiarEstado(AdminUsuarioModel user, bool activo) async {
    try {
      final actualizado = await AdminApiService.actualizarUsuario(
        user.id,
        activo: activo,
      );
      _reemplazarUsuario(actualizado);
      _mostrarMensaje(activo ? 'Usuario activado' : 'Usuario desactivado');
    } catch (error) {
      _mostrarMensaje(error.toString());
    }
  }

  Widget _buildContenido() {
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
              onPressed: _cargarDatos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_usuarios.isEmpty) {
      return const Center(
        child: Text('Aún no hay veterinarios ni trabajadores registrados.'),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        itemCount: _usuarios.length,
        itemBuilder: (context, index) {
          final user = _usuarios[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: user.activo
                    ? Colors.blue[100]
                    : Colors.grey[200],
                child: Text(
                  user.nombre.isEmpty ? '?' : user.nombre[0].toUpperCase(),
                  style: TextStyle(
                    color: user.activo ? GavacColors.primary : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                user.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Correo: ${user.correo}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Finca: ${_nombreFinca(user.fincaId)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text('Rol: ${etiquetaRol(user.rol)}'),
                        backgroundColor: Colors.blue[50],
                        labelStyle: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Chip(
                        label: Text(user.activo ? 'Activo' : 'Inactivo'),
                        backgroundColor: user.activo
                            ? Colors.green[50]
                            : Colors.red[50],
                        labelStyle: TextStyle(
                          color: user.activo
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.security, color: Colors.orange),
                    onPressed: () => _showAsignarPermisosDialog(user),
                    tooltip: 'Asignar permisos por módulo',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () => _showUsuarioDialog(usuarioToEdit: user),
                    tooltip: 'Editar rol y datos',
                  ),
                  Switch(
                    value: user.activo,
                    activeThumbColor: GavacColors.primary,
                    onChanged: (val) => _cambiarEstado(user, val),
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                const Text(
                  'Usuarios del Sistema',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: GavacColors.primary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _cargando ? null : () => _showUsuarioDialog(),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Registrar Usuario'),
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
            Expanded(child: _buildContenido()),
          ],
        ),
      ),
    );
  }
}
