/// User subscription tier.
enum SubscriptionTier {
  /// Free trial — all features for 3 months (ads shown).
  free,

  /// Legacy monthly tier (no longer sold).
  monthly,

  /// ₹1800 one-time — full features for 1 year, ad-free.
  yearly,
}

extension SubscriptionTierX on SubscriptionTier {
  String get label => switch (this) {
        SubscriptionTier.free => 'Free trial',
        SubscriptionTier.monthly => 'Pro',
        SubscriptionTier.yearly => 'Yearly Pro',
      };

  String get storageKey => name;
}

/// App capabilities that can be restricted by plan.
enum AppFeature {
  /// Core expense tracking during free trial.
  basicUsage,

  /// JSON backup — paid only.
  backup,

  /// JSON restore — paid only.
  restore,

  /// CSV export — paid only.
  exportCsv,

  /// PDF report — paid only.
  exportPdf,

  /// Bank statement import — paid only.
  importStatement,
}
