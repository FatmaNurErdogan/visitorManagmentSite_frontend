import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/landing_screen.dart';
import 'screens/staff_shell.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

class VizitApp extends StatelessWidget {
  const VizitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vizit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

/// Oturum durumuna göre personel alanı (StaffShell) ile giriş ekranı
/// (LandingScreen) arasında geçiş yapar. Login/Logout, `AuthService`
/// üzerinden `notifyListeners` ile buraya yansır — ayrıca bir navigasyon
/// çağrısına gerek yok.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return auth.isAuthenticated ? const StaffShell() : const LandingScreen();
  }
}
