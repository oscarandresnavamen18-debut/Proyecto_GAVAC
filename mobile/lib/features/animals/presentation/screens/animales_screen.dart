import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../data/services/animal_api_service.dart';

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
                      _buildHeader(context, constraints.maxWidth),
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

  Widget _buildHeader(BuildContext context, double maxWidth) {
    final isNarrow = maxWidth < 700;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HU-006: Registro de Animales',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isNarrow ? 22 : 28,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Consulta y registra el ganado asociado a tu finca.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
      ],
    );
    final button = ElevatedButton.icon(
      onPressed: _isSaving ? null : () => _mostrarModalRegistrarAnimal(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
      label: Text(
        'Registrar Animal',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading,
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: button),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: heading),
        const SizedBox(width: 20),
        button,
      ],
    );
  }

  Widget _buildKpiMetricsRow(double maxWidth) {
    final cards = [
      _buildKpiCard(
        title: 'Total Animales',
        value: _isLoading ? '—' : '${_animales.length}',
        subtitle: 'Registrados en tu finca',
        icon: Icons.pets_rounded,
        iconBgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _buildKpiCard(
        title: 'Sincronizados',
        value: _isLoading ? '—' : '${_animales.length}',
        subtitle: 'Guardados en la base de datos',
        icon: Icons.cloud_done_rounded,
        iconBgColor: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
      ),
      _buildKpiCard(
        title: 'Pendientes locales',
        value: '0',
        subtitle: 'Sin registros pendientes',
        icon: Icons.cloud_off_rounded,
        iconBgColor: const Color(0xFFFFFBEB),
        iconColor: const Color(0xFFD97706),
      ),
    ];

    if (maxWidth < 850) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            cards[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: cards[i]),
        ],
      ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textMuted,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
        ],
      ),
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
          if (isNarrow) ...[
            Text(
              'Listado de Ganado Registrado',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 14),
            _buildSearchField(),
          ] else
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Listado de Ganado Registrado',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                ),
                SizedBox(width: 280, child: _buildSearchField()),
              ],
            ),
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
                columnSpacing: 12,
                columns: [
                  _buildDataColumn('CHAPETA ÚNICA', 130),
                  _buildDataColumn('ESPECIE', 100),
                  _buildDataColumn('RAZA', 130),
                  _buildDataColumn('SEXO', 90),
                  _buildDataColumn('EDAD', 100),
                  _buildDataColumn('PESO', 100),
                  _buildDataColumn('ESTADO SINCRONIZACIÓN', 180),
                  _buildDataColumn('ACCIONES', 90),
                ],
                rows: animalesMostrados.map((animal) {
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 130,
                          child: Text(
                            animal.chapeta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      DataCell(_cellText(animal.especie, 100)),
                      DataCell(_cellText(animal.raza, 130)),
                      DataCell(_cellText(animal.sexo, 90)),
                      DataCell(_cellText(animal.edad, 100)),
                      DataCell(_cellText(animal.peso, 100)),
                      DataCell(_buildSyncBadge(animal.estadoSincronizacion)),
                      DataCell(
                        IconButton(
                          icon: const Icon(
                            Icons.visibility_outlined,
                            color: primaryColor,
                            size: 20,
                          ),
                          tooltip: 'Ver detalle del animal',
                          onPressed: () =>
                              _mostrarModalDetalleAnimal(context, animal),
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
      decoration: InputDecoration(
        hintText: 'Buscar por chapeta...',
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: textMuted,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: primaryColor,
          size: 20,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.clear_rounded,
                  size: 18,
                  color: textMuted,
                ),
                onPressed: _searchController.clear,
                tooltip: 'Limpiar búsqueda',
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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
        ? 'Aún no hay animales registrados en tu finca.'
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: Color(0xFFB45309), size: 36),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar los animales',
              style: GoogleFonts.plusJakartaSans(
                color: primaryColor,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF475569),
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

  Widget _buildSyncBadge(String estado) {
    final isSynced = estado == 'Sincronizado';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isSynced ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isSynced ? const Color(0xFF059669) : const Color(0xFFD97706),
        ),
      ),
    );
  }

  void _mostrarModalDetalleAnimal(BuildContext context, AnimalRecord animal) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  const Icon(Icons.pets_rounded, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ficha del Animal',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    'Chapeta: ${animal.chapeta}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(color: borderColor),
                const SizedBox(height: 12),
                _buildDetailRow(
                    'Especie', animal.especie, Icons.category_outlined),
                _buildDetailRow('Raza', animal.raza, Icons.dns_outlined),
                _buildDetailRow('Sexo', animal.sexo, Icons.wc_outlined),
                _buildDetailRow('Edad', animal.edad, Icons.cake_outlined),
                _buildDetailRow(
                  'Peso',
                  animal.peso,
                  Icons.monitor_weight_outlined,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Estado:',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                        child: _buildSyncBadge(animal.estadoSincronizacion)),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cerrar',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: primaryColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarModalRegistrarAnimal(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final chapetaController = TextEditingController();
    final razaController = TextEditingController();
    final fechaController = TextEditingController();
    final pesoController = TextEditingController();
    String? sexoSeleccionado;
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
              scrollable: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Registrar animal',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  fontSize: 20,
                ),
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.62,
                ),
                child: SizedBox(
                  width: 500,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Especie: Bovino',
                              style: GoogleFonts.plusJakartaSans(
                                color: primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: chapetaController,
                          label: 'Chapeta / arete',
                          hint: 'Ej. CH-1027',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa la chapeta del animal';
                            }
                            final exists = _animales.any(
                              (animal) =>
                                  animal.chapeta.toLowerCase() ==
                                  value.trim().toLowerCase(),
                            );
                            return exists
                                ? 'Esta chapeta ya está registrada'
                                : null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildFormField(
                          controller: razaController,
                          label: 'Raza',
                          hint: 'Ej. Brahman, Holstein',
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: sexoSeleccionado,
                          dropdownColor: Colors.white,
                          iconEnabledColor: accentColor,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF1E293B),
                            fontSize: 14,
                          ),
                          decoration: _formDecoration('Sexo'),
                          items: const [
                            DropdownMenuItem(
                              value: 'Macho',
                              child: Text(
                                'Macho',
                                style: TextStyle(color: primaryColor),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Hembra',
                              child: Text(
                                'Hembra',
                                style: TextStyle(color: primaryColor),
                              ),
                            ),
                          ],
                          validator: (value) =>
                              value == null ? 'Selecciona el sexo' : null,
                          onChanged: (value) {
                            setDialogState(() => sexoSeleccionado = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: fechaController,
                          readOnly: true,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF1E293B),
                            fontSize: 14,
                          ),
                          decoration:
                              _formDecoration('Fecha de nacimiento').copyWith(
                            hintText: 'Selecciona la fecha',
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: accentColor,
                            ),
                          ),
                          validator: (_) => fechaNacimiento == null
                              ? 'Selecciona la fecha de nacimiento'
                              : null,
                          onTap: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: fechaNacimiento ?? DateTime.now(),
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                              builder: (context, child) => Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: primaryColor,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Color(0xFF1E293B),
                                  ),
                                ),
                                child: child!,
                              ),
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
                        const SizedBox(height: 14),
                        _buildFormField(
                          controller: pesoController,
                          label: 'Peso actual (kg)',
                          hint: 'Ej. 450',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa el peso';
                            }
                            final weight = double.tryParse(
                              value.trim().replaceAll(',', '.'),
                            );
                            if (weight == null || weight <= 0) {
                              return 'Ingresa un peso válido mayor que cero';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(dialogContext, {
                            'chapeta': chapetaController.text.trim(),
                            'raza': razaController.text.trim(),
                            'sexo': sexoSeleccionado!,
                            'fechaNacimiento': fechaNacimiento!,
                            'pesoKg': double.parse(
                              pesoController.text.trim().replaceAll(',', '.'),
                            ),
                          });
                        },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar animal'),
                ),
              ],
            );
          },
        ),
      );

      if (!mounted || datos == null) return;
      setState(() {
        _isSaving = true;
        _error = null;
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
      razaController.dispose();
      fechaController.dispose();
      pesoController.dispose();
    }
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

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

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
      decoration: _formDecoration(label).copyWith(hintText: hint),
    );
  }
}
