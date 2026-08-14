import 'api_client.dart';

/// SADECE DEBUG: backend'e/veritabanına hiç erişmeden, uygulamanın tüm ekranlarını
/// (Panel, Kayıtlar, Odalar, Personel) gezebilmek için bellek-içi sahte veri katmanı.
///
/// `ApiClient.enableOfflineMock()` çağrıldığında devreye girer ve get/post/delete
/// çağrılarını buradaki `handle` metoduna yönlendirir — hiçbir zaman gerçek ağa çıkmaz.
/// Veritabanına erişilemediğinde (ör. ofis dışındayken) login_screen.dart'taki
/// "Offline admin (dev)" butonundan tetiklenir.
class OfflineMock {
  OfflineMock({this.currentStaffName = 'Debug Admin'});

  final String currentStaffName;

  late final List<Map<String, dynamic>> _staff = _seedStaff();
  late final List<Map<String, dynamic>> _visits = _seedVisits();
  late final List<Map<String, dynamic>> _rooms = _seedRooms();
  late final List<Map<String, dynamic>> _departments = _seedDepartments();

  int _idCounter = 1000;
  String _nextId(String prefix) => '$prefix-${_idCounter++}';

  String _iso(DateTime dt) => dt.toUtc().toIso8601String();

  List<Map<String, dynamic>> _seedStaff() {
    final now = DateTime.now();
    return [
      {
        'id': 's-admin',
        'name': 'Debug Admin',
        'email': 'debug@local',
        'role': 'ADMIN',
        'department': 'Yönetim',
        'createdAt': _iso(now.subtract(const Duration(days: 220))),
      },
      {
        'id': 's-emp1',
        'name': 'Elif Yıldız',
        'email': 'elif@vizit.local',
        'role': 'EMPLOYEE',
        'department': 'Ürün',
        'createdAt': _iso(now.subtract(const Duration(days: 150))),
      },
      {
        'id': 's-emp2',
        'name': 'Mert Kaya',
        'email': 'mert@vizit.local',
        'role': 'EMPLOYEE',
        'department': 'Mühendislik',
        'createdAt': _iso(now.subtract(const Duration(days: 90))),
      },
      {
        'id': 's-rec1',
        'name': 'Ayşe Demir',
        'email': 'ayse@vizit.local',
        'role': 'RECEPTIONIST',
        'department': null,
        'createdAt': _iso(now.subtract(const Duration(days: 60))),
      },
    ];
  }

  Map<String, dynamic> _visitor(String id, String name, String phone, {String? company}) =>
      {'id': id, 'name': name, 'phone': phone, 'email': null, 'company': company};

  Map<String, dynamic> _hostFrom(Map<String, dynamic> staff) =>
      {'id': staff['id'], 'name': staff['name'], 'email': staff['email'], 'department': staff['department']};

  List<Map<String, dynamic>> _seedVisits() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final emp1 = _staff[1];
    final emp2 = _staff[2];

