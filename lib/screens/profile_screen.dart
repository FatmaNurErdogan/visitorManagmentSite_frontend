import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/staff_member.dart';
import '../services/auth_service.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final themeController = context.watch<ThemeController>();
    final colors = context.vizitColors;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(22),
                boxShadow: colors.cardShadow,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: scheme.primary.withValues(alpha: 0.16),
                    child: Text(
                      _initials(auth.name),
                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.name ?? '', style: TextStyle(fontWeight: FontWeight.w700, color: colors.ink)),
                        const SizedBox(height: 2),
                        Text(auth.email ?? '', style: TextStyle(fontSize: 12.5, color: colors.soft)),
                        const SizedBox(height: 6),
                        Text(
                          StaffRole.label(auth.role ?? StaffRole.employee),
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: scheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'GÖRÜNÜM',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.soft, letterSpacing: 0.4),
            ),
            const SizedBox(height: 10),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Sistem')),
                ButtonSegment(value: ThemeMode.light, label: Text('Açık')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Koyu')),
              ],
              selected: {themeController.mode},
              onSelectionChanged: (selection) => context.read<ThemeController>().setMode(selection.first),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.read<AuthService>().logout(),
              child: const Text('Çıkış yap'),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters;
  }
}
