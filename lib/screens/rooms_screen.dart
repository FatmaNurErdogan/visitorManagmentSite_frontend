import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/calendar_booking.dart';
import '../models/meeting_room.dart';
import '../models/staff_member.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/async_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/theme_toggle_button.dart';
import 'mark_room_busy_screen.dart';
import 'room_form_screen.dart';

String _dayKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (rooms.isEmpty)
                  const EmptyState(
                    icon: Icons.meeting_room_outlined,
                    title: 'Henüz oda yok',
                    message: 'Bir yönetici toplantı odası eklediğinde burada görünecek.',
                  )
                else
                  for (final room in rooms) ...[
                    _RoomCard(room: room, onChanged: _refresh),
                    const SizedBox(height: 12),
                  ],
                const SizedBox(height: 12),
                const _RoomCalendarSection(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.onChanged});

  final MeetingRoom room;
  final VoidCallback onChanged;

  Future<void> _markBusy(BuildContext context) async {
    final marked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MarkRoomBusyScreen(room: room)),
    );
    if (marked == true) onChanged();
  }

  Future<void> _cancelBooking(BuildContext context, RoomBookingSummary booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Meşguliyeti iptal et'),
        content: Text('"${booking.purpose}" için ayrılan zaman iptal edilsin mi? Oda bu aralıkta tekrar müsait olacak.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('İptal et')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<AuthService>().client.delete('/rooms/${room.id}/bookings/${booking.id}');
      onChanged();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vizitColors;
    final scheme = Theme.of(context).colorScheme;
    final isAdmin = context.watch<AuthService>().role == StaffRole.admin;
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
          if (room.capacity != null) ...[
            const SizedBox(height: 4),
            Text('${room.capacity} kişi', style: TextStyle(fontSize: 12.5, color: colors.soft)),
          ],
          if (current != null || next != null) ...[
            const SizedBox(height: 10),
            Builder(builder: (context) {
              final shown = current ?? next!;
              final label = current != null
                  ? usedByLabel(current)
                  : 'Sıradaki: ${_dateTimeFormat.format(next!.startTime)} — ${usedByLabel(next)}';
              // Ziyarete bağlı rezervasyonlar buradan iptal edilemez — backend
              // bunu reddediyor, bu yüzden butonu sadece bağımsız (iç toplantı)
              // rezervasyonlarda gösteriyoruz.
              final cancellable = isAdmin && shown.visitorName == null;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 12.5, color: scheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (cancellable)
                    InkWell(
                      onTap: () => _cancelBooking(context, shown),
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Text(
                          'İptal et',
                          style: TextStyle(fontSize: 12.5, color: colors.dangerInk, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
          if (isAdmin) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _markBusy(context),
                icon: const Icon(Icons.event_busy_rounded, size: 18),
                label: const Text('Meşgul olarak işaretle'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Odalar ekranının altında, tüm odaların onaylanmış rezervasyonlarını
/// aylık bir takvimde gösteren bölüm. Backend: GET /rooms/calendar
/// (bkz. src/actions/rooms.ts getRoomBookingsForMonth).
class _RoomCalendarSection extends StatefulWidget {
  const _RoomCalendarSection();

  @override
  State<_RoomCalendarSection> createState() => _RoomCalendarSectionState();
}

class _RoomCalendarSectionState extends State<_RoomCalendarSection> {
  late DateTime _visibleMonth;
  DateTime? _selectedDay;
  late Future<List<CalendarBooking>> _future;

  ApiClient get _client => context.read<AuthService>().client;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
    _future = _load();
  }

  Future<List<CalendarBooking>> _load() async {
    final monthParam = '${_visibleMonth.year}-${_visibleMonth.month.toString().padLeft(2, '0')}';
    final data = await _client.get('/rooms/calendar', query: {'month': monthParam}) as Map<String, dynamic>;
    return (data['bookings'] as List<dynamic>)
        .map((json) => CalendarBooking.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
      _selectedDay = null;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vizitColors;
    final monthLabel = DateFormat('MMMM y', 'tr_TR').format(_visibleMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_month_rounded, size: 18, color: colors.ink),
            const SizedBox(width: 6),
            Text(
              'Rezervasyon takvimi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.ink),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: colors.cardShadow,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left_rounded)),
                  Text(monthLabel, style: TextStyle(fontWeight: FontWeight.w700, color: colors.ink)),
                  IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right_rounded)),
                ],
              ),
              FutureBuilder<List<CalendarBooking>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(friendlyErrorMessage(snapshot.error!), style: TextStyle(color: colors.soft)),
                    );
                  }
                  return _buildGrid(context, snapshot.data ?? const []);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, List<CalendarBooking> bookings) {
    final colors = context.vizitColors;
    final scheme = Theme.of(context).colorScheme;

    final byDay = <String, List<CalendarBooking>>{};
    for (final booking in bookings) {
      (byDay[_dayKey(booking.startTime)] ??= []).add(booking);
    }

    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingEmpty = (_visibleMonth.weekday - 1) % 7; // weekday: Pzt=1..Paz=7
    final totalCells = ((leadingEmpty + daysInMonth + 6) ~/ 7) * 7;

    final today = DateTime.now();
    final todayKey = _dayKey(DateTime(today.year, today.month, today.day));

    const weekdayLabels = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];
    final selectedKey = _selectedDay == null ? null : _dayKey(_selectedDay!);

    // Google Calendar'daki gibi odaya göre sabit bir renk ataması — bir ay
    // boyunca aynı oda hep aynı renkte kalsın diye roomId'lerin sıralı
    // listesindeki index'ine göre seçiliyor.
    final roomIds = bookings.map((b) => b.roomId).toSet().toList()..sort();
    final bgPalette = [colors.acceptBg, colors.warnBg, colors.dangerBg, colors.chipBg];
    final inkPalette = [colors.acceptInk, colors.warnInk, colors.dangerInk, colors.chipInk];
    Color chipBgFor(String roomId) => bgPalette[roomIds.indexOf(roomId) % bgPalette.length];
    Color chipInkFor(String roomId) => inkPalette[roomIds.indexOf(roomId) % inkPalette.length];

    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: weekdayLabels
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.soft),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.72),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final dayNum = index - leadingEmpty + 1;
            if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox.shrink();

            final date = DateTime(_visibleMonth.year, _visibleMonth.month, dayNum);
            final key = _dayKey(date);
            final dayBookings = byDay[key] ?? const <CalendarBooking>[];
            final count = dayBookings.length;
            final isSelected = key == selectedKey;
            final isToday = key == todayKey;
            const maxChips = 2;

            return InkWell(
              onTap: count == 0 ? null : () => setState(() => _selectedDay = date),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.all(1.5),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? scheme.primary.withValues(alpha: 0.1) : null,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? scheme.primary : (isToday ? scheme.primary : colors.divider),
                    width: isSelected ? 2 : (isToday ? 1.2 : 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$dayNum',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: colors.ink),
                    ),
                    const SizedBox(height: 1),
                    for (final booking in dayBookings.take(maxChips))
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                        decoration: BoxDecoration(
                          color: chipBgFor(booking.roomId),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          DateFormat('HH:mm').format(booking.startTime),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                            color: chipInkFor(booking.roomId),
                          ),
                        ),
                      ),
                    if (count > maxChips)
                      Text('+${count - maxChips}', style: TextStyle(fontSize: 7, color: colors.soft)),
                  ],
                ),
              ),
            );
          },
        ),
        if (_selectedDay != null) ...[
          const Divider(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              DateFormat('d MMMM y', 'tr_TR').format(_selectedDay!),
              style: TextStyle(fontWeight: FontWeight.w700, color: colors.ink),
            ),
          ),
          const SizedBox(height: 8),
          for (final booking in byDay[selectedKey] ?? const <CalendarBooking>[])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${booking.roomName} · ${DateFormat('HH:mm').format(booking.startTime)}–${DateFormat('HH:mm').format(booking.endTime)}',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: colors.ink),
                  ),
                  Text(booking.label, style: TextStyle(fontSize: 12, color: colors.soft)),
                  Text(booking.purpose, style: TextStyle(fontSize: 12, color: colors.soft)),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
