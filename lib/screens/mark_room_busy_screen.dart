import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/meeting_room.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

final _dateTimeFormat = DateFormat('d MMMM, HH:mm', 'tr_TR');

/// ADMIN'in bir odayı, herhangi bir ziyaretten bağımsız olarak, gelecekteki
/// istediği bir tarih/saat aralığı için doğrudan meşgul olarak işaretlemesi
/// — bkz. backend'deki POST /api/mobile/rooms/[id]/bookings.
class MarkRoomBusyScreen extends StatefulWidget {
  const MarkRoomBusyScreen({super.key, required this.room});

  final MeetingRoom room;

  @override
  State<MarkRoomBusyScreen> createState() => _MarkRoomBusyScreenState();
}

class _MarkRoomBusyScreenState extends State<MarkRoomBusyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeCtrl = TextEditingController();

  late DateTime _startTime;
  late DateTime _endTime;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startTime = DateTime(now.year, now.month, now.day, now.hour).add(const Duration(hours: 1));
    _endTime = _startTime.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (!_endTime.isAfter(_startTime)) {
        _endTime = _startTime.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEndTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endTime,
      firstDate: _startTime,
      lastDate: _startTime.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _endTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_endTime.isAfter(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitiş saati başlangıçtan sonra olmalı.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await context.read<AuthService>().client.post('/rooms/${widget.room.id}/bookings', body: {
        'purpose': _purposeCtrl.text.trim(),
        'startTime': _startTime.toUtc().toIso8601String(),
        'endTime': _endTime.toUtc().toIso8601String(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vizitColors;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.room.name} — Meşgul işaretle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Bu odayı belirli bir tarih/saat aralığında, bir ziyaretten bağımsız olarak meşgul olarak işaretle (ör. iç toplantı).',
              style: TextStyle(fontSize: 13, color: colors.soft),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _purposeCtrl,
              decoration: const InputDecoration(labelText: 'Açıklama', hintText: 'ör. Haftalık ekip toplantısı'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu alan' : null,
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _pickStartTime,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Başlangıç saati'),
                isEmpty: false,
                child: Text(_dateTimeFormat.format(_startTime), style: TextStyle(color: colors.ink)),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _pickEndTime,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Bitiş saati'),
                isEmpty: false,
                child: Text(_dateTimeFormat.format(_endTime), style: TextStyle(color: colors.ink)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Meşgul olarak işaretle'),
            ),
          ],
        ),
      ),
    );
  }
}
