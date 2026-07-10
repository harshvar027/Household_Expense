/// AdMob configuration.
///
/// **Before store upload:**
/// 1. Android: copy `android/admob.properties.example` → `android/admob.properties` (App ID for manifest)
/// 2. iOS: set `GADApplicationIdentifier` in `ios/Runner/Info.plist` to your iOS AdMob App ID
/// 3. Replace [androidBannerId] and [iosBannerId] below with production unit IDs from AdMob.
///    Test IDs (3940256099942544) must NOT ship to production.
class AdConfig {
  AdConfig._();

  /// Production: set in android/admob.properties. Test ID used only when properties file missing.
  static const androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  /// REPLACE with your production banner unit IDs before Play release.
  static const androidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const iosBannerId = 'ca-app-pub-3940256099942544/2934735716';
  /// Standard adaptive banner height is ~50 logical pixels.
  static const bannerHeight = 50.0;

  /// How often to request a fresh ad (AdMob also rotates server-side).
  static const refreshInterval = Duration(minutes: 5);

  /// Wait after screen paint before loading ads (avoids startup ANR).
  static const loadDelay = Duration(seconds: 2);
}
