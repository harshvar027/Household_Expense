import '../config/region_config.dart';
import '../models/app_region.dart';
import '../services/app_locale_service.dart';

class AuthValidators {
  static final _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static RegionConfig get _region => AppLocaleService.instance.config;

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your full name';
    if (text.length < 2) return 'Name is too short';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your email address';
    if (!_emailPattern.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? value, {AppRegion? region}) {
    final config = region == null
        ? _region
        : RegionConfig.forRegion(region);
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Enter your phone number';

    final dial = config.phoneDialCode.replaceAll('+', '');
    if (digits.startsWith(dial) &&
        digits.length > config.phoneMaxDigits &&
        digits.length <= config.phoneMaxDigits + dial.length) {
      final local = digits.substring(dial.length);
      if (local.length >= config.phoneMinDigits &&
          local.length <= config.phoneMaxDigits) {
        return null;
      }
    }

    if (digits.length < config.phoneMinDigits ||
        digits.length > config.phoneMaxDigits) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String normalizePhone(String value, {AppRegion? region}) {
    final config = region == null
        ? _region
        : RegionConfig.forRegion(region);
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final dial = config.phoneDialCode.replaceAll('+', '');
    if (digits.startsWith(dial) && digits.length > config.phoneMinDigits) {
      return digits.substring(dial.length);
    }
    return digits;
  }

  static String? pin(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter a 4-digit PIN';
    if (!RegExp(r'^\d{4}$').hasMatch(text)) {
      return 'PIN must be exactly 4 digits';
    }
    return null;
  }

  static String? confirmPin(String? value, String pin) {
    final error = AuthValidators.pin(value);
    if (error != null) return error;
    if (value != pin) return 'PINs do not match';
    return null;
  }

  static String? password(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter a password';
    if (text.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final error = AuthValidators.password(value);
    if (error != null) return error;
    if (value != password) return 'Passwords do not match';
    return null;
  }
}
