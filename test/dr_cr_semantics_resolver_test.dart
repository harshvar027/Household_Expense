import 'package:flutter_test/flutter_test.dart';
import 'package:household_expense/services/dr_cr_semantics_resolver.dart';
import 'package:household_expense/services/header_detector.dart';

void main() {
  group('DrCrSemanticsResolver', () {
    test('detects standard semantics for Axis XLS layout', () {
      final rows = [
        ['Tran Date', 'PARTICULARS', 'DR', 'CR', 'BAL'],
        ['01-07-2026', 'OPENING BALANCE', '', '', '131126.24'],
        ['01-07-2026', 'Int.Pd', '', '1068.00', '132194.24'],
        ['01-07-2026', 'ACH-DR', '2000.00', '', '130194.24'],
      ];

      final detector = HeaderDetector()..detect(rows[0]);
      final inverted = DrCrSemanticsResolver.resolveFromBalances(
        rows: rows,
        headerIndex: 0,
        detector: detector,
      );

      expect(inverted, isFalse);
    });

    test('detects inverted semantics for Axis CSV layout', () {
      final rows = [
        ['Tran Date', 'PARTICULARS', 'DR', 'CR', 'BAL'],
        ['31-03-2026', 'Int.Pd', '1019.00', '', '110195.56'],
        ['01-04-2026', 'ACH-DR', '', '2000.00', '108195.56'],
      ];

      final detector = HeaderDetector()..detect(rows[0]);
      final inverted = DrCrSemanticsResolver.resolveFromBalances(
        rows: rows,
        headerIndex: 0,
        detector: detector,
      );

      expect(inverted, isTrue);
    });
  });
}
