import 'package:flutter_test/flutter_test.dart';
import 'package:household_expense/exceptions/pdf_password_exception.dart';

void main() {
  group('isPdfPasswordArgumentError', () {
    test('detects Syncfusion password ArgumentError', () {
      final error = ArgumentError.value(
        '',
        'password',
        'Cannot open an encrypted document. The password is invalid.',
      );

      expect(isPdfPasswordArgumentError(error), isTrue);
    });

    test('ignores unrelated ArgumentError', () {
      final error = ArgumentError.value('', 'fileName', 'File not found');

      expect(isPdfPasswordArgumentError(error), isFalse);
    });
  });
}
