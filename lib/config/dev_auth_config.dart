import 'package:flutter/foundation.dart';

/// Temporary switches for testing registration (Indian + international).
/// Set [enableTestRegistration] to false before Play Store release.
class DevAuthConfig {
  /// Allows registering again on a device that already has an account.
  static const bool enableTestRegistration = false;

  static bool _disabledForTests = false;

  @visibleForTesting
  static void setDisabledForTests(bool disabled) {
    _disabledForTests = disabled;
  }

  static bool get canBypassRegistrationGuard =>
      !_disabledForTests && enableTestRegistration && !kReleaseMode;

  static bool get showTestRegistrationUi => canBypassRegistrationGuard;
}
