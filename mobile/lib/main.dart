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
  ThemeMode _themeMode = ThemeMode.system;

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
        '/register': (context) => const RegisterScreen(), // <-- Agregado
        '/dashboard': (context) => const DashboardScreen(),
      },
      builder: (context, child) {
        return Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (overlayContext) {
                final isDarkMode =
                    Theme.of(overlayContext).brightness == Brightness.dark;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (child != null) child,
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: SafeArea(
                        child: Material(
                          elevation: 6,
                          shape: const CircleBorder(),
                          shadowColor: Colors.black.withValues(alpha: 0.18),
                          child: Tooltip(
                            message: isDarkMode
                                ? 'Cambiar a modo claro'
                                : 'Cambiar a modo oscuro',
                            child: IconButton.filledTonal(
                              onPressed: () {
                                setState(() {
                                  final darkMode =
                                      Theme.of(overlayContext).brightness ==
                                          Brightness.dark;
                                  _themeMode = darkMode
                                      ? ThemeMode.light
                                      : ThemeMode.dark;
                                });
                              },
                              style: IconButton.styleFrom(
                                fixedSize: const Size(48, 48),
                                shape: const CircleBorder(),
                              ),
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                transitionBuilder: (child, animation) =>
                                    RotationTransition(
                                  turns: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                ),
                                child: Icon(
                                  isDarkMode
                                      ? Icons.light_mode
                                      : Icons.dark_mode,
                                  key: ValueKey(isDarkMode),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
