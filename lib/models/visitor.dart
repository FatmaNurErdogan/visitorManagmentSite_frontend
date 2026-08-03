class Visitor {
  const Visitor({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.company,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? company;

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      company: json['company'] as String?,
    );
  }
}
