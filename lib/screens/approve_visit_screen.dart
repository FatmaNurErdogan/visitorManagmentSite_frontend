import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/meeting_room.dart';
import '../models/staff_member.dart';
import '../models/visit.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/async_state.dart';

final _dateTimeFormat = DateFormat('d MMMM, HH:mm', 'tr_TR');

/// Bir ziyareti onaylamak artık bir toplantı odası seçmeyi gerektiriyor —
/// bkz. backend'deki src/actions/rooms.ts. ADMIN için onay anında verilir;
/// EMPLOYEE (host) için bir oda talebi (bekleyen ticket) oluşturur, ziyaret
/// ancak bir admin bu talebi onaylayınca kabul edilmiş sayılır.
class ApproveVisitScreen extends StatefulWidget {
  const ApproveVisitScreen({super.key, required this.visit});

  final Visit visit;

  @override
  State<ApproveVisitScreen> createState() => _ApproveVisitScreenState();
}

class _ApproveVisitScreenState extends State<ApproveVisitScreen> {
  late Future<List<MeetingRoom>> _roomsFuture;
  MeetingRoom? _selectedRoom;
  late DateTime _endTime;
  bool _submitting = false;

  ApiClient get _client => context.read<AuthService>().client;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _loadRooms();
    _endTime = widget.visit.scheduledAt.add(const Duration(hours: 1));
  }

  Future<List<MeetingRoom>> _loadRooms() async {
    final data = await _client.get('/rooms') as Map<String, dynamic>;
    return (data['rooms'] as List<dynamic>).map((json) => MeetingRoom.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> _pickEndTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endTime,
      firstDate: widget.visit.scheduledAt,
      lastDate: widget.visit.scheduledAt.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    if (!mounted) return;
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
    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir oda seç.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await _client.post('/visits/${widget.visit.id}/approve', body: {
        'roomId': _selectedRoom!.id,
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
    final isAdmin = context.watch<AuthService>().role == StaffRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Ziyareti onayla')),
      body: AsyncStateBuilder<List<MeetingRoom>>(
        future: _roomsFuture,
        onRetry: () => setState(() {
          _roomsFuture = _loadRooms();
        }),
        builder: (context, rooms) {
          if (rooms.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Henüz toplantı odası yok — onaylamadan önce bir yöneticinin oda eklemesi gerekiyor.',
                style: TextStyle(color: colors.soft),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '${widget.visit.visitor.name}, ${widget.visit.hostEmployee.name}\'i ziyaret etmek istiyor.',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: colors.ink),
              ),
              const SizedBox(height: 4),
              Text(widget.visit.visitReason, style: TextStyle(fontSize: 13, color: colors.soft)),
              const SizedBox(height: 24),
              DropdownButtonFormField<MeetingRoom>(
                initialValue: _selectedRoom,
                decoration: const InputDecoration(labelText: 'Toplantı odası'),
                items: rooms
                    .map((room) => DropdownMenuItem(value: room, child: Text(room.name)))
                    .toList(),
                onChanged: (room) => setState(() => _selectedRoom = room),
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _pickEndTime,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Toplantı bitiş saati'),
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
                    : Text(isAdmin ? 'Onayla' : 'Oda Talebi Gönder'),
              ),
              if (!isAdmin) ...[
                const SizedBox(height: 8),
                Text(
                  'Ziyaret, bir yönetici bu oda talebini onaylayınca kabul edilmiş sayılacak.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: colors.soft),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
