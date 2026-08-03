/// Ziyaretçinin "kimi ziyaret ediyorsun" listesinde seçtiği personel, aynı
/// zamanda bir ziyaretin `hostEmployee` alanı için de kullanılır.
class Host {
  const Host({required this.id, required this.name, this.email});

  final String id;
  final String name;
  final String? email;

  factory Host.fromJson(Map<String, dynamic> json) {
    return Host(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
    );
  }
}
