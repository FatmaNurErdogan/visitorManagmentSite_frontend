import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'offline_mock.dart';

/// `/api/mobile/*` bir hata döndürdüğünde (`{ "error": "..." }`) fırlatılır.
class ApiException implements Exception {
  ApiException(this.message, {required this.statusCode});

  final String message;
  final int statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Herhangi bir hatayı (backend'in döndürdüğü [ApiException] veya sunucuya
/// hiç ulaşılamadığında fırlayan bir [SocketException]/`ClientException`)
/// kullanıcıya gösterilebilir bir mesaja çevirir. Ekranlardaki `catch (e)`
/// bloklarının hepsi bunu kullanır — sadece [ApiException] yakalarsak
/// bağlantı hataları sessizce yutulur.
String friendlyErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  return 'Sunucuya ulaşılamadı. Bağlantını kontrol edip tekrar dene.';
}

/// visitorSite'ın `/api/mobile` katmanına ince bir HTTP sarmalayıcı.
///
/// Token, [AuthService] tarafından login/logout sırasında set edilir; burada
/// sadece varsa isteğe `Authorization: Bearer <token>` eklenir.
class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;
  String? token;
  OfflineMock? _offline;

  /// SADECE DEBUG: bundan sonraki tüm istekler gerçek ağa hiç çıkmadan
  /// [OfflineMock] tarafından bellek-içi sahte verilerle yanıtlanır.
  void enableOfflineMock({String currentStaffName = 'Debug Admin'}) {
    _offline = OfflineMock(currentStaffName: currentStaffName);
  }

  bool get isOfflineMock => _offline != null;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$apiBaseUrl$path').replace(queryParameters: query);
  }

  // "charset=utf-8" olmadan `http` paketi gövdeyi latin1 ile encode ediyor —
  // bu da ğ/ş/ı/İ gibi Türkçe karakterleri bozuyor (ç/ö/ü latin1'de olduğu
  // için fark edilmeden geçiyordu). Aşağıda ayrıca gövdeyi elle utf8 byte'a
  // çevirip gönderiyoruz, header'ın encode'unu varsaymak yerine.
  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=utf-8',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    if (_offline case final offline?) return offline.handle('GET', path, query: query);
    final response = await _http.get(_uri(path, query), headers: _headers);
    return _decode(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    if (_offline case final offline?) return offline.handle('POST', path, body: body);
    final response = await _http.post(
      _uri(path),
      headers: _headers,
      body: body == null ? null : utf8.encode(jsonEncode(body)),
    );
    return _decode(response);
  }

  Future<dynamic> delete(String path) async {
    if (_offline case final offline?) return offline.handle('DELETE', path);
    final response = await _http.delete(_uri(path), headers: _headers);
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> data = body.isEmpty ? {} : jsonDecode(body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data['error'] as String? ?? 'Beklenmeyen bir hata oluştu.';
      throw ApiException(message, statusCode: response.statusCode);
    }

    return data;
  }
}
