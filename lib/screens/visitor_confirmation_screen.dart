import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import 'visitor_chat_screen.dart';

final _fullFormat = DateFormat('d MMMM, HH:mm', 'tr_TR');

class VisitorConfirmationScreen extends StatelessWidget {
  const VisitorConfirmationScreen({
    super.key,
    required this.visitorName,
    required this.hostName,
    required this.reason,
    required this.scheduledAt,
    required this.accessToken,
  });

  final String visitorName;
  final String hostName;
  final String reason;
  final DateTime scheduledAt;
  // Backend'de talep PENDING iken de sohbet zaten açık — host onayını
  // beklemeden ziyaretçi buradan direkt mesajlaşmaya başlayabilsin diye.
  final String accessToken;

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
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: colors.warnBg, shape: BoxShape.circle),
                  child: Icon(Icons.hourglass_top_rounded, color: colors.warnInk, size: 26),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Talebin iletildi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.ink),
              ),
              const SizedBox(height: 6),
              Text(
                '$hostName onayladığında haber vereceğiz. İstersen onay beklemeden şimdiden mesaj bırakabilirsin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: colors.soft),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: colors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(visitorName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: colors.ink)),
                    const SizedBox(height: 14),
                    _PassRow(label: 'Ziyaret edilen', value: hostName, colors: colors),
                    _PassRow(label: 'Tarih', value: _fullFormat.format(scheduledAt), colors: colors),
                    _PassRow(label: 'Neden', value: reason, colors: colors),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => VisitorChatScreen(token: accessToken)),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: Text('$hostName ile sohbet et'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Yeni Talep Oluştur'),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: Text('Ana sayfaya dön', style: TextStyle(color: scheme.primary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PassRow extends StatelessWidget {
  const _PassRow({required this.label, required this.value, required this.colors});

  final String label;
  final String value;
  final VizitColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontSize: 11.5, color: colors.soft)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
