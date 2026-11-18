import 'package:material_ui/material_ui.dart';

import 'core/routing/app_routes.dart';
import 'core/session/app_session.dart';
import 'core/theme/gavac_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isLoggedIn = false;
  try {
    isLoggedIn = await AppSession.tryRestoreSession();
  } catch (_) {}
  runApp(GAVACApp(initialRoute: isLoggedIn ? AppRoutes.dashboard : AppRoutes.initial));
}

class GAVACApp extends StatelessWidget {
  const GAVACApp({super.key, this.initialRoute = AppRoutes.initial});

  final String initialRoute;

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
      initialRoute: initialRoute,
      routes: AppRoutes.routes,
    );
  }
}
