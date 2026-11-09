import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modelo de datos para la HU-006 (Registro de Animales).
class AnimalRecord {
  final String id;
  final String chapeta;
  final String especie;
  final String raza;
  final String sexo;
  final String edad;
  final String peso;
  final String estadoSincronizacion;

  const AnimalRecord({
    required this.id,
    required this.chapeta,
    required this.especie,
    required this.raza,
    required this.sexo,
    required this.edad,
    required this.peso,
    required this.estadoSincronizacion,
  });
}

class AnimalesScreen extends StatefulWidget {
  final String totalAnimales;
  final String sincronizadosCount;
  final String pendientesCount;
  final List<AnimalRecord> animales;

  /// El widget padre debe guardar el registro y actualizar su listado.
  final Function(Map<String, String>)? onGuardarAnimal;

  const AnimalesScreen({
    super.key,
    this.totalAnimales = '3',
    this.sincronizadosCount = '2',
    this.pendientesCount = '1',
    this.animales = const [
      AnimalRecord(
        id: '1',
        chapeta: 'CH-1024',
        especie: 'Bovino',
        raza: 'Brahman',
        sexo: 'Macho',
        edad: '24 meses',
        peso: '450 kg',
        estadoSincronizacion: 'Sincronizado',
      ),
      AnimalRecord(
        id: '2',
        chapeta: 'CH-1025',
        especie: 'Bovino',
        raza: 'Holstein',
        sexo: 'Hembra',
        edad: '18 meses',
        peso: '380 kg',
        estadoSincronizacion: 'Sincronizado',
      ),
      AnimalRecord(
        id: '3',
        chapeta: 'CH-1026',
        especie: 'Bovino',
        raza: 'Gyr',
        sexo: 'Hembra',
        edad: '30 meses',
        peso: '420 kg',
        estadoSincronizacion: 'Pendiente Local',
      ),
    ],
    this.onGuardarAnimal,
  });

  @override
  State<AnimalesScreen> createState() => _AnimalesScreenState();
}

class _AnimalesScreenState extends State<AnimalesScreen> {
  static const Color primaryColor = Color(0xFF1A3A32);
  static const Color accentColor = Color(0xFF2E5A4D);
  static const Color backgroundColor = Color(0xFFF7F9F7);
  static const Color cardColor = Colors.white;
  static const Color borderColor = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF94A3B8);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  void _handleSearchChanged() {
    if (!mounted) return;
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
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
    if (_searchQuery.isEmpty) return widget.animales;
    return widget.animales
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
          'Control individual del ganado mediante chapeta única y sincronización offline/online.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
      ],
    );
    final button = ElevatedButton.icon(
      onPressed: () => _mostrarModalRegistrarAnimal(context),
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
        value: widget.totalAnimales,
        subtitle: 'Inventario general activo',
        icon: Icons.pets_rounded,
        iconBgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _buildKpiCard(
        title: 'Sincronizados',
        value: widget.sincronizadosCount,
        subtitle: 'Actualizados en servidor',
        icon: Icons.cloud_done_rounded,
        iconBgColor: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
      ),
      _buildKpiCard(
        title: 'Pendientes Local',
        value: widget.pendientesCount,
        subtitle: 'A la espera de conexión',
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                columnSpacing: 22,
                columns: [
                  _buildDataColumn('CHAPETA ÚNICA'),
                  _buildDataColumn('ESPECIE'),
                  _buildDataColumn('RAZA'),
                  _buildDataColumn('SEXO'),
                  _buildDataColumn('EDAD'),
                  _buildDataColumn('PESO'),
                  _buildDataColumn('ESTADO SINCRONIZACIÓN'),
                  _buildDataColumn('ACCIONES'),
                ],
                rows: animalesMostrados.map((animal) {
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
                      DataCell(_cellText(animal.especie)),
                      DataCell(_cellText(animal.raza)),
                      DataCell(_cellText(animal.sexo)),
                      DataCell(_cellText(animal.edad)),
                      DataCell(_cellText(animal.peso)),
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

  DataColumn _buildDataColumn(String title) {
    return DataColumn(label: _buildTableHeader(title));
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

  Widget _cellText(String value) {
    return Text(
      value,
      style: GoogleFonts.plusJakartaSans(fontSize: 14),
    );
  }

  Widget _buildTableHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: textMuted,
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
    final especieController = TextEditingController(text: 'Bovino');
    final razaController = TextEditingController();
    final edadController = TextEditingController();
    final pesoController = TextEditingController();
    String? sexoSeleccionado;

    try {
      final datos = await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                'Registrar Nuevo Animal (HU-006)',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFormField(
                          controller: chapetaController,
                          label: 'Chapeta / Arete único',
                          hint: 'Ej. CH-1027',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa la chapeta del animal';
                            }
                            final exists = widget.animales.any(
                              (animal) =>
                                  animal.chapeta.toLowerCase() ==
                                  value.trim().toLowerCase(),
                            );
                            if (exists)
                              // ignore: curly_braces_in_flow_control_structures
                              return 'Esta chapeta ya está registrada';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildFormField(
                          controller: especieController,
                          label: 'Especie',
                          hint: 'Ej. Bovino, Bufalino',
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 12),
                        _buildFormField(
                          controller: razaController,
                          label: 'Raza',
                          hint: 'Ej. Brahman, Holstein',
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: sexoSeleccionado,
                          decoration: _formDecoration('Sexo'),
                          items: const [
                            DropdownMenuItem(
                                value: 'Macho', child: Text('Macho')),
                            DropdownMenuItem(
                                value: 'Hembra', child: Text('Hembra')),
                          ],
                          validator: (value) =>
                              value == null ? 'Selecciona el sexo' : null,
                          onChanged: (value) {
                            setDialogState(() => sexoSeleccionado = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildFormField(
                          controller: edadController,
                          label: 'Edad',
                          hint: 'Ej. 24 meses',
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 12),
                        _buildFormField(
                          controller: pesoController,
                          label: 'Peso (kg)',
                          hint: 'Ej. 450',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa el peso';
                            }
                            final peso = double.tryParse(
                              value.trim().replaceAll(',', '.'),
                            );
                            if (peso == null || peso <= 0) {
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: textMuted,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(dialogContext, {
                      'chapeta': chapetaController.text.trim(),
                      'especie': especieController.text.trim(),
                      'raza': razaController.text.trim(),
                      'sexo': sexoSeleccionado!,
                      'edad': edadController.text.trim(),
                      'peso':
                          '${pesoController.text.trim().replaceAll(',', '.')} kg',
                      'estadoSincronizacion': 'Pendiente Local',
                    });
                  },
                  child: Text(
                    'Guardar Animal',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      if (!mounted || datos == null) return;

      final callback = widget.onGuardarAnimal;
      if (callback == null) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Formulario validado, pero falta conectar onGuardarAnimal en el widget padre.',
            ),
          ),
        );
        return;
      }

      callback(datos);
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Datos enviados al componente padre. El registro aún debe persistirse en la aplicación.',
          ),
        ),
      );
    } finally {
      chapetaController.dispose();
      especieController.dispose();
      razaController.dispose();
      edadController.dispose();
      pesoController.dispose();
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  InputDecoration _formDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
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
      decoration: _formDecoration(label).copyWith(hintText: hint),
    );
  }
}
