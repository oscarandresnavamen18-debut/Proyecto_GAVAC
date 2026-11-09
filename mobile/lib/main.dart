import 'package:flutter/material.dart';
import 'core/theme/gavac_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/dashboard_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';

void main() {
  runApp(const GAVACApp());
}

class GAVACApp extends StatelessWidget {
  const GAVACApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GAVAC - Gestión Ganadera',
      debugShowCheckedModeBanner: false,
      theme: GavacTheme.lightTheme,
      darkTheme: GavacTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(), // <-- Agregado
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
