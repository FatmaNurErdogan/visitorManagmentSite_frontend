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
