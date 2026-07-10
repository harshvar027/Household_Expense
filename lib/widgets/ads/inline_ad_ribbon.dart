import 'package:flutter/material.dart';

import 'ad_banner_host.dart';

/// Banner placed between scroll sections — does not overlap tappable tiles.
class InlineAdRibbon extends StatelessWidget {
  final bool active;

  const InlineAdRibbon({super.key, this.active = true});

  @override
  Widget build(BuildContext context) {
    return AdBannerHost(
      active: active,
      style: AdBannerStyle.inlineSection,
    );
  }
}
