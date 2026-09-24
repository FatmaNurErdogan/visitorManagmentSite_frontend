import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/landing_screen.dart';
import 'screens/staff_shell.dart';
import 'screens/visitor_chat_screen.dart';
import 'services/auth_service.dart';
import 'services/theme_controller.dart';
import 'theme/app_theme.dart';

/// Uygulama içinden herhangi bir yerden (login olmuş/olmamış fark etmeksizin)
/// route push edebilmek için — deep link, o an ekranda AuthGate/StaffShell
/// hangisi varsa onun üstüne VisitorChatScreen'i açmak istiyor.
final rootNavigatorKey = GlobalKey<NavigatorState>();

class VizitApp extends StatefulWidget {
  const VizitApp({super.key});

  @override
  State<VizitApp> createState() => _VizitAppState();
}

class _VizitAppState extends State<VizitApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Uygulama zaten çalışırken gelen linkler.
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleLink);

    // Uygulama linkle soğuk açıldıysa (kapalıyken tıklandıysa).
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) _handleLink(initialUri);
  }

  void _handleLink(Uri uri) {
    // https://{domain}/visit/{token} → VisitorChatScreen. Başka path'leri
    // şimdilik yok sayıyoruz.
    final segments = uri.pathSegments;
    if (segments.length == 2 && segments[0] == 'visit') {
      final token = segments[1];
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => VisitorChatScreen(token: token)),
      );
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeController>().mode;

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Visit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
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
