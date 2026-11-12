import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_session.dart';
import '../../../../core/widgets/feature_page_widgets.dart';
import '../../data/services/animal_api_service.dart';

extension AnimalRecordUiExtension on AnimalRecord {
  String get finca =>
      AppSession.farmName.isNotEmpty ? AppSession.farmName : 'Sin Finca';
}

class AnimalesScreen extends StatefulWidget {
  final AnimalRepository? repository;

  const AnimalesScreen({super.key, this.repository});

  @override
  State<AnimalesScreen> createState() => _AnimalesScreenState();
}

class _AnimalesScreenState extends State<AnimalesScreen> {
  static const Color primaryColor = Color(0xFF1A3A32);
  static const Color accentColor = Color(0xFF2E5A4D);
  static const Color backgroundColor = Color(0xFFF7F9F7);
  static const Color cardColor = Colors.white;
  static const Color borderColor = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF64748B);

  final TextEditingController _searchController = TextEditingController();
  late final AnimalRepository _repository;
  List<AnimalRecord> _animales = [];
  String _searchQuery = '';
  String? _error;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? const AnimalApiService();
    _searchController.addListener(_handleSearchChanged);
    _loadAnimals();
  }

  void _handleSearchChanged() {
    if (!mounted) return;
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _loadAnimals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final animals = await _repository.listAnimals();
      if (!mounted) return;
      setState(() {
        _animales = animals;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      _setLoadError(error.message);
    } on FormatException catch (error) {
      _setLoadError(error.message);
    } on Exception catch (error) {
      _setLoadError('No se pudieron cargar los animales: $error');
    }
  }

  void _setLoadError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  List<AnimalRecord> get _filteredAnimales {
    if (_searchQuery.isEmpty) return _animales;
    return _animales
        .where((animal) => animal.chapeta.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth >= 1000 ? 32.0 : 16.0;
            return SingleChildScrollView(
              padding: EdgeInsets.all(horizontalPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(constraints.maxWidth),
                      const SizedBox(height: 28),
                      _buildKpiMetricsRow(constraints.maxWidth),
                      const SizedBox(height: 32),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_error != null)
                        _buildLoadError()
                      else
                        _buildDataTableSection(context, constraints.maxWidth),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(double maxWidth) {
    return FeaturePageBanner(
      title: 'Módulo de Registro de Animales',
      subtitle: 'Control individual del ganado mediante chapeta única.',
      icon: Icons.pets_rounded,
      isCompact: maxWidth < 700,
    );
  }

  Widget _buildKpiMetricsRow(double maxWidth) {
    final cards = [
      _buildKpiCard(
        title: 'Total Animales',
        value: _isLoading ? '0' : '${_animales.length}',
        subtitle: 'Total Animales',
        icon: Icons.pets_rounded,
        iconBgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _buildKpiCard(
        title: 'Sincronizados',
        value: _isLoading ? '0' : '${_animales.length}',
        subtitle: 'Sincronizados',
        icon: Icons.cloud_done_rounded,
        iconBgColor: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
      ),
      _buildKpiCard(
        title: 'Pendientes Local',
        value: '0',
        subtitle: 'Pendientes Local',
        icon: Icons.cloud_off_rounded,
        iconBgColor: const Color(0xFFFFFBEB),
        iconColor: const Color(0xFFD97706),
      ),
    ];

    return FeatureMetricLayout(
      cards: cards,
      isCompact: maxWidth < 800,
      horizontalSpacing: 14,
      verticalSpacing: 12,
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return FeatureKpiCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      iconBgColor: iconBgColor,
      iconColor: iconColor,
      cardColor: cardColor,
      borderColor: borderColor,
      textColor: textMuted,
      valueColor: primaryColor,
    );
  }

  Widget _buildDataTableSection(BuildContext context, double maxWidth) {
    final animalesMostrados = _filteredAnimales;
    final isNarrow = maxWidth < 700;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isNarrow ? 16 : 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              if (isNarrow)
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Listado de Ganado Registrado',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                )
              else
                Text(
                  'Listado de Ganado Registrado',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _mostrarModalRegistrarAnimal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Registrar Animal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchField(),
          const SizedBox(height: 20),
          if (animalesMostrados.isEmpty)
            _buildEmptyState()
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(backgroundColor),
                dataRowMinHeight: 64,
                dataRowMaxHeight: 72,
                columnSpacing: 16,
                columns: [
                  _buildDataColumn('Chapeta', 110),
                  _buildDataColumn('Raza', 120),
                  _buildDataColumn('Sexo', 100),
                  _buildDataColumn('Finca', 150),
                  _buildDataColumn('Fecha Nac.', 110),
                  _buildDataColumn('Estado', 100),
                  _buildDataColumn('Acciones', 110),
                ],
                rows: animalesMostrados.asMap().entries.map((entry) {
                  final index = entry.key;
                  final animal = entry.value;
                  final isMacho = animal.sexo == 'Macho';
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          animal.chapeta,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      DataCell(_cellText(animal.raza, 120)),
                      DataCell(
                        Row(
                          children: [
                            Icon(
                              isMacho ? Icons.male : Icons.female,
                              color: isMacho
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFEC4899),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              animal.sexo,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(_cellText(animal.finca, 150)),
                      DataCell(
                          _cellText(_formatDate(animal.fechaNacimiento), 110)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            animal.estadoSincronizacion,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xFF2563EB),
                                size: 18,
                              ),
                              tooltip: 'Editar animal',
                              onPressed: () => _mostrarModalEditarAnimal(
                                  context, animal, index),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              tooltip: 'Eliminar animal',
                              onPressed: () =>
                                  _confirmarEliminarAnimal(context, index),
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

  DataColumn _buildDataColumn(String title, double width) {
    return DataColumn(
      label: SizedBox(width: width, child: _buildTableHeader(title)),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Buscar por chapeta...',
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: const Color(0xFF94A3B8),
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Colors.white70,
          size: 20,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.clear_rounded,
                  size: 18,
                  color: Colors.white70,
                ),
                onPressed: _searchController.clear,
                tooltip: 'Limpiar búsqueda',
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _cellText(String value, double width) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildTableHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF475569),
      ),
    );
  }

  Widget _buildEmptyState() {
    final message = _searchQuery.isEmpty
        ? 'No hay animales registrados en el sistema'
        : 'No se encontró ningún animal con la chapeta "$_searchQuery"';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: textMuted),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar los animales',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadAnimals,
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminarAnimal(BuildContext context, int index) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Animal'),
        content: const Text(
          '¿Estás seguro que deseas eliminar este registro de animal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _animales.removeAt(index);
              });
              _showMessage('Animal eliminado del registro.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarModalRegistrarAnimal(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final chapetaController = TextEditingController();
    final fechaController = TextEditingController();
    final pesoController = TextEditingController();

    String? razaSeleccionada = 'Holstein';
    String? sexoSeleccionado = 'Macho';
    DateTime? fechaNacimiento;

    try {
      final datos = await showDialog<Map<String, Object>>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.pets, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Registrar Animal',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      fontSize: 20,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              content: SizedBox(
                width: 580,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              controller: chapetaController,
                              label: 'Chapeta / ID Único *',
                              hint: 'Ej: 00123',
                              icon: Icons.sell_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Campo obligatorio';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF1E293B), fontSize: 14),
                              initialValue: razaSeleccionada,
                              dropdownColor: Colors.white,
                              decoration: _formDecoration('Raza *').copyWith(
                                prefixIcon: const Icon(Icons.dns_outlined,
                                    size: 18, color: accentColor),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'Holstein',
                                    child: Text('Holstein',
                                        style: TextStyle(color: primaryColor))),
                                DropdownMenuItem(
                                    value: 'Brahman',
                                    child: Text('Brahman',
                                        style: TextStyle(color: primaryColor))),
                                DropdownMenuItem(
                                    value: 'Gyr',
                                    child: Text('Gyr',
                                        style: TextStyle(color: primaryColor))),
                                DropdownMenuItem(
                                    value: 'Angus',
                                    child: Text('Angus',
                                        style: TextStyle(color: primaryColor))),
                              ],
                              onChanged: (v) =>
                                  setDialogState(() => razaSeleccionada = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: fechaController,
                              readOnly: true,
                              decoration:
                                  _formDecoration('Fecha de Nacimiento *')
                                      .copyWith(
                                prefixIcon: const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                    color: accentColor),
                                hintText: 'Seleccione fecha',
                              ),
                              validator: (_) => fechaNacimiento == null
                                  ? 'Campo obligatorio'
                                  : null,
                              onTap: () async {
                                final selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      fechaNacimiento ?? DateTime.now(),
                                  firstDate: DateTime(1950),
                                  lastDate: DateTime.now(),
                                );
                                if (selectedDate != null) {
                                  setDialogState(() {
                                    fechaNacimiento = selectedDate;
                                    fechaController.text =
                                        _formatDate(selectedDate);
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF1E293B), fontSize: 14),
                              initialValue: sexoSeleccionado,
                              dropdownColor: Colors.white,
                              decoration: _formDecoration('Sexo *').copyWith(
                                prefixIcon: const Icon(Icons.wc_outlined,
                                    size: 18, color: accentColor),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'Macho',
                                    child: Text('Macho',
                                        style: TextStyle(color: primaryColor))),
                                DropdownMenuItem(
                                    value: 'Hembra',
                                    child: Text('Hembra',
                                        style: TextStyle(color: primaryColor))),
                              ],
                              onChanged: (v) =>
                                  setDialogState(() => sexoSeleccionado = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: pesoController,
                        label: 'Peso actual (kg) *',
                        hint: 'Ej: 450',
                        icon: Icons.monitor_weight_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          final peso = double.tryParse(
                            (value ?? '').trim().replaceAll(',', '.'),
                          );
                          if (peso == null || peso <= 0) {
                            return 'Ingresa un peso válido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(dialogContext, {
                      'chapeta': chapetaController.text.trim(),
                      'raza': razaSeleccionada!,
                      'sexo': sexoSeleccionado!,
                      'fechaNacimiento': fechaNacimiento!,
                      'pesoKg': double.parse(
                        pesoController.text.trim().replaceAll(',', '.'),
                      ),
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Guardar Animal'),
                ),
              ],
            );
          },
        ),
      );

      if (!mounted || datos == null) return;
      setState(() {
        _isSaving = true;
      });
      final animal = await _repository.createAnimal(
        chapeta: datos['chapeta']! as String,
        raza: datos['raza']! as String,
        sexo: datos['sexo']! as String,
        fechaNacimiento: datos['fechaNacimiento']! as DateTime,
        pesoKg: datos['pesoKg']! as double,
      );
      if (!mounted) return;
      setState(() {
        _animales.insert(0, animal);
        _isSaving = false;
      });
      _showMessage('Animal registrado correctamente.');
    } on ApiException catch (error) {
      _finishSaveWithError(error.message);
    } on FormatException catch (error) {
      _finishSaveWithError(error.message);
    } on Exception catch (error) {
      _finishSaveWithError('No se pudo registrar el animal: $error');
    } finally {
      chapetaController.dispose();
      fechaController.dispose();
      pesoController.dispose();
    }
  }

  void _mostrarModalEditarAnimal(
      BuildContext context, AnimalRecord animal, int index) {
    final formKey = GlobalKey<FormState>();
    final chapetaController = TextEditingController(text: animal.chapeta);
    final fechaController =
        TextEditingController(text: _formatDate(animal.fechaNacimiento));
    final pesoController =
        TextEditingController(text: animal.pesoKg.toStringAsFixed(0));

    String razaSeleccionada = animal.raza;
    String sexoSeleccionado = animal.sexo;
    DateTime fechaNacimiento = animal.fechaNacimiento;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: primaryColor, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Editar Animal',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            controller: chapetaController,
                            label: 'Chapeta / ID Único *',
                            hint: 'Ej: 00123',
                            icon: Icons.sell_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Campo obligatorio';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF1E293B), fontSize: 14),
                            initialValue: razaSeleccionada,
                            dropdownColor: Colors.white,
                            decoration: _formDecoration('Raza *').copyWith(
                              prefixIcon: const Icon(Icons.dns_outlined,
                                  size: 18, color: accentColor),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Holstein',
                                  child: Text('Holstein',
                                      style: TextStyle(color: primaryColor))),
                              DropdownMenuItem(
                                  value: 'Brahman',
                                  child: Text('Brahman',
                                      style: TextStyle(color: primaryColor))),
                              DropdownMenuItem(
                                  value: 'Gyr',
                                  child: Text('Gyr',
                                      style: TextStyle(color: primaryColor))),
                              DropdownMenuItem(
                                  value: 'Angus',
                                  child: Text('Angus',
                                      style: TextStyle(color: primaryColor))),
                            ],
                            onChanged: (v) => setDialogState(
                                () => razaSeleccionada = v ?? razaSeleccionada),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: fechaController,
                            readOnly: true,
                            decoration: _formDecoration('Fecha de Nacimiento *')
                                .copyWith(
                              prefixIcon: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: accentColor),
                            ),
                            onTap: () async {
                              final selectedDate = await showDatePicker(
                                context: context,
                                initialDate: fechaNacimiento,
                                firstDate: DateTime(1950),
                                lastDate: DateTime.now(),
                              );
                              if (selectedDate != null) {
                                setDialogState(() {
                                  fechaNacimiento = selectedDate;
                                  fechaController.text =
                                      _formatDate(selectedDate);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF1E293B), fontSize: 14),
                            initialValue: sexoSeleccionado,
                            dropdownColor: Colors.white,
                            decoration: _formDecoration('Sexo *').copyWith(
                              prefixIcon: const Icon(Icons.wc_outlined,
                                  size: 18, color: accentColor),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Macho',
                                  child: Text('Macho',
                                      style: TextStyle(color: primaryColor))),
                              DropdownMenuItem(
                                  value: 'Hembra',
                                  child: Text('Hembra',
                                      style: TextStyle(color: primaryColor))),
                            ],
                            onChanged: (v) => setDialogState(
                                () => sexoSeleccionado = v ?? sexoSeleccionado),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(dialogContext);
                  setState(() {
                    _animales[index] = AnimalRecord(
                      id: animal.id,
                      chapeta: chapetaController.text.trim(),
                      raza: razaSeleccionada,
                      sexo: sexoSeleccionado,
                      fechaNacimiento: fechaNacimiento,
                      pesoKg:
                          double.tryParse(pesoController.text) ?? animal.pesoKg,
                    );
                  });
                  _showMessage('Datos del animal actualizados.');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Actualizar Animal'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _finishSaveWithError(String message) {
    if (!mounted) return;
    setState(() => _isSaving = false);
    _showMessage(message);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  InputDecoration _formDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF475569),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF94A3B8),
        fontSize: 13,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF1E293B),
        fontSize: 14,
      ),
      decoration: _formDecoration(label).copyWith(
        hintText: hint,
        prefixIcon:
            icon != null ? Icon(icon, size: 18, color: accentColor) : null,
      ),
    );
  }
}
