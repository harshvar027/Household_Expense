import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/ad_config.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';

enum AdBannerStyle {
  /// Fixed strip above bottom navigation.
  bottomRibbon,

  /// Embedded between scroll sections (e.g. menu groups).
  inlineSection,
}

/// Loads, displays, and periodically refreshes a banner ad.
class AdBannerHost extends StatefulWidget {
  final bool active;
  final AdBannerStyle style;

  const AdBannerHost({
    super.key,
    required this.active,
    this.style = AdBannerStyle.bottomRibbon,
  });

  @override
  State<AdBannerHost> createState() => _AdBannerHostState();
}

class _AdBannerHostState extends State<AdBannerHost> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  bool _loading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      // Defer ad load so startup / tab transitions stay responsive.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(AdConfig.loadDelay, () {
          if (mounted && widget.active) _loadAd();
        });
      });
    }
  }

  @override
  void didUpdateWidget(AdBannerHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      Future.delayed(AdConfig.loadDelay, () {
        if (mounted && widget.active) _loadAd();
      });
    } else if (!widget.active && oldWidget.active) {
      _stopRefreshTimer();
      _disposeAd();
    }
  }

  Future<void> _loadAd() async {
    if (!widget.active || !AdService.isSupported || _loading) return;

    _loading = true;
    _stopRefreshTimer();
    _disposeAd();

    try {
      final ad = await AdService.createBannerAd();

      if (!mounted || !widget.active) {
        ad?.dispose();
        return;
      }

      if (ad != null) {
        setState(() {
          _bannerAd = ad;
          _loaded = true;
        });
        _scheduleRefresh();
      } else {
        setState(() => _loaded = false);
        _scheduleRetry();
      }
    } finally {
      _loading = false;
    }
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(AdConfig.refreshInterval, () {
      if (mounted && widget.active && !_loading) _loadAd();
    });
  }

  void _scheduleRetry() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(minutes: 2), () {
      if (mounted && widget.active && !_loading) _loadAd();
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _disposeAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _loaded = false;
  }

  @override
  void dispose() {
    _stopRefreshTimer();
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();

    return switch (widget.style) {
      AdBannerStyle.bottomRibbon => _buildBottomRibbon(),
      AdBannerStyle.inlineSection => _buildInlineSection(),
    };
  }

  Widget _buildBottomRibbon() {
    if (!_loaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
          top: BorderSide(color: AppColors.accent.withValues(alpha: 0.12)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: AdConfig.bannerHeight,
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }

  Widget _buildInlineSection() {
    const verticalPadding = 8.0;
    final slotHeight = AdConfig.bannerHeight + (verticalPadding * 2);

    if (!_loaded || _bannerAd == null) {
      // Keep a fixed slot while active so loaded ads never overlap tiles below.
      return SizedBox(
        height: slotHeight,
        child: _loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: verticalPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ColoredBox(
          color: AppColors.surfaceElevated,
          child: SizedBox(
            width: double.infinity,
            height: AdConfig.bannerHeight,
            child: AdWidget(ad: _bannerAd!),
          ),
        ),
      ),
    );
  }
}
