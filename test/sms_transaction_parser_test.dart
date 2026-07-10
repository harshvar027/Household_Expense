import 'package:flutter_test/flutter_test.dart';
import 'package:household_expense/services/sms_transaction_parser.dart';

void main() {
  group('SmsTransactionParser', () {
    test('parses debit UPI SMS', () {
      final parsed = SmsTransactionParser.parse(
        'Rs.499.00 debited from A/c **1234 on 01-Jul-26. '
        'Info: SWIGGY*BLR. UPI Ref 123456789012',
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, 499);
      expect(parsed.isDebit, isTrue);
      expect(parsed.description.toLowerCase(), contains('swiggy'));
      expect(parsed.paymentMethod, 'UPI');
    });

    test('parses credit salary SMS', () {
      final parsed = SmsTransactionParser.parse(
        'A/c XX1234 credited with Rs. 75,000.00 on 01-07-2026. '
        'Salary credit from ACME CORP',
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, 75000);
      expect(parsed.isDebit, isFalse);
      expect(parsed.suggestedCategory, 'Salary');
    });

    test('ignores OTP SMS', () {
      final parsed = SmsTransactionParser.parse(
        '123456 is your OTP for login. Do not share with anyone.',
      );

      expect(parsed, isNull);
    });

    test('parses card spend SMS', () {
      final parsed = SmsTransactionParser.parse(
        'INR 1,250.50 spent on HDFC Bank Credit Card ending 4321 at AMAZON on 02-Jul-26',
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, 1250.50);
      expect(parsed.isDebit, isTrue);
      expect(parsed.paymentMethod, 'Credit Card');
    });

    test('detects investment hint', () {
      final parsed = SmsTransactionParser.parse(
        'Rs.5000.00 debited from A/c **1234 on 01-Jul-26. SIP Groww Mutual Fund',
      );

      expect(parsed, isNotNull);
      expect(parsed!.isInvestmentHint, isTrue);
    });
  });
}