    return [
      {
        'id': 'visit-1',
        'visitor': _visitor('vis-1', 'Caner Öztürk', '+905551112233', company: 'Acme A.Ş.'),
        'hostEmployee': _hostFrom(emp1),
        'visitReason': 'Ürün demo görüşmesi',
        'scheduledAt': _iso(today.add(const Duration(hours: 14))),
        'scheduledEndAt': _iso(today.add(const Duration(hours: 14, minutes: 30))),
        'status': 'PENDING',
        'requestedAt': _iso(now.subtract(const Duration(hours: 1))),
        'respondedAt': null,
        'checkedInAt': null,
        'checkedOutAt': null,
      },
      {
        'id': 'visit-2',
        'visitor': _visitor('vis-2', 'Zeynep Aksoy', '+905552223344', company: 'Beta Ltd.'),
        'hostEmployee': _hostFrom(emp2),
        'visitReason': 'Sözleşme görüşmesi',
        'scheduledAt': _iso(today.add(const Duration(hours: 10))),
        'scheduledEndAt': _iso(today.add(const Duration(hours: 10, minutes: 30))),
        'status': 'ACCEPTED',
        'requestedAt': _iso(now.subtract(const Duration(days: 1))),
        'respondedAt': _iso(now.subtract(const Duration(days: 1))),
        'checkedInAt': null,
        'checkedOutAt': null,
      },
      {
        'id': 'visit-3',
        'visitor': _visitor('vis-3', 'Tolga Şahin', '+905553334455'),
        'hostEmployee': _hostFrom(emp1),
        'visitReason': 'Teknik görüşme',
        'scheduledAt': _iso(today.add(const Duration(hours: 9))),
        'scheduledEndAt': _iso(today.add(const Duration(hours: 9, minutes: 30))),
        'status': 'CHECKED_IN',
        'requestedAt': _iso(now.subtract(const Duration(days: 2))),
        'respondedAt': _iso(now.subtract(const Duration(days: 2))),
        'checkedInAt': _iso(today.add(const Duration(hours: 9, minutes: 5))),
        'checkedOutAt': null,
      },
      {
        'id': 'visit-4',
        'visitor': _visitor('vis-1', 'Caner Öztürk', '+905551112233', company: 'Acme A.Ş.'),
        'hostEmployee': _hostFrom(emp2),
        'visitReason': 'Geçmiş ziyaret',
        'scheduledAt': _iso(now.subtract(const Duration(days: 3))),
        'scheduledEndAt': _iso(now.subtract(const Duration(days: 3)).add(const Duration(minutes: 30))),
        'status': 'CHECKED_OUT',
        'requestedAt': _iso(now.subtract(const Duration(days: 4))),
        'respondedAt': _iso(now.subtract(const Duration(days: 4))),
        'checkedInAt': _iso(now.subtract(const Duration(days: 3))),
        'checkedOutAt': _iso(now.subtract(const Duration(days: 3)).add(const Duration(hours: 1))),
      },
    ];
  }

  List<Map<String, dynamic>> _seedRooms() {
    final now = DateTime.now();
    final visit2 = _visits[1];

    return [
      {
        'id': 'room-1',
        'name': 'Toplantı Odası 1',
        'location': '3. Kat',
        'capacity': 6,
        'perks': 'Projeksiyon, Beyaz tahta',
        'bookings': [
          {
            'id': 'booking-1',
            'startTime': _iso(now.subtract(const Duration(minutes: 30))),
            'endTime': _iso(now.add(const Duration(minutes: 30))),
            'purpose': 'Haftalık senkron',
            'requestedBy': {'name': 'Elif Yıldız'},
            'visit': null,
          },
        ],
      },
      {
        'id': 'room-2',
        'name': 'Toplantı Odası 2',
        'location': '2. Kat',
        'capacity': 10,
        'perks': 'TV, Video konferans',
        'bookings': [
          {
            'id': 'booking-2',
            'startTime': _iso(now.add(const Duration(hours: 2))),
            'endTime': _iso(now.add(const Duration(hours: 3))),
            'purpose': visit2['visitReason'],
            'requestedBy': {'name': visit2['hostEmployee']['name']},
            'visit': {
              'visitor': {'name': visit2['visitor']['name']},
              'hostEmployee': {'name': visit2['hostEmployee']['name']},
            },
          },
        ],
      },
      {
        'id': 'room-3',
        'name': 'Toplantı Odası 3',
        'location': '1. Kat',
        'capacity': 4,
        'perks': '',
        'bookings': <Map<String, dynamic>>[],
      },
    ];
  }

  List<Map<String, dynamic>> _seedDepartments() {
    return [
      {'id': 'dept-1', 'name': 'Yönetim'},
      {'id': 'dept-2', 'name': 'Ürün'},
      {'id': 'dept-3', 'name': 'Mühendislik'},
    ];
  }

  Never _notFound(String path) => throw ApiException('Bulunamadı: $path', statusCode: 404);

  Map<String, dynamic>? _findVisit(String id) {
    for (final v in _visits) {
      if (v['id'] == id) return v;
    }
    return null;
  }

  Map<String, dynamic>? _findRoom(String id) {
    for (final r in _rooms) {
      if (r['id'] == id) return r;
    }
    return null;
  }

  Future<dynamic> handle(String method, String path, {Map<String, String>? query, Object? body}) async {
    final b = (body as Map<String, dynamic>?) ?? const {};

    if (method == 'GET' && path == '/visits/dashboard') {
      return {
        'pendingApprovals': _visits.where((v) => v['status'] == 'PENDING').toList(),
        'todaysVisits': _visits.where((v) => v['status'] == 'ACCEPTED' || v['status'] == 'CHECKED_IN').toList(),
      };
    }

    if (method == 'GET' && path == '/visits') {
      final status = query?['status'];
      final visits = status == null ? _visits : _visits.where((v) => v['status'] == status).toList();
      return {'visits': visits};
    }

    // Backend'deki createVisitRequestCore'un basitleştirilmiş offline
    // karşılığı — aynı host için, henüz sonuçlanmamış (PENDING/
    // PENDING_ADMIN_APPROVAL/ACCEPTED/CHECKED_IN) bir ziyaretle çakışan yeni
    // talep oluşturulamıyor. Gerçek sunucudaki transaction/race-condition
    // koruması burada yok — bu sadece UI akışını test etmek için.
    if (method == 'POST' && path == '/visits') {
      final name = (b['name'] as String?)?.trim() ?? '';
      final hostEmployeeId = b['hostEmployeeId'] as String?;
      final scheduledAtRaw = b['scheduledAt'] as String?;
      final scheduledEndAtRaw = b['scheduledEndAt'] as String?;
      if (name.isEmpty || hostEmployeeId == null || scheduledAtRaw == null || scheduledEndAtRaw == null) {
        throw ApiException('Please fill in all required fields.', statusCode: 400);
      }

      final scheduledAt = DateTime.parse(scheduledAtRaw);
      final scheduledEndAt = DateTime.parse(scheduledEndAtRaw);
      if (!scheduledEndAt.isAfter(scheduledAt)) {
        throw ApiException('End time must be after the start time.', statusCode: 400);
      }

      const openStatuses = ['PENDING', 'PENDING_ADMIN_APPROVAL', 'ACCEPTED', 'CHECKED_IN'];
      final conflict = _visits.any((v) {
        final host = v['hostEmployee'] as Map<String, dynamic>;
        if (host['id'] != hostEmployeeId) return false;
        if (!openStatuses.contains(v['status'])) return false;
        final vStart = DateTime.parse(v['scheduledAt'] as String);
        final vEnd = DateTime.parse(v['scheduledEndAt'] as String);
        return vStart.isBefore(scheduledEndAt) && vEnd.isAfter(scheduledAt);
      });

      final host = _staff.firstWhere((s) => s['id'] == hostEmployeeId, orElse: () => const {});
      if (conflict) {
        throw ApiException(
          '${host['name'] ?? 'Host'} already has another visit scheduled in that time range. Please pick a different time.',
          statusCode: 400,
        );
      }

      final visitorId = _nextId('vis');
      final visit = {
        'id': _nextId('visit'),
        'visitor': _visitor(visitorId, name, (b['phone'] as String?) ?? '', company: b['company'] as String?),
        'hostEmployee': _hostFrom(host),
        'visitReason': (b['visitReason'] as String?) ?? '',
        'scheduledAt': scheduledAtRaw,
        'scheduledEndAt': scheduledEndAtRaw,
        'status': 'PENDING',
        'requestedAt': _iso(DateTime.now()),
        'respondedAt': null,
        'checkedInAt': null,
        'checkedOutAt': null,
        'accessToken': _nextId('token'),
      };
      _visits.add(visit);
      return {'visit': visit};
    }

    if (method == 'GET' && path == '/rooms') {
      return {'rooms': _rooms};
    }

    if (method == 'GET' && path == '/rooms/calendar') {
      final now = DateTime.now();
      var year = now.year;
      var month = now.month;
      final parts = query?['month']?.split('-');
      if (parts != null && parts.length == 2) {
        year = int.tryParse(parts[0]) ?? year;
        month = int.tryParse(parts[1]) ?? month;
      }
      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 1);

      final bookings = <Map<String, dynamic>>[];
      for (final room in _rooms) {
        for (final booking in room['bookings'] as List<Map<String, dynamic>>) {
          final start = DateTime.parse(booking['startTime'] as String);
          final end = DateTime.parse(booking['endTime'] as String);
          if (!start.isBefore(monthEnd) || !end.isAfter(monthStart)) continue;

          final visit = booking['visit'] as Map<String, dynamic>?;
          bookings.add({
            'id': booking['id'],
            'roomId': room['id'],
            'roomName': room['name'],
            'startTime': booking['startTime'],
            'endTime': booking['endTime'],
            'purpose': booking['purpose'],
            'label': visit != null
                ? '${(visit['visitor'] as Map)['name']} (${(visit['hostEmployee'] as Map)['name']} ziyaretinde)'
                : '${(booking['requestedBy'] as Map)['name']} (iç toplantı)',
          });
        }
      }
      return {'year': year, 'month': month, 'bookings': bookings};
    }

    if (method == 'GET' && path == '/staff') {
      return {'staff': _staff};
    }

    if (method == 'GET' && path == '/departments') {
      return {'departments': _departments};
    }

    if (method == 'POST' && path == '/departments') {
      final name = (b['name'] as String?)?.trim() ?? '';
      if (name.isEmpty) {
        throw ApiException('Please give the department a name.', statusCode: 400);
      }
      if (_departments.any((d) => d['name'] == name)) {
        throw ApiException('A department with this name already exists.', statusCode: 400);
      }
      _departments.add({'id': _nextId('dept'), 'name': name});
      return {'success': true};
    }

    if (method == 'GET' && path == '/hosts') {
      return {'hosts': _staff.where((s) => s['role'] == 'EMPLOYEE').map(_hostFrom).toList()};
    }

    final visitAction = RegExp(r'^/visits/([^/]+)/(reject|approve|checkin|checkout)$').firstMatch(path);
    if (method == 'POST' && visitAction != null) {
      final visit = _findVisit(visitAction.group(1)!);
      if (visit == null) _notFound(path);
      final now = _iso(DateTime.now());
      switch (visitAction.group(2)) {
        case 'reject':
          visit['status'] = 'REJECTED';
          visit['respondedAt'] = now;
        case 'approve':
          visit['status'] = 'ACCEPTED';
          visit['respondedAt'] = now;
        case 'checkin':
          visit['status'] = 'CHECKED_IN';
          visit['checkedInAt'] = now;
        case 'checkout':
          visit['status'] = 'CHECKED_OUT';
          visit['checkedOutAt'] = now;
      }
      return {'success': true};
    }

    if (method == 'POST' && path == '/rooms') {
      final room = {
        'id': _nextId('room'),
        'name': b['name'],
        'location': b['location'],
        'capacity': b['capacity'],
        'perks': b['perks'],
        'bookings': <Map<String, dynamic>>[],
      };
      _rooms.add(room);
      return {'success': true};
    }

    if (method == 'POST' && path == '/staff') {
      final staff = {
        'id': _nextId('staff'),
        'name': b['name'],
        'email': b['email'],
        'role': b['role'],
        'department': b['department'],
        'createdAt': _iso(DateTime.now()),
      };
      _staff.add(staff);
      return {'success': true};
    }

    final bookingCreate = RegExp(r'^/rooms/([^/]+)/bookings$').firstMatch(path);
    if (method == 'POST' && bookingCreate != null) {
      final room = _findRoom(bookingCreate.group(1)!);
      if (room == null) _notFound(path);
      final start = DateTime.parse(b['startTime'] as String);
      final end = DateTime.parse(b['endTime'] as String);
      if (!end.isAfter(start)) {
        throw ApiException('End time must be after the start time.', statusCode: 400);
      }
      final conflict = (room['bookings'] as List).cast<Map<String, dynamic>>().any((existing) {
        final existingStart = DateTime.parse(existing['startTime'] as String);
        final existingEnd = DateTime.parse(existing['endTime'] as String);
        return start.isBefore(existingEnd) && end.isAfter(existingStart);
      });
      if (conflict) {
        throw ApiException('This room is already booked for that time.', statusCode: 400);
      }
      (room['bookings'] as List<Map<String, dynamic>>).add({
        'id': _nextId('booking'),
        'startTime': b['startTime'],
        'endTime': b['endTime'],
        'purpose': b['purpose'],
        'requestedBy': {'name': currentStaffName},
        'visit': null,
      });
      return {'success': true};
    }

    final bookingCancel = RegExp(r'^/rooms/([^/]+)/bookings/([^/]+)$').firstMatch(path);
    if (method == 'DELETE' && bookingCancel != null) {
      final room = _findRoom(bookingCancel.group(1)!);
      if (room == null) _notFound(path);
      final bookingId = bookingCancel.group(2);
      final bookings = room['bookings'] as List<Map<String, dynamic>>;
      Map<String, dynamic>? booking;
      for (final bk in bookings) {
        if (bk['id'] == bookingId) {
          booking = bk;
          break;
        }
      }
      if (booking == null) throw ApiException('Booking not found.', statusCode: 400);
      if (booking['visit'] != null) {
        throw ApiException("This booking is tied to a visit and can't be cancelled here.", statusCode: 400);
      }
      bookings.remove(booking);
      return {'success': true};
    }

    _notFound(path);
  }
}
