import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/meeting_room.dart';
import '../models/staff_member.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/async_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/theme_toggle_button.dart';
import 'room_booking_screen.dart';
import 'room_form_screen.dart';

final _timeFormat = DateFormat('HH:mm', 'tr_TR');
final _dateTimeFormat = DateFormat('d MMMM, HH:mm', 'tr_TR');

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

/// /staff/rooms sayfasının mobil karşılığı — tüm odaların o anki
/// durumunu (Müsait / Dolu) ve kimin kullandığını gösterir.
class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  late Future<List<MeetingRoom>> _future;

  ApiClient get _client => context.read<AuthService>().client;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MeetingRoom>> _load() async {
    final data = await _client.get('/rooms') as Map<String, dynamic>;
    return (data['rooms'] as List<dynamic>).map((json) => MeetingRoom.fromJson(json as Map<String, dynamic>)).toList();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _addRoom() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RoomFormScreen()),
    );
    if (created == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().role == StaffRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toplantı odaları'),
        actions: const [ThemeToggleButton()],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(onPressed: _addRoom, child: const Icon(Icons.add_rounded))
          : null,
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: AsyncStateBuilder<List<MeetingRoom>>(
          future: _future,
          onRetry: _refresh,
          builder: (context, rooms) {
            if (rooms.isEmpty) {
              return ListView(
                children: const [
                  EmptyState(
                    icon: Icons.meeting_room_outlined,
                    title: 'Henüz oda yok',
                    message: 'Bir yönetici toplantı odası eklediğinde burada görünecek.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: rooms.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _RoomCard(room: rooms[index], onBooked: _refresh),
            );
          },
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.onBooked});

  final MeetingRoom room;
  final VoidCallback onBooked;

  Future<void> _reserve(BuildContext context) async {
    final booked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RoomBookingScreen(room: room)),
    );
    if (booked == true) onBooked();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vizitColors;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final current = _firstWhereOrNull(room.bookings, (b) => !b.startTime.isAfter(now) && b.endTime.isAfter(now));
    final next = _firstWhereOrNull(room.bookings, (b) => b.startTime.isAfter(now));

    String usedByLabel(RoomBookingSummary booking) => booking.visitorName != null
        ? '${booking.visitorName} (${booking.visitHostName} ziyaretinde)'
        : '${booking.requestedByName} (iç toplantı)';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(room.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: colors.ink)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: current != null ? colors.dangerBg : colors.acceptBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  current != null ? 'Dolu · ${_timeFormat.format(current.endTime)}\'e kadar' : 'Müsait',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: current != null ? colors.dangerInk : colors.acceptInk,
                  ),
                ),
              ),
            ],
          ),
          if (room.location != null || room.capacity != null) ...[
            const SizedBox(height: 4),
            Text(
              [if (room.location != null) room.location!, if (room.capacity != null) '${room.capacity} kişi'].join(
                ' · ',
              ),
              style: TextStyle(fontSize: 12.5, color: colors.soft),
            ),
          ],
          if (room.perksList.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: room.perksList
                  .map(
                    (perk) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: colors.chipBg, borderRadius: BorderRadius.circular(999)),
                      child: Text(perk, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: colors.chipInk)),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (current != null || next != null) ...[
            const SizedBox(height: 10),
            Text(
              current != null
                  ? usedByLabel(current)
                  : 'Sıradaki: ${_dateTimeFormat.format(next!.startTime)} — ${usedByLabel(next)}',
              style: TextStyle(fontSize: 12.5, color: scheme.primary, fontWeight: FontWeight.w600),
            ),
          ],
          if (room.bookings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Takvim',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: colors.soft),
            ),
            const SizedBox(height: 6),
            ...room.bookings.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '${_dateTimeFormat.format(b.startTime)} – ${_timeFormat.format(b.endTime)} · ${usedByLabel(b)}',
                  style: TextStyle(fontSize: 11.5, color: colors.soft),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _reserve(context),
              child: const Text('Rezervasyon Yap'),
            ),
          ),
        ],
      ),
    );
  }
}
