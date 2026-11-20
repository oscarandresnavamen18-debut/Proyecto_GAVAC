import '../../../../core/network/api_client.dart';
import '../../../../core/session/app_session.dart';

/// Indicadores del inicio para la finca activa.
class DashboardSummary {
  const DashboardSummary({
    this.farmName,
    this.totalAnimales = 0,
    this.hembras = 0,
    this.machos = 0,
    this.pesoPromedioKg,
    this.animalesEnTratamiento = 0,
    this.vacunasPorVencer = 0,
    this.vacunasVencidas = 0,
    this.vacasGestantes = 0,
    this.partosProximos = 0,
    this.lecheLitros30Dias = 0,
    this.lechePromedioOrdeno,
    this.insumosBajoMinimo = 0,
    this.alertas = 0,
  });

  factory DashboardSummary.fromJson(
    Map<String, dynamic> json,
  ) => DashboardSummary(
    farmName: json['farm_name'] as String?,
    totalAnimales: json['total_animales'] as int? ?? 0,
    hembras: json['hembras'] as int? ?? 0,
    machos: json['machos'] as int? ?? 0,
    pesoPromedioKg: (json['peso_promedio_kg'] as num?)?.toDouble(),
    animalesEnTratamiento: json['animales_en_tratamiento'] as int? ?? 0,
    vacunasPorVencer: json['vacunas_por_vencer'] as int? ?? 0,
    vacunasVencidas: json['vacunas_vencidas'] as int? ?? 0,
    vacasGestantes: json['vacas_gestantes'] as int? ?? 0,
    partosProximos: json['partos_proximos'] as int? ?? 0,
    lecheLitros30Dias: (json['leche_litros_30_dias'] as num?)?.toDouble() ?? 0,
    lechePromedioOrdeno: (json['leche_promedio_ordeno'] as num?)?.toDouble(),
    insumosBajoMinimo: json['insumos_bajo_minimo'] as int? ?? 0,
    alertas: json['alertas'] as int? ?? 0,
  );

  final String? farmName;
  final int totalAnimales;
  final int hembras;
  final int machos;
  final double? pesoPromedioKg;
  final int animalesEnTratamiento;
  final int vacunasPorVencer;
  final int vacunasVencidas;
  final int vacasGestantes;
  // Partos esperados en los próximos 30 días.
  final int partosProximos;
  final double lecheLitros30Dias;
  final double? lechePromedioOrdeno;
  final int insumosBajoMinimo;
  final int alertas;
}

abstract interface class DashboardRepository {
  Future<DashboardSummary> summary();
}

class DashboardApiService implements DashboardRepository {
  const DashboardApiService();

  @override
  Future<DashboardSummary> summary() async {
    final token = AppSession.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException(401, 'Inicia sesión para ver el resumen.');
    }
    return DashboardSummary.fromJson(
      await ApiClient.get('/api/v1/dashboard', token: token)
          as Map<String, dynamic>,
    );
  }
}
