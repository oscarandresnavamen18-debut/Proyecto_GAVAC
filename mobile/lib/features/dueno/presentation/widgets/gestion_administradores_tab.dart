import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/dueno_models.dart';
import '../../data/services/dueno_api_service.dart';

class GestionAdministradoresTab extends StatefulWidget {
  final DuenoRepository repository;
  final List<FincaDuenoModel> fincas;
  final VoidCallback onRefresh;
  final ValueChanged<Widget>? onOpenModal;
  final VoidCallback? onCloseModal;

  const GestionAdministradoresTab({
    super.key,
    required this.repository,
    required this.fincas,
    required this.onRefresh,
    this.onOpenModal,
    this.onCloseModal,
  });

  @override
  State<GestionAdministradoresTab> createState() =>
      _GestionAdministradoresTabState();
}

class _GestionAdministradoresTabState
    extends State<GestionAdministradoresTab> {
  static const Color primaryColor = Color(0xFF1A3A32);
  static const Color textMuted = Color(0xFF64748B);

  List<AdministradorModel> _admins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);
    final list = await widget.repository.listAdministradores();
    if (!mounted) return;
    setState(() {
      _admins = list;
      _isLoading = false;
    });
  }

  void _showCreateAdminModal() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final List<int> selectedFarmIds = [];
    final List<String> selectedPermissions = ['registro', 'sanidad', 'produccion'];

    final modalWidget = StatefulBuilder(
      builder: (context, setModalState) => Container(
        width: 520,
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
                  child: const Icon(Icons.person_add_alt_1,
                      color: primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Crear Administrador',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Completo *',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico *',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña *',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Asignar Fincas:',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.fincas.isEmpty)
                    const Text(
                      'No hay fincas registradas aún. Puedes agregar fincas en la pestaña "Fincas".',
                      style: TextStyle(color: textMuted, fontSize: 13),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      children: widget.fincas.map((finca) {
                        final selected = selectedFarmIds.contains(finca.id);
                        return FilterChip(
                          label: Text(finca.name),
                          selected: selected,
                          selectedColor: primaryColor.withValues(alpha: 0.2),
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selectedFarmIds.add(finca.id);
                              } else {
                                selectedFarmIds.remove(finca.id);
                              }
                            });
                          },
                        );
                      }).toList(),
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
                          final farmNames = widget.fincas
                              .where((f) => selectedFarmIds.contains(f.id))
                              .map((f) => f.name)
                              .toList();
                          final newAdmin =
                              await widget.repository.createAdministrador(
                            fullName: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            password: passCtrl.text,
                            farmIds: selectedFarmIds,
                            permissions: selectedPermissions,
                          );
                          final adminWithNames = newAdmin.copyWith(
                            fullName: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            farmIds: selectedFarmIds,
                            farmNames: farmNames,
                          );
                          if (!mounted) return;
                          setState(() => _admins.insert(0, adminWithNames));
                          widget.onRefresh();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Administrador registrado exitosamente.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: const Text('Guardar Administrador'),
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

  void _showEditAdminModal(AdministradorModel admin, int index) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: admin.fullName);
    final emailCtrl = TextEditingController(text: admin.email);
    final List<int> selectedFarmIds = List.from(admin.farmIds);

    final modalWidget = StatefulBuilder(
      builder: (context, setModalState) => Container(
        width: 520,
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
                  'Editar Administrador',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Completo *',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico *',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Asignar Fincas:',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.fincas.isEmpty)
                    const Text('No hay fincas registradas aún.')
                  else
                    Wrap(
                      spacing: 8,
                      children: widget.fincas.map((finca) {
                        final selected = selectedFarmIds.contains(finca.id);
                        return FilterChip(
                          label: Text(finca.name),
                          selected: selected,
                          selectedColor: primaryColor.withValues(alpha: 0.15),
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selectedFarmIds.add(finca.id);
                              } else {
                                selectedFarmIds.remove(finca.id);
                              }
                            });
                          },
                        );
                      }).toList(),
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
                          final farmNames = widget.fincas
                              .where((f) => selectedFarmIds.contains(f.id))
                              .map((f) => f.name)
                              .toList();
                          final updated =
                              await widget.repository.updateAdministrador(
                            id: admin.id,
                            fullName: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            farmIds: selectedFarmIds,
                          );
                          final updatedWithNames = updated.copyWith(
                            fullName: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            farmIds: selectedFarmIds,
                            farmNames: farmNames,
                          );
                          if (!mounted) return;
                          setState(() => _admins[index] = updatedWithNames);
                          widget.onRefresh();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Administrador actualizado.')),
                          );
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Actualizar Administrador'),
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

  void _toggleAdminStatus(AdministradorModel admin, int index) async {
    final updated = await widget.repository.updateAdministrador(
      id: admin.id,
      isActive: !admin.isActive,
    );
    if (!mounted) return;
    setState(() => _admins[index] = updated.copyWith(isActive: !admin.isActive));
    widget.onRefresh();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !admin.isActive
              ? 'Administrador activado.'
              : 'Administrador desactivado.',
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
                'Gestión de Administradores',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateAdminModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Nuevo Administrador'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_admins.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No hay administradores registrados aún.',
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
                  DataColumn(label: Text('NOMBRE')),
                  DataColumn(label: Text('EMAIL')),
                  DataColumn(label: Text('FINCAS ASIGNADAS')),
                  DataColumn(label: Text('ESTADO')),
                  DataColumn(label: Text('ACCIONES')),
                ],
                rows: _admins.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final admin = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text(admin.fullName,
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700))),
                      DataCell(Text(admin.email)),
                      DataCell(Text(admin.farmNames.isNotEmpty
                          ? admin.farmNames.join(', ')
                          : 'Sin fincas')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: admin.isActive
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            admin.isActive ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              color: admin.isActive
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
                              tooltip: 'Editar Administrador',
                              onPressed: () => _showEditAdminModal(admin, idx),
                            ),
                            IconButton(
                              icon: Icon(
                                admin.isActive
                                    ? Icons.block
                                    : Icons.check_circle_outline,
                                color: admin.isActive ? Colors.orange : Colors.green,
                              ),
                              tooltip: admin.isActive ? 'Desactivar' : 'Activar',
                              onPressed: () => _toggleAdminStatus(admin, idx),
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
