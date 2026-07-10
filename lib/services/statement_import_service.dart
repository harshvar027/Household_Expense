import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';

import '../utils/file_type_groups.dart';
import '../utils/file_type_sniffer.dart';
import '../database/database_helper.dart';
import '../models/bank_transaction.dart';
import '../services/auth_service.dart';
import '../services/bank_detector.dart';
import '../services/category_detector.dart';
import '../services/entitlement_service.dart';
import '../models/subscription_tier.dart';
import '../models/bank_profile.dart';
import '../services/statement_reader_service.dart';
import '../services/transaction_parser.dart';

class PickedStatementFile {
  final String name;
  final Uint8List bytes;
  final String? mimeType;

  const PickedStatementFile({
    required this.name,
    required this.bytes,
    this.mimeType,
  });
}

class StatementImportService {
  static const _androidChannel =
      MethodChannel('com.householdexpense.app/file_picker');

  final _reader = StatementReaderService();
  final _bankDetector = BankDetector();

  Future<List<BankTransaction>?> pickAndImport({String? pdfPassword}) async {
    await EntitlementService.instance.requireFeature(AppFeature.importStatement);
    final picked = await pickStatementFile();
    if (picked == null) return null;
    return importStatement(picked, pdfPassword: pdfPassword);
  }

  Future<PickedStatementFile?> pickStatementFile() async {
    final picked = await _pickStatementFile();
    if (picked == null) return null;

    final (name, bytes, mimeType) = picked;
    return PickedStatementFile(name: name, bytes: bytes, mimeType: mimeType);
  }

  Future<List<BankTransaction>> importStatement(
    PickedStatementFile file, {
    String? pdfPassword,
    BankId? bankId,
  }) async {
    final resolvedName = FileTypeSniffer.resolveFileName(
      fileName: file.name,
      bytes: file.bytes,
      mimeType: file.mimeType,
    );
    final ext = resolvedName.contains('.')
        ? resolvedName.split('.').last.toLowerCase()
        : '';
    if (!['csv', 'xlsx', 'xls', 'pdf'].contains(ext)) {
      throw Exception('Please select a CSV, Excel (.xls/.xlsx), or PDF statement.');
    }

    final readResult = _reader.read(
      resolvedName,
      file.bytes,
      mimeType: file.mimeType,
      pdfPassword: pdfPassword,
      bankId: bankId,
    );
    final detected = _bankDetector.detect(
      rows: readResult.rows,
      fileName: resolvedName,
      rawText: readResult.rawText,
    );
    final bank = BankProfile.resolve(selected: bankId, detected: detected);
    final transactions = TransactionParser(bankProfile: bank).parse(
      readResult.rows,
    );
    final dbCategories = await DatabaseHelper.instance.getCategories();

    for (final t in transactions) {
      if (t.isDebit) {
        t.category = await CategoryDetector.detectExpense(t, dbCategories);
      }

      t.duplicate = await DatabaseHelper.instance.transactionExists(t);

      if (t.duplicate) {
        t.selected = false;
      }
    }

    return transactions;
  }

  Future<(String name, Uint8List bytes, String? mimeType)?> _pickStatementFile() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _pickOnAndroid();
    }

    return _pickWithFileSelector();
  }

  Future<(String name, Uint8List bytes, String? mimeType)?> _pickOnAndroid() async {
    AuthService.instance.beginBackgroundLockSuppress();
    try {
      final result = await _androidChannel
          .invokeMethod<Map<Object?, Object?>>('pickStatement')
          .timeout(
            const Duration(seconds: 120),
            onTimeout: () => throw Exception(
              'File picker did not open. Tap the button again and choose your statement.',
            ),
          );

      if (result == null) return null;

      final name = result['name'] as String? ?? 'statement';
      final mimeType = result['mimeType'] as String?;
      final path = result['path'] as String?;
      if (path != null) {
        return (name, await File(path).readAsBytes(), mimeType);
      }

      final bytes = result['bytes'];
      if (bytes is Uint8List) {
        return (name, bytes, mimeType);
      }

      throw Exception('Could not read the selected statement file.');
    } finally {
      AuthService.instance.endBackgroundLockSuppress();
    }
  }

  Future<(String name, Uint8List bytes, String? mimeType)?> _pickWithFileSelector() async {
    AuthService.instance.beginBackgroundLockSuppress();
    try {
      final XFile? file = await openFile(
        acceptedTypeGroups: [FileTypeGroups.bankStatement],
        confirmButtonText: 'Select Statement',
      );

      if (file == null) return null;

      return (file.name, await file.readAsBytes(), file.mimeType);
    } finally {
      AuthService.instance.endBackgroundLockSuppress();
    }
  }
}

/// Backward-compatible alias.
typedef CsvImportService = StatementImportService;
