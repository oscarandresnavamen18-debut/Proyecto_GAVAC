import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/dueno_models.dart';
import '../../data/services/dueno_api_service.dart';
import '../widgets/asignacion_fincas_tab.dart';
import '../widgets/gestion_administradores_tab.dart';
import '../widgets/gestion_fincas_dueno_tab.dart';
import '../widgets/gestion_permisos_tab.dart';
import '../widgets/gestion_usuarios_dueno_tab.dart';

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

class DuenoScreen extends StatefulWidget {
  final DuenoRepository repository;

  const DuenoScreen({
    super.key,
    this.repository = const DuenoApiService(),
  });

  @override
  State<DuenoScreen> createState() => _DuenoScreenState();
}

class _DuenoScreenState extends State<DuenoScreen> {
  static const Color primaryColor = Color(0xFF1A3A32);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color borderColor = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF64748B);

  int _selectedTabIndex = 0;
  Widget? _activeModal;

  DuenoSummary _summary = const DuenoSummary(
    totalFincas: 0,
    totalAdministradores: 0,
    totalUsuarios: 0,
    fincasAsignadasCount: 0,
  );
  List<FincaDuenoModel> _fincas = [];
  List<UsuarioDuenoModel> _usuarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _openModal(Widget modalWidget) {
    setState(() {
      _activeModal = modalWidget;
    });
  }

  void _closeModal() {
    setState(() {
      _activeModal = null;
    });
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      widget.repository.getSummary(),
      widget.repository.listFincas(),
      widget.repository.listAdministradores(),
      widget.repository.listUsuarios(),
    ]);
    if (!mounted) return;
    final summaryBackend = results[0] as DuenoSummary;
    final fincas = results[1] as List<FincaDuenoModel>;
    final admins = results[2] as List<AdministradorModel>;
    final usuarios = results[3] as List<UsuarioDuenoModel>;

    final calcFincas = fincas.length > summaryBackend.totalFincas
        ? fincas.length
        : summaryBackend.totalFincas;
    final calcAdmins = admins.length > summaryBackend.totalAdministradores
        ? admins.length
        : summaryBackend.totalAdministradores;
    final calcUsers = usuarios.length > summaryBackend.totalUsuarios
        ? usuarios.length
        : summaryBackend.totalUsuarios;
    final assignedCount = usuarios.where((u) => u.farmIds.isNotEmpty).length +
        admins.where((a) => a.farmIds.isNotEmpty).length;

    setState(() {
      _summary = DuenoSummary(
        totalFincas: calcFincas,
        totalAdministradores: calcAdmins,
        totalUsuarios: calcUsers,
        fincasAsignadasCount: assignedCount > summaryBackend.fincasAsignadasCount
            ? assignedCount
            : summaryBackend.fincasAsignadasCount,
      );
      _fincas = fincas;
      _usuarios = usuarios;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('es', 'CO'),
      delegates: const [
        _AlwaysMaterialLocalizationsDelegate(),
        DefaultWidgetsLocalizations.delegate,
      ],
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: backgroundColor,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 28),
                          _buildKpiMetricsRow(),
                          const SizedBox(height: 28),
                          _buildCustomTabSelector(),
                          const SizedBox(height: 24),
                          _buildActiveTabContent(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_activeModal != null) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeModal,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Center(
                child: Material(
                  type: MaterialType.transparency,
                  child: _activeModal!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: const AssetImage('assets/imagenes/imagenganado.png'),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {},
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              primaryColor.withValues(alpha: 0.95),
              primaryColor.withValues(alpha: 0.65),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.workspace_premium_outlined,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Módulo Dueño / Ganadero',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Control maestro de fincas, administradores, personal y permisos de acceso.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiMetricsRow() {
    final cards = [
      _buildKpiCard(
        title: 'Total Fincas',
        value: _isLoading ? '0' : '${_summary.totalFincas}',
        subtitle: 'Fincas Registradas',
        icon: Icons.agriculture_outlined,
        iconBgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _buildKpiCard(
        title: 'Administradores',
        value: _isLoading ? '0' : '${_summary.totalAdministradores}',
        subtitle: 'Admins Creados',
        icon: Icons.admin_panel_settings_outlined,
        iconBgColor: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
      ),
      _buildKpiCard(
        title: 'Total Usuarios',
        value: _isLoading ? '0' : '${_summary.totalUsuarios}',
        subtitle: 'Personal Activo',
        icon: Icons.people_outline,
        iconBgColor: const Color(0xFFFFFBEB),
        iconColor: const Color(0xFFD97706),
      ),
      _buildKpiCard(
        title: 'Fincas Asignadas',
        value: _isLoading ? '0' : '${_summary.fincasAsignadasCount}',
        subtitle: 'Asignaciones Activas',
        icon: Icons.link_outlined,
        iconBgColor: const Color(0xFFFEE2E2),
        iconColor: const Color(0xFFDC2626),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                cards[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
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

  Widget _buildCustomTabSelector() {
    final tabs = [
      {'icon': Icons.admin_panel_settings_outlined, 'label': 'Administradores'},
      {'icon': Icons.agriculture_outlined, 'label': 'Fincas'},
      {'icon': Icons.people_outline, 'label': 'Usuarios'},
      {'icon': Icons.link_outlined, 'label': 'Asignaciones'},
      {'icon': Icons.shield_outlined, 'label': 'Permisos por Módulo'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          final tab = tabs[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = index),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? primaryColor : borderColor,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tab['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return GestionAdministradoresTab(
          repository: widget.repository,
          fincas: _fincas,
          onRefresh: _loadAllData,
          onOpenModal: _openModal,
          onCloseModal: _closeModal,
        );
      case 1:
        return GestionFincasDuenoTab(
          repository: widget.repository,
          onRefresh: _loadAllData,
          onOpenModal: _openModal,
          onCloseModal: _closeModal,
        );
      case 2:
        return GestionUsuariosDuenoTab(
          repository: widget.repository,
          fincas: _fincas,
          onRefresh: _loadAllData,
          onOpenModal: _openModal,
          onCloseModal: _closeModal,
        );
      case 3:
        return AsignacionFincasTab(
          repository: widget.repository,
          fincas: _fincas,
          usuarios: _usuarios,
          onRefresh: _loadAllData,
        );
      case 4:
      default:
        return GestionPermisosTab(
          repository: widget.repository,
          usuarios: _usuarios,
          onRefresh: _loadAllData,
        );
    }
  }
}
