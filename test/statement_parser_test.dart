import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:household_expense/models/bank_profile.dart';
import 'package:household_expense/services/bank_detector.dart';
import 'package:household_expense/services/csv_reader_service.dart';
import 'package:household_expense/services/pdf_statement_parser.dart';
import 'package:household_expense/services/transaction_parser.dart';

void main() {
  final reader = CsvReaderService();
  final detector = BankDetector();

  group('Axis Bank CSV', () {
    test('parses real statement with inverted DR/CR', () {
      final file = File('savings/AcctStatement_XXX9624_28062026.csv');
      final rows = reader.readCsvContent(file.readAsStringSync());
      final bank = detector.detect(rows: rows, fileName: file.path);
      expect(bank.id, BankId.axis);

      final txns = TransactionParser(bankProfile: bank).parse(rows);
      expect(txns.length, greaterThan(50));

      final achDebit = txns.firstWhere(
        (t) => t.description.contains('ACH-DR-TP ACH INDIANESIGN'),
      );
      expect(achDebit.isDebit, isTrue);
      expect(achDebit.amount, 2000.0);

      final neftCredit = txns.firstWhere(
        (t) => t.description.contains('MUNITIONS INDIA LTD'),
      );
      expect(neftCredit.isDebit, isFalse);
    });

    test('standard Withdrawal/Deposit headers keep normal semantics for PDF/XLS', () {
      final rows = [
        ['Date', 'Description', 'Withdrawal', 'Deposit', 'Balance'],
        ['01/04/2026', 'UPI PAYMENT', '500.00', '', '10000.00'],
        ['02/04/2026', 'SALARY CREDIT', '', '62000.00', '72000.00'],
      ];
      final bank = BankProfile.axis;
      final txns = TransactionParser(bankProfile: bank).parse(rows);

      expect(txns.length, 2);
      expect(txns[0].isDebit, isTrue);
      expect(txns[1].isDebit, isFalse);
    });

    test('CSV DR/CR column layout uses inverted semantics', () {
      final rows = [
        ['Tran Date', 'CHQNO', 'PARTICULARS', 'DR', 'CR', 'BAL'],
        ['01/04/2026', '-', 'ACH-DR-UPI PAYMENT', '', '500.00', '10000.00'],
        ['02/04/2026', '-', 'SALARY CREDIT', '62000.00', '', '72000.00'],
      ];
      final bank = BankProfile.axis;
      final txns = TransactionParser(bankProfile: bank).parse(rows);

      expect(txns.length, 2);
      expect(txns[0].isDebit, isTrue);
      expect(txns[1].isDebit, isFalse);
    });

    test('XLS export uses standard DR/CR semantics with balance check', () {
      final rows = [
        ['SRL N', 'Tran Date', 'CHQNO', 'PARTICULARS', 'DR', 'CR', 'BAL', 'SOL'],
        ['', '', '', 'OPENING BALANCE', '', '', '131126.24', ''],
        ['1', '01-07-2026', '-', 'SB:Int.Pd', '', '1068.00', '132194.24', '037'],
        ['2', '01-07-2026', '-', 'ACH-DR-TP ACH INDIANESIGN', '2000.00', '', '130194.24', '037'],
      ];
      final bank = BankProfile.axis;
      final txns = TransactionParser(bankProfile: bank).parse(rows);

      expect(txns.length, 2);
      expect(txns[0].description, contains('Int.Pd'));
      expect(txns[0].isDebit, isFalse);
      expect(txns[0].amount, 1068.0);
      expect(txns[1].description, contains('ACH-DR'));
      expect(txns[1].isDebit, isTrue);
      expect(txns[1].amount, 2000.0);
    });
  });

  group('HDFC Bank CSV', () {
    test('detects bank and parses withdrawal/deposit columns', () {
      const csv = '''
Date,Narration,Chq./Ref.No.,Value Dt,Withdrawal Amt.,Deposit Amt.,Closing Balance
01/04/2026,UPI-SWIGGY-123,,01/04/2026,249.00,,35751.00
02/04/2026,SALARY MAR 2026-INFOSYS,,02/04/2026,,62000.00,97751.00
''';
      final rows = reader.readCsvContent(csv);
      final bank = detector.detect(rows: rows);
      expect(bank.id, BankId.hdfc);

      final txns = TransactionParser(bankProfile: bank).parse(rows);
      expect(txns.length, 2);
      expect(txns[0].isDebit, isTrue);
      expect(txns[0].amount, 249.0);
      expect(txns[1].isDebit, isFalse);
      expect(txns[1].amount, 62000.0);
    });
  });

  group('ICICI Bank CSV', () {
    test('uses transaction date and remarks columns', () {
      const csv = '''
S No.,Value Date,Transaction Date,Cheque Number,Transaction Remarks,Withdrawal Amount(INR),Deposit Amount(INR),Balance(INR)
1,01/04/2026,02/04/2026,,UPI/merchant/123,500.00,,10000.00
2,03/04/2026,03/04/2026,,NEFT CREDIT, ,1500.00,11500.00
''';
      final rows = reader.readCsvContent(csv);
      final bank = detector.detect(rows: rows);
      expect(bank.id, BankId.icici);

      final txns = TransactionParser(bankProfile: bank).parse(rows);
      expect(txns.length, 2);
      expect(txns[0].date, DateTime(2026, 4, 2));
      expect(txns[0].isDebit, isTrue);
      expect(txns[1].isDebit, isFalse);
    });
  });

  group('SBI CSV', () {
    test('parses debit and credit columns', () {
      const csv = '''
Txn Date,Value Date,Description,Ref No./Cheque No.,Debit,Credit,Balance
01-04-2026,01-04-2026,UPI PAYMENT,REF1,200.00,,14800.00
02-04-2026,02-04-2026,NEFT CREDIT,REF2,,5000.00,19800.00
''';
      final rows = reader.readCsvContent(csv);
      final bank = detector.detect(rows: rows);
      expect(bank.id, BankId.sbi);

      final txns = TransactionParser(bankProfile: bank).parse(rows);
      expect(txns[0].isDebit, isTrue);
      expect(txns[1].isDebit, isFalse);
    });

    test('parses SBI PDF spaced header with Transaction Reference', () {
      const text = '''
State Bank of India
Statement of Account
Page 1 of 3
Page 2 of 3
Date  Transaction Reference  Ref.No./Chq.No.  Credit  Debit  Balance
01/05/2026  UPI/DR/123456/SHOP  -    500.00  10000.00
02/05/2026  NEFT CR SALARY  -  25000.00    35000.00
''';
      final rows = PdfStatementParser().toRows(text, bankId: BankId.sbi);
      final bank = detector.detect(rows: rows, rawText: text);
      expect(bank.id, BankId.sbi);

      final txns = TransactionParser(bankProfile: bank).parse(rows);
      expect(txns.length, 2);
      expect(txns[0].description, contains('UPI'));
      expect(txns[0].isDebit, isTrue);
      expect(txns[1].description, contains('SALARY'));
      expect(txns[1].isDebit, isFalse);
    });

    test('parses SBI PDF vertical layout from page 3', () {
      const text = '''
State Bank of India
Statement of Account
Page 1 of 3
Page 2 of 3
Date
Transaction Reference
Ref.No./Chq.No.
Credit
Debit
Balance
01/05/2026
UPI/DR/123456/SHOP
-
500.00
10000.00
02/05/2026
NEFT CR SALARY
-
25000.00
35000.00
''';
      final rows = PdfStatementParser().toRows(text, bankId: BankId.sbi);
      final bank = detector.detect(rows: rows, rawText: text);
      expect(bank.id, BankId.sbi);

      final txns = TransactionParser(bankProfile: bank).parse(rows);
      expect(txns.length, 2);
      expect(txns[0].isDebit, isTrue);
      expect(txns[1].isDebit, isFalse);
    });

    test('parses SBI PDF vertical layout with null placeholder row', () {
      const text = '''
Date
Transaction Reference
Ref.No./Chq.No.
Credit
Debit
Balance
null
null
null
null
null
null
08-05-26
PMSBY RENEWAL SBISB09063261270012427848
-
0
20.00
2730.44
08-05-26
PMJJBY RENEWAL SBIJB09063261270020727186
-
0
436.00
2294.44
''';
      final rows = PdfStatementParser().toRows(text, bankId: BankId.sbi);
      final bank = detector.detect(rows: rows, rawText: text);
      final txns = TransactionParser(bankProfile: bank).parse(rows);

      expect(txns.length, 2);
      expect(txns[0].description, contains('PMSBY'));
      expect(txns[0].amount, 20.0);
      expect(txns[0].isDebit, isTrue);
      expect(txns[1].description, contains('PMJJBY'));
      expect(txns[1].amount, 436.0);
      expect(txns[1].isDebit, isTrue);
    });
  });

  group('Bank of Baroda CSV', () {
    test('parses withdrawal and deposit columns', () {
      const csv = '''
TRAN DATE,VALUE DATE,NARRATION,CHQ.NO.,WITHDRAWAL(DR),DEPOSIT(CR),BALANCE(INR)
01/04/2026,01/04/2026,UPI MERCHANT,,-,500.00,10000.00
02/04/2026,02/04/2026,ATM CASH,CHQ1,1000.00,-,9000.00
''';
      final rows = reader.readCsvContent(csv);
      final bank = detector.detect(rows: rows);
      expect(bank.id, BankId.bob);

      final txns = TransactionParser(bankProfile: bank).parse(rows);
      expect(txns[0].isDebit, isFalse);
      expect(txns[1].isDebit, isTrue);
    });
  });

  group('PNB CSV', () {
    test('parses particulars with withdrawal/deposit', () {
      const csv = '''
Date,Particulars,Chq No,Withdrawal,Deposit,Balance
01/04/2026,UPI MERCHANT,,100.00,,9900.00
02/04/2026,SALARY,,,25000.00,34900.00
''';
      final rows = reader.readCsvContent(csv);
      final bank = detector.detect(rows: rows);
      expect(bank.id, anyOf(BankId.pnb, BankId.generic));

      final txns = TransactionParser(bankProfile: bank).parse(rows);
      expect(txns[0].isDebit, isTrue);
      expect(txns[1].isDebit, isFalse);
    });
  });

  group('AU Bank CSV', () {
    test('parses standard debit credit layout', () {
      const csv = '''
Transaction Date,Value Date,Description,Ref No,Cheque No,Debit,Credit,Balance
01-04-2026,01-04-2026,UPI PAY,REF,,50.00,,5000.00
02-04-2026,02-04-2026,IMPS IN,REF2,,,1200.00,6200.00
''';
      final rows = reader.readCsvContent(csv);
      final bank = detector.detect(rows: rows, fileName: 'au_statement.csv');
      expect(bank.id, anyOf(BankId.au, BankId.generic));

      final txns = TransactionParser(bankProfile: bank).parse(rows);
      expect(txns[0].isDebit, isTrue);
      expect(txns[1].isDebit, isFalse);
    });
  });

  group('CBI Excel', () {
    test('parses post date debit credit rows with balance suffix', () {
      final rows = [
        ['Central Bank of India'],
        [
          'Post Date',
          'Value Date',
          'Branch Code',
          'Cheque Number',
          'Transaction Description',
          'Debit',
          'Credit',
          'Balance',
        ],
        [
          '11/05/2026',
          '11/05/2026',
          '664',
          '',
          'UPI/RRN 589522776943/UPI Intent',
          '117.00',
          '',
          '5,29,206.04 CR',
        ],
        [
          '13/05/2026',
          '13/05/2026',
          '664',
          '',
          'UPI/RRN 649976060029/UPI_Mrs Guriya Kumari Mrs Gur',
          '',
          '1,100.00',
          '5,30,306.04 CR',
        ],
      ];
      final bank = detector.detect(rows: rows);
      final txns = TransactionParser(bankProfile: bank).parse(rows);

      expect(bank.id, BankId.cbi);
      expect(txns.length, 2);
      expect(txns[0].isDebit, isTrue);
      expect(txns[0].amount, 117.0);
      expect(txns[1].isDebit, isFalse);
      expect(txns[1].amount, 1100.0);
    });
  });

  group('PDF loose text', () {
    test('parses comma-separated PDF text', () {
      const text = '''
HDFC BANK
Date,Narration,Withdrawal,Deposit,Balance
01/04/2026,UPI-SWIGGY-123,249.00,,35751.00
02/04/2026,SALARY MAR 2026,,62000.00,97751.00
''';
      final rows = PdfStatementParser().toRows(text);
      final bank = detector.detect(rows: rows);
      final txns = TransactionParser(bankProfile: bank).parse(rows);

      expect(txns.length, 2);
      expect(txns[0].isDebit, isTrue);
      expect(txns[1].isDebit, isFalse);
    });

    test('parses spaced PDF text with month name dates', () {
      const text = '''
01-Apr-2026 UPI/GROWW/12345 5000.00 45000.00
02-Apr-2026 SALARY CREDIT 62000.00 107000.00
''';
      final rows = PdfStatementParser().toRows(text);
      final txns = TransactionParser(bankProfile: detector.detect(rows: rows))
          .parse(rows);

      expect(txns.length, 2);
      expect(txns[0].isDebit, isTrue);
      expect(txns[1].isDebit, isFalse);
    });

    test('parses vertical PDF layout with one field per line', () {
      const text = '''
Statement of Account
Tran Date
Value Date
Narration
Debit
Credit
Balance
01/04/2026
01/04/2026
UPI-SWIGGY-FOOD
249.00
35751.00
02/04/2026
02/04/2026
SALARY CREDIT
62000.00
97751.00
''';
      final rows = PdfStatementParser().toRows(text);
      final txns = TransactionParser(bankProfile: detector.detect(rows: rows))
          .parse(rows);

      expect(txns.length, 2);
      expect(txns[0].isDebit, isTrue);
      expect(txns[1].isDebit, isFalse);
    });

    test('parses ISO date format from PDF text', () {
      const text = '''
2026-04-01 UPI AMAZON PAY 1299.00 38452.00
2026-04-02 NEFT SALARY CREDIT 62000.00 100452.00
''';
      final rows = PdfStatementParser().toRows(text);
      final txns = TransactionParser(bankProfile: detector.detect(rows: rows))
          .parse(rows);

      expect(txns.length, 2);
      expect(txns[0].isDebit, isTrue);
      expect(txns[1].isDebit, isFalse);
    });

    test('parses CBI vertical PDF with single amount column', () {
      const text = '''
Central Bank of India
IFSC Code: CBIN0280664
Post Date
Value
Date
Branch
Code
Cheque
Number
Transaction Description
Debit
Credit
Balance
01/03/2026
01/03/2026
664
UPI/RRN100042648930/SubscriptionICCL 0099356461
 2,500.00
 4,34,483.47 CR
03/03/2026
03/03/2026
664
RAIL VIKAS NIGAM LIM1109122
 80.00
 4,34,563.47 CR
16/03/2026
16/03/2026
664
NEFT Mr. BHAGWANSINGH/XUTR/MAHBH00645400217
 45,000.00
 4,79,563.47 CR
''';
      final rows = PdfStatementParser().toRows(text);
      final bank = detector.detect(rows: rows, rawText: text);
      expect(bank.id, BankId.cbi);

      final txns = TransactionParser(bankProfile: bank).parse(rows);
      expect(txns.length, 3);
      expect(txns[0].isDebit, isTrue);
      expect(txns[0].amount, 2500.0);
      expect(txns[0].description, isNot(contains('664')));
      expect(txns[1].isDebit, isFalse);
      expect(txns[1].amount, 80.0);
      expect(txns[2].isDebit, isFalse);
      expect(txns[2].amount, 45000.0);
    });
  });
}
