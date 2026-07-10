import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_region.dart';
import '../utils/auth_validators.dart';

/// Remembers that this device already has a household account / trial anchor.
///
/// Survives profile deletion and is included in Android auto-backup so a
/// reinstall on the same Google account can restore the original trial start.
class DeviceEnrollment {
  final DateTime registrationDate;
  final String identityHash;
  final DateTime enrolledAt;

  const DeviceEnrollment({
    required this.registrationDate,
    required this.identityHash,
    required this.enrolledAt,
  });

  Map<String, dynamic> toJson() => {
        'registrationDate': registrationDate.toIso8601String(),
        'identityHash': identityHash,
        'enrolledAt': enrolledAt.toIso8601String(),
      };

  factory DeviceEnrollment.fromJson(Map<String, dynamic> json) {
    return DeviceEnrollment(
      registrationDate: DateTime.parse(json['registrationDate'] as String),
      identityHash: json['identityHash'] as String,
      enrolledAt: DateTime.parse(json['enrolledAt'] as String),
    );
  }
}

class DeviceEnrollmentService {
  DeviceEnrollmentService._();

  static final DeviceEnrollmentService instance = DeviceEnrollmentService._();

  static const _prefKey = 'device_enrollment_v1';
  static const _secureKey = 'secure_device_enrollment_v1';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<bool> isEnrolled() async => (await read()) != null;

  Future<DeviceEnrollment?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final prefRaw = prefs.getString(_prefKey);
    if (prefRaw != null) {
      try {
        return DeviceEnrollment.fromJson(
          jsonDecode(prefRaw) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    final secureRaw = await _readSecure();
    if (secureRaw != null) {
      try {
        final enrollment = DeviceEnrollment.fromJson(
          jsonDecode(secureRaw) as Map<String, dynamic>,
        );
        await prefs.setString(_prefKey, secureRaw);
        return enrollment;
      } catch (_) {}
    }

    return null;
  }

  Future<void> record({
    required String email,
    required String phone,
    required AppRegion region,
    required DateTime registrationDate,
  }) async {
    final enrollment = DeviceEnrollment(
      registrationDate: registrationDate,
      identityHash: identityHashFor(email: email, phone: phone, region: region),
      enrolledAt: DateTime.now(),
    );
    final encoded = jsonEncode(enrollment.toJson());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, encoded);
    await _writeSecure(encoded);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    await _deleteSecure();
  }

  Future<String?> _readSecure() async {
    try {
      return await _secureStorage.read(key: _secureKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSecure(String value) async {
    try {
      await _secureStorage.write(key: _secureKey, value: value);
    } catch (_) {}
  }

  Future<void> _deleteSecure() async {
    try {
      await _secureStorage.delete(key: _secureKey);
    } catch (_) {}
  }

  bool matchesIdentity(
    DeviceEnrollment enrollment, {
    required String email,
    required String phone,
    AppRegion? region,
  }) {
    return enrollment.identityHash ==
        identityHashFor(email: email, phone: phone, region: region);
  }

  static String identityHashFor({
    required String email,
    required String phone,
    AppRegion? region,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = AuthValidators.normalizePhone(
      phone,
      region: region ?? AppRegion.india,
    );
    return base64Url.encode(utf8.encode('$normalizedEmail|$normalizedPhone'));
  }
}
