import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';

class AdService {
  AdService._();

  static bool _initialized = false;
  static Future<void>? _initFuture;

  /// Call once after the first frame — never block [runApp].
  static Future<void> initialize() {
    if (_initialized) return Future.value();
    _initFuture ??= _doInitialize();
    return _initFuture!;
  }

  static Future<void> ensureInitialized() => initialize();

  static Future<void> _doInitialize() async {
    if (_initialized || kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('AdMob init failed: $e');
      _initFuture = null;
    }
  }

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String get bannerAdUnitId {
    if (Platform.isAndroid) return AdConfig.androidBannerId;
    if (Platform.isIOS) return AdConfig.iosBannerId;
    return '';
  }

  static Future<BannerAd?> createBannerAd() async {
    if (!isSupported) return null;

    await ensureInitialized();
    if (!_initialized) return null;

    final unitId = bannerAdUnitId;
    if (unitId.isEmpty) return null;

    final completer = Completer<BannerAd?>();
    late final BannerAd ad;
    ad = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!completer.isCompleted) completer.complete(ad);
        },
        onAdFailedToLoad: (failedAd, error) {
          failedAd.dispose();
          debugPrint('Banner ad failed: $error');
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    await ad.load();
    return completer.future;
  }
}
