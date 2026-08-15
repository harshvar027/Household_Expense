import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Device fingerprint / face unlock via [local_auth].
class BiometricAuthService {
  BiometricAuthService._();

  static final BiometricAuthService instance = BiometricAuthService._();
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false;
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isAvailable() async {
    if (!await isDeviceSupported()) return false;
    return canCheckBiometrics();
  }

  Future<List<BiometricType>> availableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> authenticate({
    String reason = 'Unlock Household Expense',
    bool skipAvailabilityCheck = false,
  }) async {
    if (!skipAvailabilityCheck && !await isAvailable()) return false;

    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      debugPrint('Biometric auth failed: $e');
      return false;
    }
  }
}
