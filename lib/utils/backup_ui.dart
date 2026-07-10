import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/export_service.dart';
import '../services/entitlement_service.dart';
import '../services/auth_service.dart';

enum BackupDestination { local, cloud }

/// Runs JSON backup with progress UI and user-visible errors.
Future<void> runBackupFlow(
  BuildContext context, {
  BackupDestination destination = BackupDestination.local,
}) async {
  if (!context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing backup…'),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    final path = await AuthService.instance.runWithNativeSheetGuard(
      () => ExportService.instance.backupToJson(),
    );
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path != null
              ? destination == BackupDestination.cloud
                    ? 'Encrypted backup ready — choose Drive, Dropbox, or email in the share sheet'
                    : 'Backup ready — choose Save to Drive, Files, or email in the share sheet'
              : 'Backup cancelled',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  } on EntitlementException catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Backup failed: $e'),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}

/// Shortcut for explicit cloud-save intent via share sheet.
Future<void> runCloudBackupFlow(BuildContext context) async {
  await runBackupFlow(
    context,
    destination: BackupDestination.cloud,
  );
}

/// Runs JSON restore with progress UI and user-visible errors.
Future<bool> runRestoreFlow(BuildContext context) async {
  if (!context.mounted) return false;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Restoring backup…'),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    final ok = await AuthService.instance.runWithNativeSheetGuard(
      () => ExportService.instance.restoreFromJson(),
    );
    if (!context.mounted) return false;
    Navigator.of(context, rootNavigator: true).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Restore completed successfully' : 'Restore cancelled',
        ),
      ),
    );
    return ok;
  } on EntitlementException catch (e) {
    if (!context.mounted) return false;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
    return false;
  } on ExportException catch (e) {
    if (!context.mounted) return false;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message)),
    );
    return false;
  } catch (e) {
    if (!context.mounted) return false;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Restore failed: $e'),
        duration: const Duration(seconds: 6),
      ),
    );
    return false;
  }
}

/// Keys safe to include in portable backup (never PIN/password hashes).
const _portablePreferencePrefixes = ['budget_', 'total_', 'cat_'];
const _portablePreferenceKeys = {
  'user_profile_v1',
  'user_biometric_enabled_v1',
};

Future<Map<String, dynamic>> exportPortablePreferences() async {
  final prefs = await SharedPreferences.getInstance();
  final exported = <String, dynamic>{};

  for (final key in prefs.getKeys()) {
    if (_portablePreferenceKeys.contains(key) ||
        _portablePreferencePrefixes.any((prefix) => key.startsWith(prefix))) {
      final value = prefs.get(key);
      if (value != null) {
        exported[key] = value;
      }
    }
  }

  exported['entitlement'] =
      await EntitlementService.instance.exportEntitlementMeta();
  return exported;
}

Future<void> restorePortablePreferences(Map<String, dynamic>? raw) async {
  if (raw == null) return;

  final copy = Map<String, dynamic>.from(raw);
  final entitlement = copy.remove('entitlement');

  final prefs = await SharedPreferences.getInstance();
  for (final entry in copy.entries) {
    final key = entry.key;
    final value = entry.value;
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is List) {
      await prefs.setStringList(
        key,
        value.map((e) => e.toString()).toList(),
      );
    }
  }

  if (entitlement is Map) {
    await EntitlementService.instance.importEntitlementMeta(
      Map<String, dynamic>.from(entitlement),
    );
  }
}

void validateBackupPayload(Map<String, dynamic> data) {
  if (!data.containsKey('version')) {
    throw const FormatException('This file is not a household expense backup');
  }
  final version = data['version'];
  if (version is! int || version < 7) {
    throw FormatException('Unsupported backup version: $version');
  }
}

String encodeBackupJson(Map<String, dynamic> data) {
  return const JsonEncoder.withIndent('  ').convert(data);
}
