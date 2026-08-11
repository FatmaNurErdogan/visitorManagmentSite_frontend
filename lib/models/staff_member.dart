/// `Staff.role` değerleri.
class StaffRole {
  StaffRole._();

  static const admin = 'ADMIN';
  static const employee = 'EMPLOYEE';
  static const receptionist = 'RECEPTIONIST';

  static String label(String role) {
    switch (role) {
      case admin:
        return 'Yönetici';
      case receptionist:
        return 'Resepsiyon';
      case employee:
      default:
        return 'Personel';
    }
  }
}

class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.department,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final String? department;

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      department: json['department'] as String?,
    );
  }
}
