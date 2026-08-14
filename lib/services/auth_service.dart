import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

/// Oturum durumunu tutar: token + giriş yapan personel bilgisi.
///
/// Token ve personel bilgisi birlikte güvenli depoda saklanır, böylece
/// `/api/mobile/auth/login`'in döndüğü `staff` nesnesini tekrar sormaya
/// gerek kalmadan uygulama yeniden açıldığında oturum geri yüklenebilir.
class AuthService extends ChangeNotifier {
  AuthService({required this.client, FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient client;
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'vizit_token';
  static const _staffKey = 'vizit_staff';

  bool _initializing = true;
  String? _staffId;
  String? _name;
  String? _email;
  String? _role;

  bool get isInitializing => _initializing;
  bool get isAuthenticated => client.token != null;
  String? get staffId => _staffId;
  String? get name => _name;
  String? get email => _email;
  String? get role => _role;

  /// Uygulama açılışında çağrılır; daha önce giriş yapılmışsa oturumu geri yükler.
  Future<void> restore() async {
    final token = await _storage.read(key: _tokenKey);
    final staffJson = await _storage.read(key: _staffKey);
    if (token != null && staffJson != null) {
      client.token = token;
      _applyStaff(jsonDecode(staffJson) as Map<String, dynamic>);
    }
    _initializing = false;
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
    String? expectedRole,
  }) async {
    final body = {'email': email, 'password': password};
    if (expectedRole != null) body['expectedRole'] = expectedRole;

    final data = await client.post('/auth/login', body: body) as Map<String, dynamic>;

    final token = data['token'] as String;
    final staff = data['staff'] as Map<String, dynamic>;

    client.token = token;
    _applyStaff(staff);
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _staffKey, value: jsonEncode(staff));
    notifyListeners();
  }

  Future<void> logout() async {
    client.token = null;
    _staffId = null;
    _name = null;
    _email = null;
    _role = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _staffKey);
    notifyListeners();
  }

  void _applyStaff(Map<String, dynamic> staff) {
    _staffId = staff['id'] as String;
    _name = staff['name'] as String;
    _email = staff['email'] as String;
    _role = staff['role'] as String;
  }
}
