import 'package:flutter_test/flutter_test.dart';
import 'package:household_expense/utils/account_label.dart';

void main() {
  test('formatAccountNote and parse round-trip', () {
    const note = 'Account: Sangeeta';
    expect(formatAccountNote('Sangeeta'), note);
    expect(accountNameFromNote(note), 'Sangeeta');
    expect(
      accountNameFromNote('Account: Sangeeta\nBank: CBI'),
      'Sangeeta',
    );
    expect(bankNameFromNote('Account: Sangeeta\nBank: CBI'), 'CBI');
  });

  test('buildPaymentMeta combines bank, account, and method', () {
    expect(
      buildPaymentMeta(
        paymentMethod: 'Bank',
        bankName: 'CBI',
        accountName: 'Sangeeta',
      ),
      'Bank · CBI · Sangeeta',
    );
  });

  test('buildImportNotes stores indicative labels', () {
    expect(
      buildImportNotes(accountName: 'Sangeeta', bankName: 'CBI'),
      'Account: Sangeeta\nBank: CBI',
    );
  });
}
