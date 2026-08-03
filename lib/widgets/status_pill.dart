import 'package:flutter/material.dart';

import '../models/visit.dart';
import '../theme/app_theme.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = context.vizitColors;
    final primary = Theme.of(context).colorScheme.primary;

    late final Color bg;
    late final Color ink;
    switch (status) {
      case VisitStatus.pending:
        bg = colors.warnBg;
        ink = colors.warnInk;
        break;
      case VisitStatus.accepted:
        bg = colors.acceptBg;
        ink = colors.acceptInk;
        break;
      case VisitStatus.checkedIn:
        bg = primary.withValues(alpha: 0.16);
        ink = primary;
        break;
      case VisitStatus.rejected:
        bg = colors.dangerBg;
        ink = colors.dangerInk;
        break;
      default:
        bg = colors.field;
        ink = colors.soft;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        VisitStatus.label(status),
        style: TextStyle(color: ink, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.3),
      ),
    );
  }
}
