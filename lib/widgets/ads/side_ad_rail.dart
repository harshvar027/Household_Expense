import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/ad_config.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';

/// Vertical ad column for the left or right edge of the shell.
class SideAdRail extends StatefulWidget {
  final bool active;
  final bool isLeft;

  const SideAdRail({
    super.key,
    required this.active,
    this.isLeft = true,
  });

  static bool shouldShow(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width >= AdConfig.sideAdsMinWidth) return true;
    // Landscape phones: still show dual rails with a compact width.
    return size.width > size.height && size.width >= 560;
  }

  static double railWidthFor(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width >= AdConfig.sideAdsMinWidth) return AdConfig.sideRailWidth;
    return AdConfig.sideRailWidthCompact;
  }

  @override
  State<SideAdRail> createState() => _SideAdRailState();
}

class _SideAdRailState extends State<SideAdRail> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  bool _loading = false;
  Timer? _refreshTimer;
  double _adHeight = 250;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(AdConfig.loadDelay, () {
          if (mounted && widget.active) _loadAd();
        });
      });
    }
  }

  @override
  void didUpdateWidget(SideAdRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      Future.delayed(AdConfig.loadDelay, () {
        if (mounted && widget.active) _loadAd();
      });
    } else if (!widget.active && oldWidget.active) {
      _stopRefreshTimer();
      _disposeAd();
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadAd() async {
    if (!widget.active || !AdService.isSupported || _loading) return;

    _loading = true;
    _stopRefreshTimer();
    _disposeAd();

    try {
      final ad = await AdService.createSideBannerAd(
        width: SideAdRail.railWidthFor(context),
      );

      if (!mounted || !widget.active) {
        ad?.dispose();
        return;
      }

      if (ad != null) {
        final h = ad.size.height.toDouble();
        setState(() {
          _bannerAd = ad;
          _loaded = true;
          _adHeight = h > 0 ? h : 250;
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

    final railWidth = SideAdRail.railWidthFor(context);
    final border = BorderSide(color: AppColors.accent.withValues(alpha: 0.12));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.85),
        border: Border(
          left: widget.isLeft ? BorderSide.none : border,
          right: widget.isLeft ? border : BorderSide.none,
        ),
      ),
      child: SizedBox(
        width: railWidth,
        child: SafeArea(
          left: widget.isLeft,
          right: !widget.isLeft,
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: (!_loaded || _bannerAd == null)
                  ? SizedBox(
                      width: railWidth,
                      height: 80,
                      child: _loading
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    )
                  : SizedBox(
                      width: railWidth,
                      height: _adHeight,
                      child: AdWidget(ad: _bannerAd!),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
