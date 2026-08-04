import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/visit.dart';
import '../theme/app_theme.dart';
import 'status_pill.dart';

final _timeFormat = DateFormat('HH:mm', 'tr_TR');
final _dateFormat = DateFormat('d MMM', 'tr_TR');

class VisitCard extends StatelessWidget {
  const VisitCard({
    super.key,
    required this.visit,
    this.subtitle,
    this.showReason = false,
    this.actions,
  });

  final Visit visit;
  final String? subtitle;
  final bool showReason;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.vizitColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  visit.visitor.name,
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colors.ink),
                ),
              ),
              StatusPill(status: visit.status),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: TextStyle(fontSize: 11.5, color: colors.soft)),
          ],
          if (showReason) ...[
            const SizedBox(height: 8),
            Text(visit.visitReason, style: TextStyle(fontSize: 12, color: colors.soft)),
          ],
          const SizedBox(height: 6),
          Text(
            '${_dateFormat.format(visit.scheduledAt)} · ${_timeFormat.format(visit.scheduledAt)}',
            style: TextStyle(fontSize: 11, color: colors.soft, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          if (visit.checkedInAt != null) ...[
            const SizedBox(height: 3),
            Text(
              visit.checkedOutAt != null
                  ? 'Giriş ${_timeFormat.format(visit.checkedInAt!)} · Çıkış ${_timeFormat.format(visit.checkedOutAt!)}'
                  : 'Giriş ${_timeFormat.format(visit.checkedInAt!)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.acceptInk,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
          if (actions != null) ...[
            const SizedBox(height: 12),
            actions!,
          ],
        ],
      ),
    );
  }
}
