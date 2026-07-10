import 'package:flutter/material.dart';

import 'ad_banner_host.dart';

/// Banner strip above the bottom navigation bar.
class BottomAdRibbon extends StatelessWidget {
  final bool visible;

  const BottomAdRibbon({super.key, this.visible = true});

  @override
  Widget build(BuildContext context) {
    return AdBannerHost(
      active: visible,
      style: AdBannerStyle.bottomRibbon,
    );
  }
}
