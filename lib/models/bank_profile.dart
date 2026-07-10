import '../services/app_locale_service.dart';

/// Known bank statement layouts and amount-column semantics.
enum BankId {
  generic,
  axis,
  hdfc,
  icici,
  sbi,
  bob,
  pnb,
  au,
  indusInd,
  cbi,
}

/// How debit/credit columns map to money in vs money out.
enum AmountSemantics {
  /// Withdrawal / debit column = expense; deposit / credit = income.
  standard,

  /// Short [DR] / [CR] columns where DR = money in and CR = money out (Axis, IndusInd).
  invertedShortDrCr,
}

class BankProfile {
  final BankId id;
  final String displayName;
  final AmountSemantics semantics;

  const BankProfile({
    required this.id,
    required this.displayName,
    required this.semantics,
  });

  static const generic = BankProfile(
    id: BankId.generic,
    displayName: 'Generic',
    semantics: AmountSemantics.standard,
  );

  static const axis = BankProfile(
    id: BankId.axis,
    displayName: 'Axis Bank',
    semantics: AmountSemantics.invertedShortDrCr,
  );

  static const hdfc = BankProfile(
    id: BankId.hdfc,
    displayName: 'HDFC Bank',
    semantics: AmountSemantics.standard,
  );

  static const icici = BankProfile(
    id: BankId.icici,
    displayName: 'ICICI Bank',
    semantics: AmountSemantics.standard,
  );

  static const sbi = BankProfile(
    id: BankId.sbi,
    displayName: 'State Bank of India',
    semantics: AmountSemantics.standard,
  );

  static const bob = BankProfile(
    id: BankId.bob,
    displayName: 'Bank of Baroda',
    semantics: AmountSemantics.standard,
  );

  static const pnb = BankProfile(
    id: BankId.pnb,
    displayName: 'Punjab National Bank',
    semantics: AmountSemantics.standard,
  );

  static const au = BankProfile(
    id: BankId.au,
    displayName: 'AU Small Finance Bank',
    semantics: AmountSemantics.standard,
  );

  static const indusInd = BankProfile(
    id: BankId.indusInd,
    displayName: 'IndusInd Bank',
    semantics: AmountSemantics.invertedShortDrCr,
  );

  static const cbi = BankProfile(
    id: BankId.cbi,
    displayName: 'Central Bank of India',
    semantics: AmountSemantics.standard,
  );

  static const supportedBanks = [
    axis,
    hdfc,
    icici,
    sbi,
    bob,
    pnb,
    au,
    indusInd,
    cbi,
  ];

  static const supportedFormats = ['CSV', 'Excel (.xls/.xlsx)', 'PDF'];

  static BankProfile fromId(BankId id) {
    for (final bank in supportedBanks) {
      if (bank.id == id) return bank;
    }
    return generic;
  }

  static BankId? parseId(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    for (final id in BankId.values) {
      if (id.name == value) return id;
    }
    return null;
  }

  static String labelForId(String? raw) {
    final id = parseId(raw);
    if (id != null) return fromId(id).displayName;
    final regional = AppLocaleService.instance.config.labelForBankId(raw);
    if (regional.isNotEmpty) return regional;
    return '';
  }

  static BankId? importBankIdFromStorage(String? raw) {
    final parsed = parseId(raw);
    if (parsed != null) return parsed;
    if (raw == null || raw.trim().isEmpty) return null;
    return BankId.generic;
  }

  /// Uses the user-selected bank when set; otherwise falls back to auto-detection.
  static BankProfile resolve({
    BankId? selected,
    required BankProfile detected,
  }) {
    if (selected == null || selected == BankId.generic) return detected;
    return fromId(selected);
  }

  static const importBankOptions = [
    generic,
    ...supportedBanks,
  ];
}
