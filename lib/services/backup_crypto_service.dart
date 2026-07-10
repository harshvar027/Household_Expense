import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BackupCryptoService {
  BackupCryptoService._();

  static final BackupCryptoService instance = BackupCryptoService._();

  static const _keyStorageKey = 'backup_aes_gcm_key_v1';
  static const _algo = 'AES-256-GCM';
  static const _schema = 'household_expense_backup_envelope_v1';
  static const _nonceLength = 12;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final AesGcm _cipher = AesGcm.with256bits();
  final Random _random = Random.secure();

  Future<Map<String, dynamic>> encryptJsonPayload(String plaintextJson) async {
    final keyBytes = await _loadOrCreateKey();
    final nonce = _generateNonce();
    final secretKey = SecretKey(keyBytes);
    final secretBox = await _cipher.encrypt(
      utf8.encode(plaintextJson),
      secretKey: secretKey,
      nonce: nonce,
    );

    return {
      'schema': _schema,
      'alg': _algo,
      'nonce': base64Encode(secretBox.nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
  }

  Future<String> decryptJsonPayload(Map<String, dynamic> envelope) async {
    final schema = envelope['schema'];
    final alg = envelope['alg'];
    if (schema != _schema || alg != _algo) {
      throw const FormatException('Unsupported encrypted backup format');
    }

    final nonce = _asBase64Bytes(envelope['nonce'], 'nonce');
    final cipherText = _asBase64Bytes(envelope['ciphertext'], 'ciphertext');
    final macBytes = _asBase64Bytes(envelope['mac'], 'mac');

    final keyBytes = await _loadOrCreateKey();
    final secretKey = SecretKey(keyBytes);
    final clear = await _cipher.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes)),
      secretKey: secretKey,
    );
    return utf8.decode(clear);
  }

  Future<List<int>> _loadOrCreateKey() async {
    final existing = await _secureStorage.read(key: _keyStorageKey);
    if (existing != null && existing.isNotEmpty) {
      return base64Decode(existing);
    }

    final bytes = Uint8List(32);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    await _secureStorage.write(key: _keyStorageKey, value: base64Encode(bytes));
    return bytes;
  }

  List<int> _generateNonce() {
    final nonce = Uint8List(_nonceLength);
    for (var i = 0; i < nonce.length; i++) {
      nonce[i] = _random.nextInt(256);
    }
    return nonce;
  }

  List<int> _asBase64Bytes(Object? raw, String field) {
    if (raw is! String || raw.isEmpty) {
      throw FormatException('Invalid encrypted backup field: $field');
    }
    return base64Decode(raw);
  }
}
