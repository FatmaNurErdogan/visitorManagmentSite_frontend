import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'visitor_request_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vizitColors;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: colors.field, shape: BoxShape.circle),
                child: Icon(Icons.badge_outlined, color: scheme.primary, size: 30),
              ),
              const SizedBox(height: 20),
              Text('Vizit', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: colors.ink)),
              const SizedBox(height: 6),
              Text(
                'Ofis ziyaretçi ve personel giriş sistemi',
                style: TextStyle(fontSize: 14.5, color: colors.soft),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VisitorRequestScreen()),
                ),
                child: const Text('Ziyaretçiyim'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Personelim'),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
