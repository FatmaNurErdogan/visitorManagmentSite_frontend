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

/// Backend hata mesajları İngilizce (web arayüzüyle paylaşılıyor) — bu
/// uygulama tamamen Türkçe olduğu için bilinen mesajları burada çeviriyoruz.
/// Eşleşmeyen (yeni/beklenmeyen) bir mesaj gelirse olduğu gibi gösteriliyor,
/// hatasız çalışmaya devam eder — sadece o mesaj İngilizce kalır.
const Map<String, String> _errorTranslations = {
  'Unauthorized': 'Bu işlem için giriş yapmanız gerekiyor.',
  'Invalid request body.': 'Geçersiz istek.',
  'Please give the room a name.': 'Lütfen odaya bir isim verin.',
  'Please give the department a name.': 'Lütfen departmana bir isim verin.',
  'A department with this name already exists.': 'Bu isimde bir departman zaten var.',
  'Capacity must be a positive whole number.': 'Kapasite pozitif bir tam sayı olmalı.',
  'A room with this name already exists.': 'Bu isimde bir oda zaten var.',
  'Please select a meeting room.': 'Lütfen bir toplantı odası seçin.',
  'This visit request has already been processed.': 'Bu ziyaret talebi zaten işlendi.',
  'Please fill in all required fields.': 'Lütfen tüm zorunlu alanları doldurun.',
  'Please provide a valid date and time.': 'Lütfen geçerli bir tarih ve saat girin.',
  'Please pick a date and time in the future.': 'Lütfen gelecekte bir tarih ve saat seçin.',
  'Please pick a start time between 9:00 and 18:00.': 'Lütfen 09:00–18:00 arasında bir başlangıç saati seçin.',
  "Please pick an end time between 9:00 and 18:00 on the same day.":
      'Lütfen aynı gün içinde, 18:00\'a kadar bir bitiş saati seçin.',
  "Please select who you're visiting.": 'Lütfen kimi ziyaret ettiğinizi seçin.',
  "Please pick an end time after the visit's scheduled start.":
      'Lütfen ziyaretin başlangıcından sonraki bir bitiş saati seçin.',
  'This room is already booked for that time.': 'Bu oda o saat aralığında zaten rezerve edilmiş.',
  'A room request for this visit is already pending.': 'Bu ziyaret için bir oda talebi zaten bekliyor.',
  'Please describe the purpose of this booking.': 'Lütfen bu rezervasyonun amacını yazın.',
  'Please provide valid start and end times.': 'Lütfen geçerli bir başlangıç ve bitiş saati girin.',
  'Please pick a start time in the future.': 'Lütfen gelecekte bir başlangıç saati seçin.',
  'End time must be after the start time.': 'Bitiş saati başlangıç saatinden sonra olmalı.',
  'Booking not found.': 'Rezervasyon bulunamadı.',
  "This booking is tied to a visit and can't be cancelled here.":
      'Bu rezervasyon bir ziyarete bağlı, buradan iptal edilemez.',
  'Only an active booking can be cancelled.': 'Sadece aktif bir rezervasyon iptal edilebilir.',
  'This room is already booked for that time — reject this ticket instead.':
      'Bu oda o saat aralığında zaten rezerve edilmiş — bunun yerine bu talebi reddedin.',
  "Chat isn't available for this visit.": 'Bu ziyaret için sohbet kullanılamıyor.',
  "Message can't be empty.": 'Mesaj boş olamaz.',
  'Too many requests. Please slow down.': 'Çok fazla istek gönderildi. Lütfen biraz yavaşlayın.',
  'Too many messages. Please slow down.': 'Çok fazla mesaj gönderildi. Lütfen biraz yavaşlayın.',
};

/// Herhangi bir hatayı (backend'in döndürdüğü [ApiException] veya sunucuya
/// hiç ulaşılamadığında fırlayan bir [SocketException]/`ClientException`)
/// kullanıcıya gösterilebilir bir mesaja çevirir. Ekranlardaki `catch (e)`
/// bloklarının hepsi bunu kullanır — sadece [ApiException] yakalarsak
/// bağlantı hataları sessizce yutulur.
String friendlyErrorMessage(Object error) {
  if (error is ApiException) {
    if (error.message.length > 'Message can\'t be longer than '.length &&
        error.message.startsWith("Message can't be longer than")) {
      return 'Mesaj çok uzun (en fazla 2000 karakter).';
    }
    // "<Host adı> already has another visit scheduled in that time range.
    // Please pick a different time." — host adı değişken olduğu için map'e
    // sabit girilemiyor, kalıba bakıp çeviriyoruz.
    if (error.message.contains('already has another visit scheduled in that time range')) {
      final host = error.message.split(' already has').first;
      return '$host bu saat aralığında zaten başka bir ziyaretle meşgul. Lütfen farklı bir saat seçin.';
    }
    return _errorTranslations[error.message] ?? error.message;
  }
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
