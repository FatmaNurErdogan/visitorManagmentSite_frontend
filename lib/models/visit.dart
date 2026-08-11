import 'host.dart';
import 'visitor.dart';

/// `Visit.status` değerleri — backend'de serbest metin (bkz. prisma/schema.prisma).
class VisitStatus {
  VisitStatus._();

  static const pending = 'PENDING';
  static const pendingAdminApproval = 'PENDING_ADMIN_APPROVAL';
  static const accepted = 'ACCEPTED';
  static const rejected = 'REJECTED';
  static const checkedIn = 'CHECKED_IN';
  static const checkedOut = 'CHECKED_OUT';
  static const cancelled = 'CANCELLED';
  static const expired = 'EXPIRED';

  static const all = [
    pending,
    pendingAdminApproval,
    accepted,
    rejected,
    checkedIn,
    checkedOut,
    cancelled,
    expired,
  ];

  static String label(String status) {
    switch (status) {
      case pending:
        return 'Bekliyor';
      case pendingAdminApproval:
        return 'Yönetici Onayı Bekliyor';
      case accepted:
        return 'Onaylandı';
      case rejected:
        return 'Reddedildi';
      case checkedIn:
        return 'İçeride';
      case checkedOut:
        return 'Çıktı';
      case cancelled:
        return 'İptal';
      case expired:
        return 'Süresi Doldu';
      default:
        return status;
    }
  }
}

class Visit {
  const Visit({
    required this.id,
    required this.visitor,
    required this.hostEmployee,
    required this.visitReason,
    required this.scheduledAt,
    required this.status,
    required this.requestedAt,
    this.respondedAt,
    this.checkedInAt,
    this.checkedOutAt,
    this.adminRejectionReason,
  });

  final String id;
  final Visitor visitor;
  final Host hostEmployee;
  final String visitReason;
  final DateTime scheduledAt;
  final String status;
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final String? adminRejectionReason;

  factory Visit.fromJson(Map<String, dynamic> json) {
    DateTime? parseNullable(Object? value) => value == null ? null : DateTime.parse(value as String);

    return Visit(
      id: json['id'] as String,
      visitor: Visitor.fromJson(json['visitor'] as Map<String, dynamic>),
      hostEmployee: Host.fromJson(json['hostEmployee'] as Map<String, dynamic>),
      visitReason: json['visitReason'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      status: json['status'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      respondedAt: parseNullable(json['respondedAt']),
      checkedInAt: parseNullable(json['checkedInAt']),
      checkedOutAt: parseNullable(json['checkedOutAt']),
      adminRejectionReason: json['adminRejectionReason'] as String?,
    );
  }
}
