/// Subscription pricing and store product identifiers.
///
/// Create matching products in Google Play Console and App Store Connect before publishing.
/// Free trial: 3 months, all features, ads shown.
/// After trial: one-time ₹1800 purchase for 1 year (ad-free).
class SubscriptionConfig {
  SubscriptionConfig._();

  static const freeTrialMonths = 3;
  static const yearlyPriceInr = 1800;

  /// Google Play / App Store one-time product id for ₹1800 / 1 year.
  static const yearlyProductId = 'household_expense_yearly_1800';

  static const productIds = {yearlyProductId};

  static const yearlyDuration = Duration(days: 365);
}
