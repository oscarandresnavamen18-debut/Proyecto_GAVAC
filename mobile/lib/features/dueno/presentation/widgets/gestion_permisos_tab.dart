import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/dueno_models.dart';
import '../../data/services/dueno_api_service.dart';
import 'asignacion_fincas_tab.dart';

class GestionPermisosTab extends StatefulWidget {
  final DuenoRepository repository;
  final List<UsuarioDuenoModel> usuarios;
  final VoidCallback onRefresh;

  const GestionPermisosTab({
    super.key,
    required this.repository,
    required this.usuarios,
    required this.onRefresh,
  });

  @override
  State<GestionPermisosTab> createState() => _GestionPermisosTabState();
}

class _GestionPermisosTabState extends State<GestionPermisosTab> {
  static const Color primaryColor = Color(0xFF1A3A32);
  static const Color textMuted = Color(0xFF64748B);

  static const List<Map<String, String>> _modulosGavac = [
    {'key': 'registro', 'label': '1. Registro de Ganado'},
    {'key': 'sanidad', 'label': '2. Sanidad'},
    {'key': 'produccion', 'label': '3. Producción'},
    {'key': 'reproduccion', 'label': '4. Reproducción'},
    {'key': 'reportes', 'label': '5. Reportes'},
    {'key': 'administracion', 'label': '6. Administración'},
  ];

  UsuarioDuenoModel? selectedUser;

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
          Text(
            'Gestión de Permisos por Módulo',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configura el acceso a los 6 módulos funcionales de GAVAC para cada usuario o administrador.',
            style: GoogleFonts.plusJakartaSans(color: textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          CustomSelectField<int>(
            label: 'Seleccionar Usuario / Administrador',
            icon: Icons.admin_panel_settings_outlined,
            value: selectedUser?.id,
            items: widget.usuarios.map((u) {
              return DropdownMenuItem(
                value: u.id,
                child: Text('${u.fullName} (${u.role}) - ${u.email}'),
              );
            }).toList(),
            onChanged: (v) {
              setState(() {
                selectedUser = widget.usuarios.firstWhere((u) => u.id == v);
              });
            },
          ),
          const SizedBox(height: 24),
          if (selectedUser == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Selecciona un usuario arriba para configurar sus permisos.',
                  style: GoogleFonts.plusJakartaSans(color: textMuted),
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Permisos para ${selectedUser!.fullName}:',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                ..._modulosGavac.map((mod) {
                  final key = mod['key']!;
                  final label = mod['label']!;
                  final hasAccess = selectedUser!.permissions.contains(key);
                  return CheckboxListTile(
                    activeColor: primaryColor,
                    title: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      hasAccess ? 'Acceso Permitido' : 'Bloqueado',
                      style: TextStyle(
                        color: hasAccess ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                    value: hasAccess,
                    onChanged: (val) async {
                      final updatedPermissions =
                          List<String>.from(selectedUser!.permissions);
                      if (val == true) {
                        if (!updatedPermissions.contains(key)) {
                          updatedPermissions.add(key);
                        }
                      } else {
                        updatedPermissions.remove(key);
                      }
                      final updated = await widget.repository.updateUsuario(
                        id: selectedUser!.id,
                        permissions: updatedPermissions,
                      );
                      if (!mounted) return;
                      setState(() => selectedUser = updated);
                      widget.onRefresh();
                    },
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}
