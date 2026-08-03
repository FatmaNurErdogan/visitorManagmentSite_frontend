import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

/// `/api/mobile/*` bir hata döndürdüğünde (`{ "error": "..." }`) fırlatılır.
class ApiException implements Exception {
  ApiException(this.message, {required this.statusCode});

  final String message;
  final int statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// visitorSite'ın `/api/mobile` katmanına ince bir HTTP sarmalayıcı.
///
/// Token, [AuthService] tarafından login/logout sırasında set edilir; burada
/// sadece varsa isteğe `Authorization: Bearer <token>` eklenir.
class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;
  String? token;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$apiBaseUrl$path').replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final response = await _http.get(_uri(path, query), headers: _headers);
    return _decode(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final response = await _http.post(
      _uri(path),
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final Map<String, dynamic> data = response.body.isEmpty ? {} : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data['error'] as String? ?? 'Beklenmeyen bir hata oluştu.';
      throw ApiException(message, statusCode: response.statusCode);
    }

    return data;
  }
}
