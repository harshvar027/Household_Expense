/// AdMob configuration.
///
/// **Before store upload:**
/// 1. Android: copy `android/admob.properties.example` → `android/admob.properties` (App ID for manifest)
/// 2. iOS: set `GADApplicationIdentifier` in `ios/Runner/Info.plist` to your iOS AdMob App ID
/// 3. Replace banner / side unit IDs below with production unit IDs from AdMob.
///    Test IDs (3940256099942544) must NOT ship to production.
///
/// **AdMob Console → Apps → Ad units to create (no backend API keys required):**
/// - App ID (Android + iOS) — already wired via admob.properties / Info.plist
/// - Banner (bottom + inline menu) — [androidBannerId] / [iosBannerId]
/// - Medium rectangle or Banner for side rails — [androidSideBannerId] / [iosSideBannerId]
///   (may reuse the same banner unit as bottom if you prefer one unit)
class AdConfig {
  AdConfig._();

  /// Production: set in android/admob.properties. Test ID used only when properties file missing.
  static const androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  /// REPLACE with your production banner unit IDs before Play release.
  static const androidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const iosBannerId = 'ca-app-pub-3940256099942544/2934735716';

  /// Side-rail units (Google test medium-rectangle / banner IDs).
  /// Create dedicated “Side Left/Right” or “Medium rectangle” units in AdMob, or reuse banner IDs.
  static const androidSideBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const iosSideBannerId = 'ca-app-pub-3940256099942544/2934735716';

  /// Standard adaptive banner height is ~50 logical pixels.
  static const bannerHeight = 50.0;

  /// Side rail width (logical px). Adaptive banners fill this width.
  static const sideRailWidth = 120.0;

  /// Dual left/right rails when the screen is at least this wide (tablets / large phones).
  static const sideAdsMinWidth = 640.0;

  /// Narrower rail for landscape phones.
  static const sideRailWidthCompact = 96.0;

  /// How often to request a fresh ad (AdMob also rotates server-side).
  static const refreshInterval = Duration(minutes: 5);

  /// Wait after screen paint before loading ads (avoids startup ANR).
  static const loadDelay = Duration(seconds: 2);
}
