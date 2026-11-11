import 'package:flutter/material.dart';
import 'core/theme/gavac_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';

void main() {
  runApp(const GAVACApp());
}

class GAVACApp extends StatefulWidget {
  const GAVACApp({super.key});

  @override
  State<GAVACApp> createState() => _GAVACAppState();
}

class _GAVACAppState extends State<GAVACApp> {
  final ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GAVAC - Gestión Ganadera',
      debugShowCheckedModeBanner: false,
      theme: GavacTheme.lightTheme,
      darkTheme: GavacTheme.darkTheme,
      themeMode: _themeMode,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
