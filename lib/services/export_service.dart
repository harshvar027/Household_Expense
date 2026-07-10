import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/backup_ui.dart';
import '../utils/file_type_groups.dart';
import '../database/database_helper.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/subscription_tier.dart';
import 'auth_service.dart';
import 'app_locale_service.dart';
import 'backup_crypto_service.dart';
import 'entitlement_service.dart';
import 'pdf_service.dart';

class ExportException implements Exception {
  final String message;
  const ExportException(this.message);

  @override
  String toString() => message;
}

class ExportService {
  static final ExportService instance = ExportService._();
  ExportService._();

  final _db = DatabaseHelper.instance;
  final _pdf = PdfService();

  Future<void> exportMonthlyPdf({
    required String monthLabel,
    required double income,
    required double manualIncome,
    required double importedIncome,
    required double broughtForwardIncome,
    required double budget,
    required double expenses,
    required double investmentTotal,
    required double netBalance,
    required Map<String, double> categoryTotals,
    required Map<String, double> investmentTotals,
    required List<Expense> expenseList,
    required List<Income> incomeList,
    required List<Expense> investmentList,
  }) async {
    await EntitlementService.instance.requireFeature(AppFeature.exportPdf);
    await _pdf.previewPdf(
      month: monthLabel,
      income: income,
      manualIncome: manualIncome,
      importedIncome: importedIncome,
      broughtForwardIncome: broughtForwardIncome,
      budget: budget,
      expenses: expenses,
      investmentTotal: investmentTotal,
      netBalance: netBalance,
      categoryTotals: categoryTotals,
      investmentTotals: investmentTotals,
      expenseList: expenseList,
      incomeList: incomeList,
      investmentList: investmentList,
    );
  }

  Future<String?> exportExpensesCsv(List<Expense> expenses) async {
    await EntitlementService.instance.requireFeature(AppFeature.exportCsv);
    final rows = <List<dynamic>>[
      ['Date', 'Item', 'Category', 'Amount', 'Payment', 'Member', 'Transfer', 'Notes'],
    ];
    final members = await _db.getMembers();
    final memberMap = {for (final m in members) m.id!: m.name};

    for (final e in expenses) {
      rows.add([
        e.expenseDate,
        e.item,
        e.category,
        e.amount.toStringAsFixed(2),
        e.paymentMethod,
        memberMap[e.memberId] ?? '',
        e.isTransfer ? 'Yes' : 'No',
        e.notes,
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    return _saveFile(csv, 'expenses_export.csv', 'CSV');
  }

  /// Full JSON backup: database + monthly budgets + profile (no PIN secrets).
  Future<String?> backupToJson() async {
    await EntitlementService.instance.requireFeature(AppFeature.backup);

    final dbData = await _db.exportAllData();
    final preferences = await exportPortablePreferences();
    final payload = {
      ...dbData,
      'version': 8,
      'preferences': preferences,
    };

    final plaintextJson = encodeBackupJson(payload);
    final encrypted = await BackupCryptoService.instance.encryptJsonPayload(
      plaintextJson,
    );
    final json = encodeBackupJson(encrypted);
    final timestamp = DateTime.now().toIso8601String().split('T').first;
    return _saveFile(
      json,
      'household_expense_backup_$timestamp.json',
      'JSON',
    );
  }

  Future<bool> restoreFromJson() async {
    await EntitlementService.instance.requireFeature(AppFeature.restore);
    try {
      return await AuthService.instance.runWithNativeSheetGuard(() async {
        final file = await openFile(acceptedTypeGroups: [FileTypeGroups.json]);
        if (file == null) return false;

        final content = await File(file.path).readAsString();
        final root = jsonDecode(content) as Map<String, dynamic>;
        final data = await _decodeBackupPayload(root);
        validateBackupPayload(data);

        await _db.restoreAllData(data);
        await restorePortablePreferences(
          data['preferences'] as Map<String, dynamic>?,
        );

        final profile = await AuthService.instance.getProfile();
        AppLocaleService.instance.applyProfile(profile);
        return true;
      });
    } on FormatException catch (e) {
      throw ExportException(e.message);
    } on ExportException {
      rethrow;
    } catch (e) {
      throw ExportException('Could not read backup file: $e');
    }
  }

  Future<Map<String, dynamic>> _decodeBackupPayload(
    Map<String, dynamic> root,
  ) async {
    final schema = root['schema'];
    if (schema is String &&
        schema == 'household_expense_backup_envelope_v1') {
      final plaintext = await BackupCryptoService.instance.decryptJsonPayload(
        root,
      );
      final decoded = jsonDecode(plaintext);
      if (decoded is! Map<String, dynamic>) {
        throw const ExportException('Backup data is not a valid JSON object');
      }
      return decoded;
    }
    return root;
  }

  Future<String?> _saveFile(
    String content,
    String defaultName,
    String label,
  ) async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      return _saveFileMobile(content, defaultName);
    }

    final ext = defaultName.split('.').last.toLowerCase();
    final location = await getSaveLocation(
      suggestedName: defaultName,
      acceptedTypeGroups: [
        ext == 'csv' ? FileTypeGroups.csv : FileTypeGroups.json,
      ],
    );
    if (location == null) return null;

    final file = File(location.path);
    await file.writeAsString(content);
    return location.path;
  }

  Future<String?> _saveFileMobile(String content, String defaultName) async {
    return AuthService.instance.runWithNativeSheetGuard(() async {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$defaultName');
      await file.writeAsString(content, flush: true);

      final xFile = XFile(
        file.path,
        mimeType: 'application/json',
        name: defaultName,
      );
      final result = await Share.shareXFiles(
        [xFile],
        subject: defaultName,
        text:
            'Household expense backup — save this JSON file to Drive, Files, or email.',
      );
      if (result.status == ShareResultStatus.dismissed) {
        return null;
      }
      return file.path;
    });
  }
}
