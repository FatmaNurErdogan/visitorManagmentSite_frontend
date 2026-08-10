/// visitorSite backend'inin mobil API tabanı.
///
/// - Android emulator: ana bilgisayarın localhost'u `10.0.2.2` üzerinden görünür.
/// - iOS simulator / Windows: `localhost` doğrudan çalışır.
/// - Gerçek cihaz: bilgisayarının yerel ağ (LAN) IP'sini kullanmalısın, örn.
///   `http://192.168.1.23:3000/api/mobile`, ve backend'i `npm run dev` ile
///   ayakta tutmalısın.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api/mobile',
);

/// Ziyaretçinin onay/red mailindeki link (`https://{deepLinkHost}/visit/{token}`)
/// ile eşleştirdiğimiz host. Universal Links (iOS) / App Links (Android) bu
/// domain üzerinden doğrulanıyor — gerçek, herkese açık bir HTTPS domain
/// olmalı (localhost / LAN IP ile çalışmaz, Apple/Google doğrulayamaz).
const String deepLinkHost = String.fromEnvironment(
  'DEEP_LINK_HOST',
  defaultValue: 'REPLACE_WITH_PRODUCTION_DOMAIN',
);
