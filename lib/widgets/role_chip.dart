import 'package:flutter/material.dart';

import '../models/staff_member.dart';
import '../theme/app_theme.dart';

class RoleChip extends StatelessWidget {
  const RoleChip({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final colors = context.vizitColors;
    final primary = Theme.of(context).colorScheme.primary;

    final (bg, ink) = switch (role) {
      StaffRole.admin => (colors.dangerBg, colors.dangerInk),
      StaffRole.receptionist => (colors.acceptBg, colors.acceptInk),
      _ => (primary.withValues(alpha: 0.16), primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        StaffRole.label(role).toUpperCase(),
        style: TextStyle(color: ink, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.3),
      ),
    );
  }
}
