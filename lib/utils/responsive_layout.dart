import 'package:flutter/material.dart';

import '../config/ad_config.dart';

/// Shared breakpoints and inset math for phone, tablet, and large screens.
class ResponsiveLayout {
  ResponsiveLayout._();

  static const double maxContentWidth = 840;
  static const double tabletBreakpoint = 600;
  static const double wideBreakpoint = 840;
  static const double compactHeightBreakpoint = 360;
  static const double baseBottomNavHeight = 76;

  static double textScale(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);

  static double bottomNavBarHeight(BuildContext context) =>
      baseBottomNavHeight * textScale(context);

  static double scrollBottomPadding(
    BuildContext context, {
    required bool showBottomAd,
    bool includeFabClearance = false,
  }) {
    final mq = MediaQuery.of(context);
    final navHeight = bottomNavBarHeight(context);
    final safeBottom = mq.padding.bottom;
    final outerPad = safeBottom > 0 ? 4.0 : 12.0;
    final ad = showBottomAd ? AdConfig.bannerHeight : 0.0;
    final fab = includeFabClearance ? 64.0 : 0.0;
    return navHeight + safeBottom + outerPad + ad + fab + 20;
  }

  static double fabBottomOffset(
    BuildContext context, {
    required bool showBottomAd,
  }) {
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom;
    if (keyboard > 0) return keyboard + 12;

    final navHeight = bottomNavBarHeight(context);
    final safeBottom = mq.padding.bottom;
    final outerPad = safeBottom > 0 ? 4.0 : 12.0;
    final ad = showBottomAd ? AdConfig.bannerHeight : 0.0;
    return navHeight + safeBottom + outerPad + ad;
  }

  static int gridCrossAxisCount(
    BuildContext context, {
    int phone = 2,
    int tablet = 3,
    int wide = 4,
  }) {
    final width = contentWidth(context);
    if (width >= wideBreakpoint) return wide;
    if (width >= tabletBreakpoint) return tablet;
    return phone;
  }

  static double contentWidth(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width.clamp(0, maxContentWidth);
  }

  static bool isCompactWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;

  static bool isTabletOrWider(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static EdgeInsets screenPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return const EdgeInsets.fromLTRB(12, 8, 12, 0);
    if (width >= tabletBreakpoint) {
      return const EdgeInsets.fromLTRB(28, 8, 28, 0);
    }
    return const EdgeInsets.fromLTRB(20, 8, 20, 0);
  }

  static Widget constrainContent(BuildContext context, Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxContentWidth,
          minHeight: MediaQuery.sizeOf(context).height,
        ),
        child: child,
      ),
    );
  }
}
