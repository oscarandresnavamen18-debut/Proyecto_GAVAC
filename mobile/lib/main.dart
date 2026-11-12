import 'package:flutter/material.dart';
import 'core/theme/gavac_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';

void main() {
  runApp(const GAVACApp());
}

// 1. Convertimos GAVACApp en un StatefulWidget para recordar si el tema es claro u oscuro
class GAVACApp extends StatefulWidget {
  const GAVACApp({super.key});

  @override
  State<GAVACApp> createState() => _GAVACAppState();
}

class _GAVACAppState extends State<GAVACApp> {
  // Estado inicial del tema (puedes cambiarlo a ThemeMode.dark si prefieres que arranque oscuro)
  ThemeMode _themeMode = ThemeMode.light;

  // Función pública para alternar el tema que se puede compartir con tus pantallas
  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GAVAC - Gestión Ganadera',
      debugShowCheckedModeBanner: false,
      theme: GavacTheme.lightTheme,
      darkTheme: GavacTheme.darkTheme,
      themeMode: _themeMode, // Usamos la variable de estado aquí
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }

  // Método estático opcional por si quieres invocar el cambio de tema desde cualquier pantalla hijos
  static _GAVACAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_GAVACAppState>();
}
