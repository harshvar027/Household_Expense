import '../models/app_region.dart';
import '../models/bank_profile.dart';

enum DateOrder { dmy, mdy }

class RegionalBankOption {
  final String id;
  final String displayName;
  final BankId? importBankId;

  const RegionalBankOption({
    required this.id,
    required this.displayName,
    this.importBankId,
  });
}

class RegionConfig {
  final AppRegion region;
  final String currencyCode;
  final String currencySymbol;
  final DateOrder dateOrder;
  final String phoneDialCode;
  final int phoneMinDigits;
  final int phoneMaxDigits;
  final List<RegionalBankOption> banks;
  final List<String> paymentMethods;
  final bool supportsSmsQuickEntry;

  const RegionConfig({
    required this.region,
    required this.currencyCode,
    required this.currencySymbol,
    required this.dateOrder,
    required this.phoneDialCode,
    required this.phoneMinDigits,
    required this.phoneMaxDigits,
    required this.banks,
    required this.paymentMethods,
    required this.supportsSmsQuickEntry,
  });

  static RegionConfig forRegion(AppRegion region) {
    switch (region) {
      case AppRegion.india:
        return _india;
      case AppRegion.unitedStates:
        return _unitedStates;
      case AppRegion.unitedKingdom:
        return _unitedKingdom;
      case AppRegion.europe:
        return _europe;
      case AppRegion.international:
        return _international;
    }
  }

  static final _india = RegionConfig(
    region: AppRegion.india,
    currencyCode: 'INR',
    currencySymbol: '₹',
    dateOrder: DateOrder.dmy,
    phoneDialCode: '+91',
    phoneMinDigits: 10,
    phoneMaxDigits: 10,
    supportsSmsQuickEntry: false,
    paymentMethods: const [
      'Cash',
      'UPI',
      'Credit Card',
      'Debit Card',
      'Net Banking',
    ],
    banks: [
      const RegionalBankOption(
        id: 'generic',
        displayName: 'Auto-detect from file',
        importBankId: BankId.generic,
      ),
      ...BankProfile.supportedBanks.map(
        (bank) => RegionalBankOption(
          id: bank.id.name,
          displayName: bank.displayName,
          importBankId: bank.id,
        ),
      ),
    ],
  );

  static final _unitedStates = RegionConfig(
    region: AppRegion.unitedStates,
    currencyCode: 'USD',
    currencySymbol: r'$',
    dateOrder: DateOrder.mdy,
    phoneDialCode: '+1',
    phoneMinDigits: 10,
    phoneMaxDigits: 10,
    supportsSmsQuickEntry: false,
    paymentMethods: const [
      'Cash',
      'Debit Card',
      'Credit Card',
      'Bank Transfer',
      'Check',
      'Digital Wallet',
    ],
    banks: _intlBanks(const [
      ('chase', 'Chase'),
      ('bofa', 'Bank of America'),
      ('wells_fargo', 'Wells Fargo'),
      ('citi', 'Citibank'),
      ('capital_one', 'Capital One'),
      ('us_bank', 'U.S. Bank'),
      ('pnc', 'PNC Bank'),
      ('td_bank', 'TD Bank'),
    ]),
  );

  static final _unitedKingdom = RegionConfig(
    region: AppRegion.unitedKingdom,
    currencyCode: 'GBP',
    currencySymbol: '£',
    dateOrder: DateOrder.dmy,
    phoneDialCode: '+44',
    phoneMinDigits: 10,
    phoneMaxDigits: 11,
    supportsSmsQuickEntry: false,
    paymentMethods: const [
      'Cash',
      'Debit Card',
      'Credit Card',
      'Bank Transfer',
      'Direct Debit',
      'Digital Wallet',
    ],
    banks: _intlBanks(const [
      ('barclays', 'Barclays'),
      ('hsbc', 'HSBC UK'),
      ('lloyds', 'Lloyds Bank'),
      ('natwest', 'NatWest'),
      ('santander_uk', 'Santander UK'),
      ('monzo', 'Monzo'),
      ('revolut', 'Revolut'),
    ]),
  );

  static final _europe = RegionConfig(
    region: AppRegion.europe,
    currencyCode: 'EUR',
    currencySymbol: '€',
    dateOrder: DateOrder.dmy,
    phoneDialCode: '+49',
    phoneMinDigits: 8,
    phoneMaxDigits: 12,
    supportsSmsQuickEntry: false,
    paymentMethods: const [
      'Cash',
      'Debit Card',
      'Credit Card',
      'Bank Transfer',
      'SEPA',
      'Digital Wallet',
    ],
    banks: _intlBanks(const [
      ('deutsche', 'Deutsche Bank'),
      ('bnp', 'BNP Paribas'),
      ('ing', 'ING'),
      ('santander', 'Santander'),
      ('unicredit', 'UniCredit'),
      ('n26', 'N26'),
      ('revolut_eu', 'Revolut'),
    ]),
  );

  static final _international = RegionConfig(
    region: AppRegion.international,
    currencyCode: 'USD',
    currencySymbol: r'$',
    dateOrder: DateOrder.dmy,
    phoneDialCode: '+',
    phoneMinDigits: 7,
    phoneMaxDigits: 15,
    supportsSmsQuickEntry: false,
    paymentMethods: const [
      'Cash',
      'Debit Card',
      'Credit Card',
      'Bank Transfer',
      'Digital Wallet',
    ],
    banks: _intlBanks(const [
      ('generic_bank', 'My bank (auto-detect)'),
      ('hsbc', 'HSBC'),
      ('standard_chartered', 'Standard Chartered'),
      ('citibank', 'Citibank'),
      ('other', 'Other bank'),
    ]),
  );

  static List<RegionalBankOption> _intlBanks(
    List<(String id, String name)> entries,
  ) {
    return [
      const RegionalBankOption(
        id: 'generic',
        displayName: 'Auto-detect from file',
        importBankId: BankId.generic,
      ),
      ...entries.map(
        (entry) => RegionalBankOption(
          id: entry.$1,
          displayName: entry.$2,
          importBankId: BankId.generic,
        ),
      ),
    ];
  }

  RegionalBankOption? bankById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final bank in banks) {
      if (bank.id == id) return bank;
    }
    return null;
  }

  String labelForBankId(String? id) {
    return bankById(id)?.displayName ?? '';
  }

  BankId? importBankIdFor(String? id) {
    return bankById(id)?.importBankId;
  }

  List<RegionalBankOption> get registrationBanks =>
      banks.where((bank) => bank.id != 'generic').toList();

  String get importBankSummary {
    final names = registrationBanks.take(8).map((b) => b.displayName).join(', ');
    final suffix = registrationBanks.length > 8 ? ', and more' : '';
    return 'Banks: $names$suffix. Statement import uses universal Debit/Credit columns.';
  }
}
