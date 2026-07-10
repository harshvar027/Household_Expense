import '../config/region_config.dart';
import '../models/app_region.dart';
import '../models/user_profile.dart';

/// Active region, currency, and formatting rules for the signed-in household.
class AppLocaleService {
  AppLocaleService._();

  static final AppLocaleService instance = AppLocaleService._();

  RegionConfig _config = RegionConfig.forRegion(AppRegion.india);

  RegionConfig get config => _config;

  AppRegion get region => _config.region;

  String get currencyCode => _config.currencyCode;

  String get currencySymbol => _config.currencySymbol;

  DateOrder get dateOrder => _config.dateOrder;

  void applyProfile(UserProfile? profile) {
    if (profile == null) {
      _config = RegionConfig.forRegion(AppRegion.india);
      return;
    }
    final region = AppRegion.fromStorage(profile.region);
    _config = RegionConfig.forRegion(region);
    if (profile.currency.trim().isNotEmpty &&
        profile.currency != _config.currencyCode) {
      // Respect explicit currency override saved on profile.
      _config = RegionConfig(
        region: _config.region,
        currencyCode: profile.currency,
        currencySymbol: _symbolForCurrency(profile.currency),
        dateOrder: _config.dateOrder,
        phoneDialCode: _config.phoneDialCode,
        phoneMinDigits: _config.phoneMinDigits,
        phoneMaxDigits: _config.phoneMaxDigits,
        banks: _config.banks,
        paymentMethods: _config.paymentMethods,
        supportsSmsQuickEntry: _config.supportsSmsQuickEntry,
      );
    }
  }

  static String _symbolForCurrency(String code) {
    switch (code.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return code;
    }
  }
}
