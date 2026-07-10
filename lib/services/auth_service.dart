import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/dev_auth_config.dart';
import '../database/database_helper.dart';
import '../models/app_region.dart';
import '../models/household_member.dart';
import '../models/registration_guard.dart';
import '../models/user_profile.dart';
import '../utils/auth_validators.dart';
import 'app_locale_service.dart';
import 'device_enrollment_service.dart';
import 'entitlement_service.dart';

enum AuthLockMethod { pin, password }

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _profileKey = 'user_profile_v1';
  static const _pinHashKey = 'user_pin_hash_v1';
  static const _passwordHashKey = 'user_password_hash_v1';
  static const _authMethodKey = 'user_auth_method_v1';
  static const _loggedInKey = 'user_logged_in_v1';
  static const _biometricEnabledKey = 'user_biometric_enabled_v1';
  static const _securePinHashKey = 'secure_user_pin_hash_v1';
  static const _securePasswordHashKey = 'secure_user_password_hash_v1';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Nested counter so nested file pickers / share sheets don't unlock early.
  int _backgroundLockSuppressCount = 0;

  bool get isBackgroundLockSuppressed => _backgroundLockSuppressCount > 0;

  /// Call around native UI that pauses the Flutter activity (file picker, etc.).
  void beginBackgroundLockSuppress() => _backgroundLockSuppressCount++;

  void endBackgroundLockSuppress() {
    if (_backgroundLockSuppressCount > 0) {
      _backgroundLockSuppressCount--;
    }
  }

  /// Keeps the session alive while native share sheets / file pickers pause the app.
  ///
  /// External intents (email composer, share sheet, file picker) can return before
  /// the activity fully backgrounds or resumes, so we track lifecycle transitions
  /// for the whole guarded window and only end suppression after the app is back.
  Future<T> runWithNativeSheetGuard<T>(Future<T> Function() action) async {
    beginBackgroundLockSuppress();
    final tracker = _NativeSheetLifecycleTracker();
    WidgetsBinding.instance.addObserver(tracker);
    try {
      final result = await action();
      await tracker.waitForForegroundCycleIfNeeded();
      return result;
    } finally {
      WidgetsBinding.instance.removeObserver(tracker);
      endBackgroundLockSuppress();
    }
  }

  /// Clears in-app session so the lock screen is shown (cold start / background).
  Future<void> prepareForLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
  }

  Future<void> endSession() async {
    await prepareForLaunch();
  }

  Future<void> unlockSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
  }

  Future<bool> hasProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_profileKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  Future<AuthLockMethod> getAuthLockMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_authMethodKey);
    return raw == 'password' ? AuthLockMethod.password : AuthLockMethod.pin;
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<UserProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    final profile = UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    AppLocaleService.instance.applyProfile(profile);
    return profile;
  }

  Future<void> register({
    required UserProfile profile,
    required String pin,
  }) async {
    if (DevAuthConfig.canBypassRegistrationGuard && await hasProfile()) {
      await clearProfile();
    }

    final check = await checkRegistrationAllowed(
      email: profile.email,
      phone: profile.phone,
      region: AppRegion.fromStorage(profile.region),
    );
    if (!check.allowed) {
      throw AuthException(check.message);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    AppLocaleService.instance.applyProfile(profile);
    await _writeSecretHashes(
      pinHash: _hashSecret(pin),
      passwordHash: null,
    );
    await prefs.remove(_pinHashKey);
    await prefs.remove(_passwordHashKey);
    await prefs.setString(_authMethodKey, 'pin');
    await prefs.setBool(_biometricEnabledKey, false);
    await prefs.setBool(_loggedInKey, true);

    final activeRegion = AppRegion.fromStorage(profile.region);
    final enrollment = await DeviceEnrollmentService.instance.read();
    final registrationDate =
        enrollment != null &&
                DeviceEnrollmentService.instance.matchesIdentity(
                  enrollment,
                  email: profile.email,
                  phone: profile.phone,
                  region: activeRegion,
                )
            ? enrollment.registrationDate
            : DateTime.now();

    await EntitlementService.instance.setRegistrationDate(registrationDate);
    await DeviceEnrollmentService.instance.record(
      email: profile.email,
      phone: profile.phone,
      region: activeRegion,
      registrationDate: registrationDate,
    );
    await _syncHouseholdMember(profile.name);
    await DatabaseHelper.instance.setupInitialAccountFromRegistration(profile);
  }

  /// Unlock with PIN or password (local device — no identifier needed).
  Future<bool> unlockWithSecret(String secret) async {
    if (!await _verifySecret(secret)) return false;
    await unlockSession();
    return true;
  }

  Future<bool> login({
    required String identifier,
    required String secret,
  }) async {
    final profile = await getProfile();
    if (profile == null) return false;

    final normalizedId = AuthValidators.normalizePhone(
      identifier,
      region: AppRegion.fromStorage(profile.region),
    );
    final matchesEmail =
        profile.email.toLowerCase() == identifier.trim().toLowerCase();
    final matchesPhone = profile.phone == normalizedId;

    if (!matchesEmail && !matchesPhone) return false;
    if (!await _verifySecret(secret)) return false;

    await unlockSession();
    return true;
  }

  Future<bool> verifyCurrentSecret(String secret) => _verifySecret(secret);

  Future<void> changePin({
    required String currentSecret,
    required String newPin,
  }) async {
    if (!await _verifySecret(currentSecret)) {
      throw AuthException('Current PIN or password is incorrect');
    }

    final prefs = await SharedPreferences.getInstance();
    await _writeSecretHashes(pinHash: _hashSecret(newPin));
    await prefs.setString(_authMethodKey, 'pin');
  }

  Future<void> setPassword({
    required String currentSecret,
    required String newPassword,
  }) async {
    if (!await _verifySecret(currentSecret)) {
      throw AuthException('Current PIN or password is incorrect');
    }

    final prefs = await SharedPreferences.getInstance();
    await _writeSecretHashes(passwordHash: _hashSecret(newPassword));
    await prefs.setString(_authMethodKey, 'password');
  }

  Future<void> switchToPin({
    required String currentSecret,
    required String newPin,
  }) async {
    await changePin(currentSecret: currentSecret, newPin: newPin);
  }

  Future<void> logout() async {
    await endSession();
  }

  /// Verifies email + phone against the profile stored on this device.
  bool identityMatches(
    UserProfile profile,
    String email,
    String phone, {
    AppRegion? region,
  }) {
    final activeRegion = region ?? AppRegion.fromStorage(profile.region);
    final normalizedPhone =
        AuthValidators.normalizePhone(phone, region: activeRegion);
    return profile.email.trim().toLowerCase() == email.trim().toLowerCase() &&
        profile.phone == normalizedPhone;
  }

  /// Blocks duplicate accounts on one device; also catches re-register with same identity.
  Future<RegistrationCheck> checkRegistrationAllowed({
    String? email,
    String? phone,
    AppRegion? region,
  }) async {
    if (DevAuthConfig.canBypassRegistrationGuard) {
      return const RegistrationCheck(reason: RegistrationBlockReason.allowed);
    }

    final profile = await getProfile();
    if (profile != null) {
      final maskedEmail = _maskEmail(profile.email);
      final maskedPhone = _maskPhone(profile.phone);

      if (email != null &&
          phone != null &&
          email.trim().isNotEmpty &&
          phone.trim().isNotEmpty) {
        final activeRegion = region ?? AppRegion.fromStorage(profile.region);
        if (identityMatches(profile, email, phone, region: activeRegion)) {
          return RegistrationCheck(
            reason: RegistrationBlockReason.identityMatchesExisting,
            maskedEmail: maskedEmail,
            maskedPhone: maskedPhone,
          );
        }
      }

      return RegistrationCheck(
        reason: RegistrationBlockReason.deviceAlreadyRegistered,
        maskedEmail: maskedEmail,
        maskedPhone: maskedPhone,
      );
    }

    final enrollment = await DeviceEnrollmentService.instance.read();
    if (enrollment == null) {
      return const RegistrationCheck(reason: RegistrationBlockReason.allowed);
    }

    if (email != null &&
        phone != null &&
        email.trim().isNotEmpty &&
        phone.trim().isNotEmpty &&
        DeviceEnrollmentService.instance.matchesIdentity(
          enrollment,
          email: email,
          phone: phone,
          region: region,
        )) {
      return const RegistrationCheck(reason: RegistrationBlockReason.allowed);
    }

    return const RegistrationCheck(
      reason: RegistrationBlockReason.deviceAlreadyRegistered,
    );
  }

  /// Resets PIN or password after local identity check (no SMS/email — free).
  Future<void> resetLockAfterIdentityCheck({
    required String email,
    required String phone,
    required String newSecret,
    AuthLockMethod method = AuthLockMethod.pin,
  }) async {
    final profile = await getProfile();
    if (profile == null) {
      throw const AuthException('No account found on this device');
    }

    if (!identityMatches(profile, email, phone)) {
      throw const AuthException(
        'Email and mobile number do not match the account on this device',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    if (method == AuthLockMethod.password) {
      await _writeSecretHashes(
        pinHash: null,
        passwordHash: _hashSecret(newSecret),
      );
      await prefs.remove(_pinHashKey);
      await prefs.setString(_authMethodKey, 'password');
    } else {
      await _writeSecretHashes(
        pinHash: _hashSecret(newSecret),
        passwordHash: null,
      );
      await prefs.remove(_passwordHashKey);
      await prefs.setString(_authMethodKey, 'pin');
    }
    await prefs.setBool(_biometricEnabledKey, false);
    await unlockSession();
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].isEmpty) return '***@***';
    final name = parts[0];
    if (name.length == 1) return '*@${parts[1]}';
    if (name.length == 2) return '${name[0]}*@${parts[1]}';
    return '${name[0]}***${name[name.length - 1]}@${parts[1]}';
  }

  String _maskPhone(String phone) {
    if (phone.length < 4) return '****';
    return '******${phone.substring(phone.length - 4)}';
  }

  Future<void> updateProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    AppLocaleService.instance.applyProfile(profile);
    await _syncHouseholdMember(profile.name);
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_pinHashKey);
    await prefs.remove(_passwordHashKey);
    await _secureDelete(_securePinHashKey);
    await _secureDelete(_securePasswordHashKey);
    await prefs.remove(_authMethodKey);
    await prefs.remove(_biometricEnabledKey);
    await prefs.setBool(_loggedInKey, false);
  }

  /// Debug/testing only — clears local auth so a new profile can be registered.
  Future<void> prepareForTestRegistration() async {
    if (!DevAuthConfig.canBypassRegistrationGuard) {
      throw const AuthException(
        'Test registration is not available in release builds',
      );
    }
    await clearProfile();
    await DeviceEnrollmentService.instance.clear();
  }

  Future<bool> _verifySecret(String secret) async {
    final method = await getAuthLockMethod();
    final hash = await _readSecretHash(method);
    if (hash == null) return false;
    return hash == _hashSecret(secret);
  }

  Future<String?> _readSecretHash(AuthLockMethod method) async {
    final secureKey = method == AuthLockMethod.password
        ? _securePasswordHashKey
        : _securePinHashKey;
    final legacyPrefKey = method == AuthLockMethod.password
        ? _passwordHashKey
        : _pinHashKey;

    final secureValue = await _secureRead(secureKey);
    if (secureValue != null && secureValue.isNotEmpty) {
      return secureValue;
    }

    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(legacyPrefKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _secureWrite(secureKey, legacy);
      await prefs.remove(legacyPrefKey);
      return legacy;
    }
    return null;
  }

  Future<void> _writeSecretHashes({
    String? pinHash,
    String? passwordHash,
  }) async {
    if (pinHash == null) {
      await _secureDelete(_securePinHashKey);
    } else {
      await _secureWrite(_securePinHashKey, pinHash);
    }

    if (passwordHash == null) {
      await _secureDelete(_securePasswordHashKey);
    } else {
      await _secureWrite(_securePasswordHashKey, passwordHash);
    }
  }

  Future<String?> _secureRead(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } on MissingPluginException {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
  }

  Future<void> _secureWrite(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } on MissingPluginException {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    }
  }

  Future<void> _secureDelete(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } on MissingPluginException {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }
  }

  String _hashSecret(String value) =>
      base64Url.encode(utf8.encode('household_expense_pin_$value'));

  Future<void> _syncHouseholdMember(String name) async {
    final db = DatabaseHelper.instance;
    final members = await db.getMembers();
    final self = members.where((m) => m.name == 'Self').firstOrNull;

    if (self != null) {
      await db.updateMember(
        self.copyWith(name: name, role: 'Primary'),
      );
      return;
    }

    await db.insertMember(
      HouseholdMember(name: name, role: 'Primary'),
    );
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class _NativeSheetLifecycleTracker with WidgetsBindingObserver {
  bool _leftResumed = false;
  Completer<void>? _resumeCompleter;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isBackgroundLifecycleState(state)) {
      _leftResumed = true;
      return;
    }

    if (state == AppLifecycleState.resumed && _leftResumed) {
      _resumeCompleter?.complete();
    }
  }

  Future<void> waitForForegroundCycleIfNeeded() async {
    // Let the platform deliver pause/resume events for launched intents.
    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;

    final current = WidgetsBinding.instance.lifecycleState;
    if (current != null && _isBackgroundLifecycleState(current)) {
      _leftResumed = true;
    }

    if (!_leftResumed) return;
    if (current == AppLifecycleState.resumed) return;

    _resumeCompleter = Completer<void>();
    try {
      await _resumeCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {},
      );
    } finally {
      _resumeCompleter = null;
    }
  }
}

bool _isBackgroundLifecycleState(AppLifecycleState state) {
  return state == AppLifecycleState.paused ||
      state == AppLifecycleState.inactive ||
      state == AppLifecycleState.hidden;
}

extension _HouseholdMemberCopy on HouseholdMember {
  HouseholdMember copyWith({String? name, String? role, String? color}) {
    return HouseholdMember(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      color: color ?? this.color,
    );
  }
}
