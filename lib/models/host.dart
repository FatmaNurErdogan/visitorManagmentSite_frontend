/// Ziyaretçinin "kimi ziyaret ediyorsun" listesinde seçtiği personel, aynı
/// zamanda bir ziyaretin `hostEmployee` alanı için de kullanılır.
class Host {
  const Host({required this.id, required this.name, this.email, this.department});

  final String id;
  final String name;
  final String? email;
  final String? department;

  /// Dropdown/liste gösterimi için: "Elif Yıldız (Ürün)" ya da departman
  /// yoksa sadece "Elif Yıldız".
  String get displayName => department == null || department!.isEmpty ? name : '$name ($department)';

  factory Host.fromJson(Map<String, dynamic> json) {
    return Host(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      department: json['department'] as String?,
    );
  }
}
