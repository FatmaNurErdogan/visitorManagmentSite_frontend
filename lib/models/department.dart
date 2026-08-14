/// Personel formundaki "Departman" seçim listesinin kaynağı.
/// Bkz. backend src/actions/departments.ts.
class Department {
  const Department({required this.id, required this.name});

  final String id;
  final String name;

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(id: json['id'] as String, name: json['name'] as String);
  }
}
