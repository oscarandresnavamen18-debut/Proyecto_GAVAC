import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/dueno_models.dart';
import '../../data/services/dueno_api_service.dart';

class _AlwaysMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _AlwaysMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return const DefaultMaterialLocalizations();
  }

  @override
  bool shouldReload(_AlwaysMaterialLocalizationsDelegate old) => false;
}

class AsignacionFincasTab extends StatefulWidget {
  final DuenoRepository repository;
  final List<FincaDuenoModel> fincas;
  final List<UsuarioDuenoModel> usuarios;
  final VoidCallback onRefresh;

  const AsignacionFincasTab({
    super.key,
    required this.repository,
    required this.fincas,
    required this.usuarios,
    required this.onRefresh,
  });

  @override
  State<AsignacionFincasTab> createState() => _AsignacionFincasTabState();
}

class _AsignacionFincasTabState extends State<AsignacionFincasTab> {
  static const Color primaryColor = Color(0xFF1A3A32);
  static const Color textMuted = Color(0xFF64748B);

  int? selectedFarmId;
  int? selectedUserId;

  void _showMessage(String text) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(SnackBar(content: Text(text)));
    }
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
          Text(
            'Asignación de Fincas a Personal',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vincula administradores, trabajadores y veterinarios a las fincas autorizadas.',
            style: GoogleFonts.plusJakartaSans(color: textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomSelectField<int>(
                  label: 'Seleccionar Finca *',
                  icon: Icons.home_outlined,
                  value: selectedFarmId,
                  items: widget.fincas.map((f) {
                    return DropdownMenuItem(value: f.id, child: Text(f.name));
                  }).toList(),
                  onChanged: (v) => setState(() => selectedFarmId = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSelectField<int>(
                  label: 'Seleccionar Usuario / Administrador *',
                  icon: Icons.person_outline,
                  value: selectedUserId,
                  items: widget.usuarios.map((u) {
                    return DropdownMenuItem(
                      value: u.id,
                      child: Text('${u.fullName} (${u.role})'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => selectedUserId = v),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onPressed: () async {
                  if (selectedFarmId == null || selectedUserId == null) {
                    _showMessage(
                      'Selecciona una finca y un usuario para realizar la asignación.',
                    );
                    return;
                  }
                  await widget.repository.asignarFinca(
                    userId: selectedUserId!,
                    farmId: selectedFarmId!,
                  );
                  if (!mounted) return;
                  widget.onRefresh();
                  _showMessage('Finca asignada correctamente.');
                },
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Asignar Finca'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Resumen de Asignaciones Actuales:',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.usuarios.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No hay asignaciones registradas.')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('USUARIO')),
                  DataColumn(label: Text('ROL')),
                  DataColumn(label: Text('FINCAS ASIGNADAS')),
                  DataColumn(label: Text('ACCIONES')),
                ],
                rows: widget.usuarios.map((user) {
                  return DataRow(
                    cells: [
                      DataCell(Text(user.fullName,
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700))),
                      DataCell(Text(user.role)),
                      DataCell(Text(user.farmNames.isNotEmpty
                          ? user.farmNames.join(', ')
                          : 'Sin fincas')),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.link_off, color: Colors.redAccent),
                          tooltip: 'Retirar asignaciones',
                          onPressed: () async {
                            if (user.farmIds.isNotEmpty) {
                              await widget.repository.retirarFinca(
                                userId: user.id,
                                farmId: user.farmIds.first,
                              );
                              if (!mounted) return;
                              widget.onRefresh();
                            }
                          },
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

class CustomSelectField<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const CustomSelectField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    DropdownMenuItem<T>? selectedItem;
    for (final item in items) {
      if (item.value == value) {
        selectedItem = item;
        break;
      }
    }
    final selectedWidget = selectedItem?.child;
    final selectedText =
        selectedWidget is Text ? selectedWidget.data ?? '' : '';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: items.isEmpty
          ? null
          : () async {
              final selected = await showDialog<T>(
                context: context,
                useRootNavigator: false,
                builder: (dialogContext) => Localizations(
                  locale: const Locale('es', 'CO'),
                  delegates: const [
                    _AlwaysMaterialLocalizationsDelegate(),
                    DefaultWidgetsLocalizations.delegate,
                  ],
                  child: SimpleDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      label.replaceAll('*', '').trim(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A3A32),
                      ),
                    ),
                    children: items.map((item) {
                      final isSelected = item.value == value;
                      return SimpleDialogOption(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        onPressed: () => Navigator.pop(dialogContext, item.value),
                        child: Row(
                          children: [
                            Expanded(child: item.child),
                            if (isSelected)
                              const Icon(Icons.check,
                                  color: Color(0xFF1A3A32), size: 18),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
              if (selected != null) {
                onChanged(selected);
              }
            },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF2E5A4D)),
          suffixIcon:
              const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
          ),
        ),
        child: Text(
          selectedText.isNotEmpty
              ? selectedText
              : (items.isEmpty ? 'No hay opciones disponibles' : 'Seleccionar opción...'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight:
                selectedText.isNotEmpty ? FontWeight.w700 : FontWeight.w500,
            color: selectedText.isNotEmpty
                ? const Color(0xFF1E293B)
                : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}
