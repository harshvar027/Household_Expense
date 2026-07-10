import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the SQLCipher database key using platform secure storage.
/// On Android this uses EncryptedSharedPreferences backed by Android Keystore.
class DatabaseKeyService {
  DatabaseKeyService._();

  static final DatabaseKeyService instance = DatabaseKeyService._();

  static const _storageKey = 'household_expense_sqlcipher_key_v1';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  String? _cachedPassword;

  /// Returns the SQLCipher passphrase using a raw 256-bit hex key (no PBKDF2).
  Future<String> getSqlCipherPassword() async {
    if (_cachedPassword != null) return _cachedPassword!;

    var hexKey = await _storage.read(key: _storageKey);
    if (hexKey == null || !_isValidHexKey(hexKey)) {
      hexKey = _generateHexKey();
      await _storage.write(key: _storageKey, value: hexKey);
    }

    _cachedPassword = "x'$hexKey'";
    return _cachedPassword!;
  }

  String _generateHexKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  bool _isValidHexKey(String value) {
    return RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(value);
  }
}
