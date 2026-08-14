import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/meeting_room.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

final _dateTimeFormat = DateFormat('d MMMM, HH:mm', 'tr_TR');

/// Bağımsız bir toplantı odası rezervasyonu talep etme ekranı — ziyaret
/// onayından tamamen ayrı (bkz. backend'deki src/actions/rooms.ts). Oda o
/// saatte doluysa talep reddedilir, kullanıcı farklı bir saat seçmek zorunda
/// kalır; boşsa talep PENDING olarak oluşur ve admin onayını bekler.
class RoomBookingScreen extends StatefulWidget {
  const RoomBookingScreen({super.key, required this.room});

  final MeetingRoom room;

  @override
  State<RoomBookingScreen> createState() => _RoomBookingScreenState();
}

class _RoomBookingScreenState extends State<RoomBookingScreen> {
  final _purposeCtrl = TextEditingController();
  late DateTime _start;
  late DateTime _end;
  bool _submitting = false;
  String? _errorMessage;

  ApiClient get _client => context.read<AuthService>().client;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, now.day, now.hour + 1);
    _end = _start.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial, DateTime firstDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: initial.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickStart() async {
    final picked = await _pickDateTime(_start, DateTime.now());
    if (picked == null) return;
    setState(() {
      _start = picked;
      if (!_end.isAfter(_start)) {
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    final picked = await _pickDateTime(_end, _start.add(const Duration(minutes: 1)));
    if (picked == null) return;
    setState(() => _end = picked);
  }

  Future<void> _submit() async {
    final purpose = _purposeCtrl.text.trim();
    if (purpose.isEmpty) {
      setState(() => _errorMessage = 'Lütfen toplantının amacını yaz.');
      return;
    }
    if (!_end.isAfter(_start)) {
      setState(() => _errorMessage = 'Bitiş saati başlangıçtan sonra olmalı.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await _client.post('/rooms/${widget.room.id}/book', body: {
        'purpose': purpose,
        'startTime': _start.toUtc().toIso8601String(),
        'endTime': _end.toUtc().toIso8601String(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      // Backend hata mesajları İngilizce (web arayüzü İngilizce) — burada en
      // sık karşılaşılan "oda o saatte dolu" durumunu Türkçeye çeviriyoruz,
      // diğerleri (ör. "amaç zorunlu") olduğu gibi gösteriliyor.
      if (!mounted) return;
      final message = friendlyErrorMessage(e);
      setState(() => _errorMessage = message.contains('already booked')
          ? 'Bu oda o saatte dolu. Lütfen farklı bir saat seç.'
          : message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vizitColors;
    final upcoming = widget.room.bookings;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.room.name} — Rezervasyon')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (upcoming.isNotEmpty) ...[
            Text(
              'Dolu saatler',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.soft),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colors.field, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: upcoming
                    .map(
                      (b) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          '${_dateTimeFormat.format(b.startTime)} – ${DateFormat('HH:mm').format(b.endTime)}',
                          style: TextStyle(fontSize: 12.5, color: colors.ink),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
          TextField(
            controller: _purposeCtrl,
            decoration: const InputDecoration(labelText: 'Amaç'),
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: _pickStart,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Başlangıç'),
              child: Text(_dateTimeFormat.format(_start), style: TextStyle(color: colors.ink)),
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: _pickEnd,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Bitiş'),
              child: Text(_dateTimeFormat.format(_end), style: TextStyle(color: colors.ink)),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: TextStyle(color: colors.dangerInk, fontSize: 12.5)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Rezervasyon Talep Et'),
          ),
          const SizedBox(height: 8),
          Text(
            'Oda bu saatte doluysa talebin oluşturulamaz, farklı bir saat seçmen istenir. Boşsa admin onayını bekler.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: colors.soft),
          ),
        ],
      ),
    );
  }
}
