import 'package:flutter_test/flutter_test.dart';
import 'package:household_expense/config/region_config.dart';
import 'package:household_expense/models/app_region.dart';
import 'package:household_expense/models/user_profile.dart';
import 'package:household_expense/services/app_locale_service.dart';
import 'package:household_expense/services/transaction_parser.dart';

void main() {
  group('RegionConfig', () {
    test('US uses MDY dates and USD', () {
      final config = RegionConfig.forRegion(AppRegion.unitedStates);
      expect(config.currencyCode, 'USD');
      expect(config.dateOrder, DateOrder.mdy);
      expect(config.banks.any((b) => b.id == 'chase'), isTrue);
    });

    test('India keeps INR and Indian banks', () {
      final config = RegionConfig.forRegion(AppRegion.india);
      expect(config.currencyCode, 'INR');
      expect(config.banks.any((b) => b.id == 'sbi'), isTrue);
      expect(config.supportsSmsQuickEntry, isFalse);
    });
  });

  group('AppLocaleService', () {
    test('applyProfile sets currency symbol from region', () {
      AppLocaleService.instance.applyProfile(
        const UserProfile(
          name: 'Test',
          email: 't@example.com',
          phone: '5551234567',
          region: 'unitedStates',
          currency: 'USD',
        ),
      );
      expect(AppLocaleService.instance.currencySymbol, r'$');
      expect(AppLocaleService.instance.dateOrder, DateOrder.mdy);
    });
  });

  group('TransactionParser date order', () {
    test('parses MDY numeric dates when region is US', () {
      AppLocaleService.instance.applyProfile(
        const UserProfile(
          name: 'Test',
          email: 't@example.com',
          phone: '5551234567',
          region: 'unitedStates',
          currency: 'USD',
        ),
      );
      final parser = TransactionParser();
      final date = parser.parseDate('03/15/2024');
      expect(date?.year, 2024);
      expect(date?.month, 3);
      expect(date?.day, 15);
    });
  });
}
