import 'package:flutter_test/flutter_test.dart';
import 'package:household_expense/utils/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('validates email', () {
      expect(AuthValidators.email('test@example.com'), isNull);
      expect(AuthValidators.email('bad-email'), isNotNull);
    });

    test('validates phone', () {
      expect(AuthValidators.phone('9876543210'), isNull);
      expect(AuthValidators.phone('123'), isNotNull);
    });

    test('validates pin', () {
      expect(AuthValidators.pin('1234'), isNull);
      expect(AuthValidators.pin('12'), isNotNull);
    });

    test('normalizes phone with country code', () {
      expect(AuthValidators.normalizePhone('919876543210'), '9876543210');
    });
  });
}
