/// Global feature toggles for store builds and compliance.
class AppFeatureFlags {
  AppFeatureFlags._();

  /// SMS quick entry is disabled — not used and avoids Play Store SMS declarations.
  static const smsQuickEntryEnabled = false;
}
