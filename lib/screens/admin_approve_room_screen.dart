import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/meeting_room.dart';
import '../models/visit.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/async_state.dart';

final _dateTimeFormat = DateFormat('d MMMM, HH:mm', 'tr_TR');

/// Departman admin'inin bir ziyareti son olarak onaylarken isteğe bağlı
/// olarak bir toplantı odası da atayabildiği ekran — bkz. backend'deki
/// approveVisitByAdminCore. Oda seçilirse, ziyaretin zaten planlanmış
/// saatleri için doğrudan bir rezervasyon oluşturulur; o saatte oda
/// doluysa onay başarısız olur ve farklı bir oda/atamasız devam etmek
/// gerekir.
class AdminApproveRoomScreen extends StatefulWidget {
  const AdminApproveRoomScreen({super.key, required this.visit});

  final Visit visit;

  @override
  State<AdminApproveRoomScreen> createState() => _AdminApproveRoomScreenState();
}

class _AdminApproveRoomScreenState extends State<AdminApproveRoomScreen> {
  late Future<List<MeetingRoom>> _roomsFuture;
  MeetingRoom? _selectedRoom;
  bool _submitting = false;

  ApiClient get _client => context.read<AuthService>().client;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _loadRooms();
  }

  Future<List<MeetingRoom>> _loadRooms() async {
    final data = await _client.get('/rooms') as Map<String, dynamic>;
    return (data['rooms'] as List<dynamic>).map((json) => MeetingRoom.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await _client.post('/visits/${widget.visit.id}/approve', body: {
        if (_selectedRoom != null) 'roomId': _selectedRoom!.id,
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
      appBar: AppBar(title: const Text('Son onay')),
      body: AsyncStateBuilder<List<MeetingRoom>>(
        future: _roomsFuture,
        onRetry: () => setState(() {
          _roomsFuture = _loadRooms();
        }),
        builder: (context, rooms) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '${widget.visit.visitor.name}, ${widget.visit.hostEmployee.name}\'i ziyaret etmek istiyor.',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: colors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                '${_dateTimeFormat.format(widget.visit.scheduledAt)} — ${DateFormat('HH:mm').format(widget.visit.scheduledEndAt)}',
                style: TextStyle(fontSize: 13, color: colors.soft),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<MeetingRoom?>(
                initialValue: _selectedRoom,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Oda atama (opsiyonel)'),
                items: [
                  const DropdownMenuItem<MeetingRoom?>(value: null, child: Text('Oda atama yok')),
                  ...rooms.map(
                    (room) => DropdownMenuItem<MeetingRoom?>(
                      value: room,
                      child: Text(room.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (room) => setState(() => _selectedRoom = room),
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
                    : const Text('Onayla'),
              ),
              const SizedBox(height: 8),
              Text(
                'Bir oda seçersen, ziyaretin planlanmış saatleri için doğrudan rezerve edilir. Oda o saatte doluysa onay başarısız olur.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: colors.soft),
              ),
            ],
          );
        },
      ),
    );
  }
}
