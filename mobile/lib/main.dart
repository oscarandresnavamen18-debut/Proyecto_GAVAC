import 'package:material_ui/material_ui.dart';

import 'core/routing/app_routes.dart';
import 'core/theme/gavac_theme.dart';

void main() {
  runApp(const GAVACApp());
}

class GAVACApp extends StatelessWidget {
  const GAVACApp({super.key});

  /// Español de Colombia: calendarios, meses y botones del sistema.
  static const locale = Locale('es', 'CO');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GAVAC - Gestión Ganadera',
      debugShowCheckedModeBanner: false,
      theme: GavacTheme.lightTheme,
      locale: locale,
      supportedLocales: const [locale, Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      initialRoute: AppRoutes.initial,
      routes: AppRoutes.routes,
    );
  }
}
