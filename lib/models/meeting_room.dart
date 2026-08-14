class RoomBookingSummary {
  const RoomBookingSummary({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.purpose,
    required this.requestedByName,
    this.visitorName,
    this.visitHostName,
  });

  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String purpose;
  final String requestedByName;
  // İkisi de null ise standalone (ziyaretsiz) bir rezervasyon.
  final String? visitorName;
  final String? visitHostName;

  factory RoomBookingSummary.fromJson(Map<String, dynamic> json) {
    final visit = json['visit'] as Map<String, dynamic>?;
    return RoomBookingSummary(
      id: json['id'] as String,
      // Backend UTC döndürüyor — .toLocal() olmadan oda saatleri 3 saat
      // geride görünür (bkz. models/visit.dart'taki aynı düzeltme).
      startTime: DateTime.parse(json['startTime'] as String).toLocal(),
      endTime: DateTime.parse(json['endTime'] as String).toLocal(),
      purpose: json['purpose'] as String,
      requestedByName: (json['requestedBy'] as Map<String, dynamic>)['name'] as String,
      visitorName: visit == null ? null : (visit['visitor'] as Map<String, dynamic>)['name'] as String,
      visitHostName: visit == null ? null : (visit['hostEmployee'] as Map<String, dynamic>)['name'] as String,
    );
  }
}

class MeetingRoom {
  const MeetingRoom({
    required this.id,
    required this.name,
    required this.bookings,
    this.location,
    this.capacity,
    this.perks,
  });

  final String id;
  final String name;
  final String? location;
  final int? capacity;
  // Virgülle ayrılmış serbest metin, ör. "Projector, Whiteboard, TV".
  final String? perks;
  final List<RoomBookingSummary> bookings;

  List<String> get perksList =>
      (perks == null || perks!.isEmpty) ? const [] : perks!.split(',').map((p) => p.trim()).toList();

  factory MeetingRoom.fromJson(Map<String, dynamic> json) {
    return MeetingRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String?,
      capacity: json['capacity'] as int?,
      perks: json['perks'] as String?,
      bookings: (json['bookings'] as List<dynamic>)
          .map((b) => RoomBookingSummary.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }
}
