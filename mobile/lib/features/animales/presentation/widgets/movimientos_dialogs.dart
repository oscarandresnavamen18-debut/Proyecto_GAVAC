import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/date_format.dart';
import '../../data/services/animal_api_service.dart';
import '../../data/services/potreros_api_service.dart';

/// Datos elegidos en el diálogo de mover animales.
class MoverAnimalesDatos {
  const MoverAnimalesDatos({
    required this.animalIds,
    required this.destinoId,
    required this.fecha,
    this.notas,
  });

  final List<int> animalIds;
  // null = sin potrero.
  final int? destinoId;
  final DateTime fecha;
  final String? notas;
}

/// Datos elegidos en el diálogo de salida.
class SalidaDatos {
  const SalidaDatos({
    required this.tipo,
    required this.fecha,
    this.precio,
    this.comprador,
    this.causa,
    this.notas,
  });

  // VENTA o MUERTE.
  final String tipo;
  final DateTime fecha;
  final double? precio;
  final String? comprador;
  final String? causa;
  final String? notas;
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(formatDate(value)),
      ),
    );
  }
}

/// Elige animales, potrero de destino, fecha y nota. Devuelve null si se cancela.
Future<MoverAnimalesDatos?> showMoverAnimalesDialog(
  BuildContext context, {
  required List<AnimalRecord> animales,
  required List<Potrero> potreros,
  required String Function(int?) nombrePotrero,
  int? preseleccionado,
}) {
  final seleccion = <int>{?preseleccionado};
  final notasController = TextEditingController();
  int? destino = potreros.isEmpty ? null : potreros.first.id;
  // Filtro por potrero de origen: -1 = todos.
  var origen = -1;
  var fecha = DateTime.now();

  return showDialog<MoverAnimalesDatos>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final visibles = animales
            .where((a) => origen == -1 || (a.loteId ?? 0) == origen)
            .toList();
        final todosMarcados =
            visibles.isNotEmpty &&
            visibles.every((a) => seleccion.contains(a.id));
        return AlertDialog(
          title: const Text('Mover animales de potrero'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int?>(
                    isExpanded: true,
                    initialValue: destino,
                    decoration: const InputDecoration(labelText: 'Mover a'),
                    items: [
                      for (final potrero in potreros)
                        DropdownMenuItem<int?>(
                          value: potrero.id,
                          child: Text(
                            '${potrero.nombre} (${potrero.animales})',
                          ),
                        ),
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Sin potrero'),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => destino = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Fecha del movimiento',
                          value: fecha,
                          onPick: (d) => setDialogState(() => fecha = d),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: origen,
                          decoration: const InputDecoration(
                            labelText: 'Mostrar animales de',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: -1,
                              child: Text('Todos'),
                            ),
                            for (final potrero in potreros)
                              DropdownMenuItem(
                                value: potrero.id,
                                child: Text(potrero.nombre),
                              ),
                            const DropdownMenuItem(
                              value: 0,
                              child: Text('Sin potrero'),
                            ),
                          ],
                          onChanged: (v) =>
                              setDialogState(() => origen = v ?? -1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notasController,
                    decoration: const InputDecoration(
                      labelText: 'Nota',
                      hintText: 'Ej. Rotación de pastos',
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: todosMarcados,
                    title: Text('Seleccionar los ${visibles.length} mostrados'),
                    onChanged: (v) => setDialogState(() {
                      for (final a in visibles) {
                        v == true
                            ? seleccion.add(a.id)
                            : seleccion.remove(a.id);
                      }
                    }),
                  ),
                  const Divider(height: 1),
                  for (final animal in visibles)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: seleccion.contains(animal.id),
                      title: Text(animal.chapeta),
                      subtitle: Text(nombrePotrero(animal.loteId)),
                      onChanged: (v) => setDialogState(() {
                        v == true
                            ? seleccion.add(animal.id)
                            : seleccion.remove(animal.id);
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: seleccion.isEmpty
                  ? null
                  : () => Navigator.pop(
                      dialogContext,
                      MoverAnimalesDatos(
                        animalIds: seleccion.toList(),
                        destinoId: destino,
                        fecha: fecha,
                        notas: notasController.text,
                      ),
                    ),
              child: Text('Mover ${seleccion.length}'),
            ),
          ],
        );
      },
    ),
  );
}

/// Registra la venta o la muerte de un animal. Devuelve null si se cancela.
Future<SalidaDatos?> showSalidaDialog(
  BuildContext context, {
  required String chapeta,
}) {
  final formKey = GlobalKey<FormState>();
  final precioController = TextEditingController();
  final compradorController = TextEditingController();
  final causaController = TextEditingController();
  final notasController = TextEditingController();
  var tipo = 'VENTA';
  var fecha = DateTime.now();

  return showDialog<SalidaDatos>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final venta = tipo == 'VENTA';
        return AlertDialog(
          title: Text('Salida de $chapeta'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'VENTA',
                          label: Text('Venta'),
                          icon: Icon(Icons.sell_outlined),
                        ),
                        ButtonSegment(
                          value: 'MUERTE',
                          label: Text('Muerte'),
                          icon: Icon(Icons.heart_broken_outlined),
                        ),
                      ],
                      selected: {tipo},
                      onSelectionChanged: (v) =>
                          setDialogState(() => tipo = v.first),
                    ),
                    const SizedBox(height: 16),
                    _DateField(
                      label: venta ? 'Fecha de la venta' : 'Fecha de la muerte',
                      value: fecha,
                      onPick: (d) => setDialogState(() => fecha = d),
                    ),
                    const SizedBox(height: 12),
                    if (venta) ...[
                      TextFormField(
                        controller: precioController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Precio de venta (\$)',
                          hintText: 'Ej. 3500000',
                        ),
                        validator: (v) {
                          final text = (v ?? '').trim();
                          if (text.isEmpty) return null;
                          return _parsePrecio(text) == null
                              ? 'Escribe solo el número, ej. 3500000'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: compradorController,
                        decoration: const InputDecoration(
                          labelText: 'Comprador',
                        ),
                      ),
                    ] else
                      TextFormField(
                        controller: causaController,
                        decoration: const InputDecoration(
                          labelText: 'Causa de la muerte *',
                        ),
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? 'Indica la causa' : null,
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notasController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(
                  dialogContext,
                  SalidaDatos(
                    tipo: tipo,
                    fecha: fecha,
                    precio: venta ? _parsePrecio(precioController.text) : null,
                    comprador: venta ? compradorController.text : null,
                    causa: venta ? null : causaController.text,
                    notas: notasController.text,
                  ),
                );
              },
              child: Text(venta ? 'Registrar venta' : 'Registrar muerte'),
            ),
          ],
        );
      },
    ),
  );
}

/// Acepta "3500000", "3.500.000" o "$ 3.500.000,50".
double? _parsePrecio(String text) {
  final cleaned = text.replaceAll(RegExp(r'[\$\s.]'), '').replaceAll(',', '.');
  final value = double.tryParse(cleaned);
  return value != null && value >= 0 ? value : null;
}
