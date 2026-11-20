import 'package:material_ui/material_ui.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/gavac_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../data/services/potreros_api_service.dart';

/// Potreros de la finca, historial de movimientos y salidas de animales.
class PotrerosScreen extends StatefulWidget {
  const PotrerosScreen({
    super.key,
    this.repository = const PotrerosApiService(),
  });

  final PotrerosRepository repository;

  @override
  State<PotrerosScreen> createState() => _PotrerosScreenState();
}

class _PotrerosScreenState extends State<PotrerosScreen> {
  List<Potrero> _potreros = [];
  List<MovimientoPotrero> _movimientos = [];
  List<SalidaAnimal> _salidas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.repository.listPotreros(incluirInactivos: true),
        widget.repository.listMovimientos(),
        widget.repository.listSalidas(),
      ]);
      if (!mounted) return;
      setState(() {
        _potreros = results[0] as List<Potrero>;
        _movimientos = results[1] as List<MovimientoPotrero>;
        _salidas = results[2] as List<SalidaAnimal>;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _editarPotrero([Potrero? potrero]) async {
    final formKey = GlobalKey<FormState>();
    final nombre = TextEditingController(text: potrero?.nombre ?? '');
    final descripcion = TextEditingController(text: potrero?.descripcion ?? '');
    final area = TextEditingController(
      text: potrero?.areaHectareas == null ? '' : '${potrero!.areaHectareas}',
    );
    final guardar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(potrero == null ? 'Nuevo potrero' : 'Editar potrero'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombre,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej. Potrero La Loma',
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'El nombre es obligatorio'
                    : null,
              ),
              TextFormField(
                controller: area,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Área (hectáreas)',
                ),
                validator: (v) {
                  final text = (v ?? '').trim().replaceAll(',', '.');
                  if (text.isEmpty) return null;
                  final value = double.tryParse(text);
                  return value == null || value <= 0 ? 'Área no válida' : null;
                },
              ),
              TextFormField(
                controller: descripcion,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ej. Pasto estrella, con bebedero',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (guardar != true) return;
    final areaValor = double.tryParse(area.text.trim().replaceAll(',', '.'));
    try {
      if (potrero == null) {
        await widget.repository.crearPotrero(
          nombre: nombre.text,
          descripcion: descripcion.text,
          areaHectareas: areaValor,
        );
        _mensaje('Potrero creado.');
      } else {
        await widget.repository.actualizarPotrero(
          potrero.id,
          nombre: nombre.text,
          descripcion: descripcion.text,
          areaHectareas: areaValor,
        );
        _mensaje('Potrero actualizado.');
      }
      await _cargar();
    } on ApiException catch (error) {
      _mensaje(error.message);
    }
  }

  Future<void> _cambiarEstado(Potrero potrero) async {
    try {
      await widget.repository.actualizarPotrero(
        potrero.id,
        activo: !potrero.activo,
      );
      _mensaje(potrero.activo ? 'Potrero desactivado.' : 'Potrero activado.');
      await _cargar();
    } on ApiException catch (error) {
      _mensaje(error.message);
    }
  }

  Future<void> _anular(SalidaAnimal salida) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Anular ${salida.tipoTexto.toLowerCase()}'),
        content: Text(
          '${salida.chapeta} volverá a estar en la finca. Úsalo solo para '
          'corregir un registro hecho por error.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await widget.repository.anularSalida(salida.id);
      _mensaje('${salida.chapeta} vuelve a estar en la finca.');
      await _cargar();
    } on ApiException catch (error) {
      _mensaje(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Potreros y salidas'),
          backgroundColor: GavacColors.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Potreros'),
              Tab(text: 'Movimientos'),
              Tab(text: 'Salidas'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _cargando ? null : () => _editarPotrero(),
          backgroundColor: GavacColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Nuevo potrero'),
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _cargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            : TabBarView(
                children: [
                  _listaPotreros(),
                  _listaMovimientos(),
                  _listaSalidas(),
                ],
              ),
      ),
    );
  }

  Widget _vacio(String texto) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(texto, textAlign: TextAlign.center),
    ),
  );

  Widget _listaPotreros() {
    if (_potreros.isEmpty) {
      return _vacio(
        'Aún no hay potreros. Crea el primero con "Nuevo potrero".',
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          for (final potrero in _potreros)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: potrero.activo
                      ? const Color(0xFFE5F4E4)
                      : const Color(0xFFF0EFEC),
                  child: Icon(
                    Icons.grass_rounded,
                    color: potrero.activo ? GavacColors.primary : Colors.grey,
                  ),
                ),
                title: Text(
                  potrero.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  [
                    '${potrero.animales} ${potrero.animales == 1 ? 'animal' : 'animales'}',
                    if (potrero.areaHectareas != null)
                      '${potrero.areaHectareas!.toStringAsFixed(potrero.areaHectareas! % 1 == 0 ? 0 : 1)} ha',
                    if (potrero.descripcion != null) potrero.descripcion!,
                    if (!potrero.activo) 'Inactivo',
                  ].join(' · '),
                ),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Editar potrero',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editarPotrero(potrero),
                    ),
                    IconButton(
                      tooltip: potrero.activo ? 'Desactivar' : 'Activar',
                      icon: Icon(
                        potrero.activo
                            ? Icons.toggle_on_rounded
                            : Icons.toggle_off_rounded,
                        color: potrero.activo
                            ? GavacColors.primary
                            : Colors.grey,
                      ),
                      onPressed: () => _cambiarEstado(potrero),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _listaMovimientos() {
    if (_movimientos.isEmpty) {
      return _vacio('Todavía no hay movimientos entre potreros.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _movimientos.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final m = _movimientos[index];
        return ListTile(
          leading: const Icon(
            Icons.swap_horiz_rounded,
            color: GavacColors.primary,
          ),
          title: Text(
            '${m.chapeta}: ${m.desde ?? 'Sin potrero'} → ${m.hacia ?? 'Sin potrero'}',
          ),
          subtitle: Text(
            [
              formatDate(m.fecha),
              if (m.notas != null) m.notas!,
              if (m.registradoPor != null) m.registradoPor!,
            ].join(' · '),
          ),
        );
      },
    );
  }

  Widget _listaSalidas() {
    if (_salidas.isEmpty) {
      return _vacio('No hay ventas ni muertes registradas.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _salidas.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final s = _salidas[index];
        final detalle = s.esVenta
            ? [
                if (s.precio != null) '\$ ${_miles(s.precio!)}',
                if (s.comprador != null) s.comprador!,
              ]
            : [if (s.causa != null) s.causa!];
        return ListTile(
          leading: Icon(
            s.esVenta ? Icons.sell_outlined : Icons.heart_broken_outlined,
            color: s.esVenta ? const Color(0xFF2563EB) : Colors.grey,
          ),
          title: Text('${s.tipoTexto} · ${s.chapeta}'),
          subtitle: Text([formatDate(s.fecha), ...detalle].join(' · ')),
          trailing: TextButton(
            onPressed: () => _anular(s),
            child: const Text('Anular'),
          ),
        );
      },
    );
  }
}

/// 3500000 → "3.500.000".
String _miles(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
