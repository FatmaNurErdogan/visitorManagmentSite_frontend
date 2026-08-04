import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bir listenin boş olduğu durumlarda gösterilen, katmanlı daire
/// illüstrasyonuyla süslenmiş sıcak boş durum kartı.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.vizitColors;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 108,
            height: 108,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(decoration: BoxDecoration(color: colors.field, shape: BoxShape.circle)),
                ),
                Positioned(
                  top: 12,
                  left: 20,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(color: colors.chipBg.withValues(alpha: 0.8), shape: BoxShape.circle),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 10,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: colors.acceptBg.withValues(alpha: 0.85), shape: BoxShape.circle),
                  ),
                ),
                Positioned.fill(
                  child: Center(child: Icon(icon, color: scheme.primary, size: 30)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: colors.ink),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: colors.soft, height: 1.5),
          ),
        ],
      ),
    );
  }
}
