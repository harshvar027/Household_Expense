import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

/// One-time migration from legacy plaintext SQLite files to SQLCipher.
class DatabaseMigrationService {
  DatabaseMigrationService._();

  static const _sqliteMagic = 'SQLite format 3';
  static const _tables = [
    'categories',
    'expenses',
    'income',
    'bank_transactions',
    'merchant_rules',
    'category_budgets',
    'recurring_transactions',
    'household_members',
    'accounts',
    'goals',
  ];

  static Future<bool> isPlaintextSqliteFile(File file) async {
    if (!await file.exists()) return false;

    final handle = await file.open();
    try {
      final bytes = await handle.read(16);
      if (bytes.length < _sqliteMagic.length) return false;
      return String.fromCharCodes(bytes).startsWith(_sqliteMagic);
    } finally {
      await handle.close();
    }
  }

  static Future<Map<String, dynamic>?> exportPlaintextDatabase(
    String path,
  ) async {
    if (kIsWeb) return null;

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final db = sqlite.sqlite3.open(path, mode: sqlite.OpenMode.readOnly);
    try {
      final data = <String, dynamic>{};
      for (final table in _tables) {
        data[table] = _readTable(db, table);
      }
      return data;
    } catch (_) {
      return null;
    } finally {
      db.dispose();
    }
  }

  static List<Map<String, dynamic>> _readTable(sqlite.Database db, String table) {
    try {
      final result = db.select('SELECT * FROM $table');
      return result
          .map(
            (row) => {
              for (final column in result.columnNames) column: row[column],
            },
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> archivePlaintextFile(File file) async {
    final backupPath = '${file.path}.plaintext.bak';
    if (await File(backupPath).exists()) {
      await file.delete();
      return;
    }
    await file.rename(backupPath);
  }
}
