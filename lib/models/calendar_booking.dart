/// /rooms/calendar'dan (bkz. backend src/actions/rooms.ts
/// getRoomBookingsForMonth) dönen tek bir rezervasyon — hangi odaya,
/// odalar ekranındaki aylık takvim için.
class CalendarBooking {
  const CalendarBooking({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.startTime,
    required this.endTime,
    required this.purpose,
    required this.label,
  });

  final String id;
  final String roomId;
  final String roomName;
  final DateTime startTime;
  final DateTime endTime;
  final String purpose;
  // "Ziyaretçi adı (host ziyaretinde)" ya da "Talep eden adı (iç toplantı)".
  final String label;

  factory CalendarBooking.fromJson(Map<String, dynamic> json) {
    return CalendarBooking(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      roomName: json['roomName'] as String,
      // Backend UTC döndürüyor — bkz. aynı düzeltme models/visit.dart'ta.
      startTime: DateTime.parse(json['startTime'] as String).toLocal(),
      endTime: DateTime.parse(json['endTime'] as String).toLocal(),
      purpose: json['purpose'] as String,
      label: json['label'] as String,
    );
  }
}
