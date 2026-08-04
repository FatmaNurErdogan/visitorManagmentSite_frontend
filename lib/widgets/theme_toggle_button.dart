import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/theme_controller.dart';

/// Giriş yapmamış (ziyaretçi) ekranlarda da tema değiştirebilmek için —
/// dokununca Sistem → Açık → Koyu → Sistem sırasıyla döner.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();

    final (icon, tooltip) = switch (controller.mode) {
      ThemeMode.system => (Icons.brightness_auto_outlined, 'Tema: Sistem'),
      ThemeMode.light => (Icons.light_mode_outlined, 'Tema: Açık'),
      ThemeMode.dark => (Icons.dark_mode_outlined, 'Tema: Koyu'),
    };

    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () {
        const order = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
        final next = order[(order.indexOf(controller.mode) + 1) % order.length];
        context.read<ThemeController>().setMode(next);
      },
    );
  }
}
