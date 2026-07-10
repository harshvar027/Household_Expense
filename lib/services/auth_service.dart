import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/dev_auth_config.dart';
import '../database/database_helper.dart';
import '../models/app_region.dart';
import '../models/app_user_record.dart';
import '../models/household_member.dart';
import '../models/registration_guard.dart';
import '../models/user_profile.dart';
import '../utils/auth_validators.dart';
import 'app_locale_service.dart';
import 'auth_credential_store.dart';
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
  static const _migratedToDbKey = 'auth_migrated_to_db_v1';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthCredentialStore _store = DatabaseAuthCredentialStore();
  bool _migrationChecked = false;

  /// Nested counter so nested file pickers / share sheets don't unlock early.
  int _backgroundLockSuppressCount = 0;

  bool get isBackgroundLockSuppressed => _backgroundLockSuppressCount > 0;

  /// Test-only: swap the credential store (in-memory) and reset migration flag.
  @visibleForTesting
  void debugUseStore(AuthCredentialStore store) {
    _store = store;
    _migrationChecked = false;
  }

  @visibleForTesting
  void debugResetMigrationFlag() {
    _migrationChecked = false;
  }

  /// Call around native UI that pauses the Flutter activity (file picker, etc.).
  void beginBackgroundLockSuppress() => _backgroundLockSuppressCount++;

  void endBackgroundLockSuppress() {
    if (_backgroundLockSuppressCount > 0) {
      _backgroundLockSuppressCount--;
    }
  }

  /// Keeps the session alive while native share sheets / file pickers pause the app.
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

  /// Ensures legacy prefs/secure credentials are copied into the database once.
  Future<void> ensureAuthReady() async {
    if (_migrationChecked) return;
    await _migrateLegacyCredentialsToDbIfNeeded();
    _migrationChecked = true;
  }

  /// True when the encrypted database already has a household account.
  Future<bool> hasAccount() async {
    await ensureAuthReady();
    return _store.hasUser();
  }

  Future<bool> hasProfile() async => hasAccount();

  /// True when a PIN/password hash exists (DB first, then secure storage).
  Future<bool> hasUnlockCredential() async {
    await ensureAuthReady();
    final user = await _store.readUser();
    if (user != null && user.secretHash.isNotEmpty) return true;
    final pin = await _readSecretHash(AuthLockMethod.pin);
    if (pin != null && pin.isNotEmpty) return true;
    final password = await _readSecretHash(AuthLockMethod.password);
    return password != null && password.isNotEmpty;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  Future<AuthLockMethod> getAuthLockMethod() async {
    await ensureAuthReady();
    final user = await _store.readUser();
    if (user != null) {
      return user.authMethod == 'password'
          ? AuthLockMethod.password
          : AuthLockMethod.pin;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_authMethodKey);
    return raw == 'password' ? AuthLockMethod.password : AuthLockMethod.pin;
  }

  Future<bool> isBiometricEnabled() async {
    await ensureAuthReady();
    final user = await _store.readUser();
    if (user != null) return user.biometricEnabled;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await ensureAuthReady();
    final user = await _store.readUser();
    if (user != null) {
      await _store.upsertUser(
        user.copyWith(
          biometricEnabled: enabled,
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<UserProfile?> getProfile() async {
    await ensureAuthReady();
    final user = await _store.readUser();
    if (user != null) {
      final profile = user.toProfile();
      AppLocaleService.instance.applyProfile(profile);
      await _mirrorProfilePrefs(profile);
      return profile;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    final profile = UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    AppLocaleService.instance.applyProfile(profile);
    return profile;
  }

  Future<AppUserRecord?> getAccountRecord() async {
    await ensureAuthReady();
    return _store.readUser();
  }

  Future<void> register({
    required UserProfile profile,
    required String pin,
  }) async {
    await ensureAuthReady();

    if (DevAuthConfig.canBypassRegistrationGuard && await hasAccount()) {
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

    final secretHash = hashSecret(pin);
    final record = AppUserRecord.fromProfile(
      profile: profile,
      secretHash: secretHash,
      authMethod: 'pin',
      biometricEnabled: false,
    );

    await _store.upsertUser(record);
    await _mirrorProfilePrefs(profile);
    await _writeSecretHashes(pinHash: secretHash, passwordHash: null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinHashKey);
    await prefs.remove(_passwordHashKey);
    await prefs.setString(_authMethodKey, 'pin');
    await prefs.setBool(_biometricEnabledKey, false);
    await prefs.setBool(_loggedInKey, true);
    await prefs.setBool(_migratedToDbKey, true);

    AppLocaleService.instance.applyProfile(profile);

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
    if (_store is DatabaseAuthCredentialStore) {
      await _syncHouseholdMember(profile.name);
      await DatabaseHelper.instance.setupInitialAccountFromRegistration(profile);
    }
  }

  /// Unlock with PIN/password only (legacy). Prefer [login] with identifier.
  Future<bool> unlockWithSecret(String secret) async {
    if (!await _verifySecret(secret)) return false;
    await unlockSession();
    return true;
  }

  /// Authorize against the database: email/username + PIN/password.
  Future<bool> login({
    required String identifier,
    required String secret,
  }) async {
    await ensureAuthReady();
    final user = await _store.readUser();
    if (user == null) return false;

    if (!identifierMatchesAccount(user, identifier)) return false;
    if (!secretsMatch(user.secretHash, secret)) return false;

    await _mirrorProfilePrefs(user.toProfile());
    AppLocaleService.instance.applyProfile(user.toProfile());
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

    final hash = hashSecret(newPin);
    await ensureAuthReady();
    final user = await _store.readUser();
    if (user != null) {
      await _store.upsertUser(
        user.copyWith(
          authMethod: 'pin',
          secretHash: hash,
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await _writeSecretHashes(pinHash: hash);
    await prefs.setString(_authMethodKey, 'pin');
  }

  Future<void> setPassword({
    required String currentSecret,
    required String newPassword,
  }) async {
    if (!await _verifySecret(currentSecret)) {
      throw AuthException('Current PIN or password is incorrect');
    }

    final hash = hashSecret(newPassword);
    await ensureAuthReady();
    final user = await _store.readUser();
    if (user != null) {
      await _store.upsertUser(
        user.copyWith(
          authMethod: 'password',
          secretHash: hash,
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await _writeSecretHashes(passwordHash: hash);
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

  /// Email, phone, or full name may unlock the local account.
  static bool identifierMatchesAccount(AppUserRecord user, String identifier) {
    final raw = identifier.trim();
    if (raw.isEmpty) return false;

    final lower = raw.toLowerCase();
    if (user.email.trim().toLowerCase() == lower) return true;
    if (user.name.trim().toLowerCase() == lower) return true;

    final region = AppRegion.fromStorage(user.region);
    final normalizedId = AuthValidators.normalizePhone(raw, region: region);
    if (normalizedId.isNotEmpty && user.phone == normalizedId) return true;

    return false;
  }

  static bool secretsMatch(String storedHash, String secret) =>
      storedHash == hashSecret(secret);

  static String hashSecret(String value) =>
      base64Url.encode(utf8.encode('household_expense_pin_$value'));

  Future<RegistrationCheck> checkRegistrationAllowed({
    String? email,
    String? phone,
    AppRegion? region,
  }) async {
    if (DevAuthConfig.canBypassRegistrationGuard) {
      return const RegistrationCheck(reason: RegistrationBlockReason.allowed);
    }

    await ensureAuthReady();
    final user = await _store.readUser();
    if (user != null) {
      final profile = user.toProfile();
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

  Future<void> resetLockAfterIdentityCheck({
    required String email,
    required String phone,
    required String newSecret,
    AuthLockMethod method = AuthLockMethod.pin,
  }) async {
    await ensureAuthReady();
    final user = await _store.readUser();
    if (user == null) {
      throw const AuthException('No account found on this device');
    }

    final profile = user.toProfile();
    if (!identityMatches(profile, email, phone)) {
      throw const AuthException(
        'Email and mobile number do not match the account on this device',
      );
    }

    final hash = hashSecret(newSecret);
    final prefs = await SharedPreferences.getInstance();
    if (method == AuthLockMethod.password) {
      await _store.upsertUser(
        user.copyWith(
          authMethod: 'password',
          secretHash: hash,
          biometricEnabled: false,
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
      await _writeSecretHashes(pinHash: null, passwordHash: hash);
      await prefs.remove(_pinHashKey);
      await prefs.setString(_authMethodKey, 'password');
    } else {
      await _store.upsertUser(
        user.copyWith(
          authMethod: 'pin',
          secretHash: hash,
          biometricEnabled: false,
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
      await _writeSecretHashes(pinHash: hash, passwordHash: null);
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
    await ensureAuthReady();
    final user = await _store.readUser();
    if (user != null) {
      await _store.upsertUser(
        user.copyWith(
          name: profile.name,
          email: profile.email,
          phone: profile.phone,
          householdName: profile.householdName,
          region: profile.region,
          currency: profile.currency,
          primaryBankId: profile.primaryBankId,
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
    }
    await _mirrorProfilePrefs(profile);
    AppLocaleService.instance.applyProfile(profile);
    if (_store is DatabaseAuthCredentialStore) {
      await _syncHouseholdMember(profile.name);
    }
  }

  Future<void> clearProfile() async {
    await ensureAuthReady();
    await _store.deleteUser();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_pinHashKey);
    await prefs.remove(_passwordHashKey);
    await _secureDelete(_securePinHashKey);
    await _secureDelete(_securePasswordHashKey);
    await prefs.remove(_authMethodKey);
    await prefs.remove(_biometricEnabledKey);
    await prefs.remove(_migratedToDbKey);
    await prefs.setBool(_loggedInKey, false);
    _migrationChecked = false;
  }

  Future<void> prepareForTestRegistration() async {
    if (!DevAuthConfig.canBypassRegistrationGuard) {
      throw const AuthException(
        'Test registration is not available in release builds',
      );
    }
    await clearProfile();
    await DeviceEnrollmentService.instance.clear();
  }

  Future<void> _migrateLegacyCredentialsToDbIfNeeded() async {
    if (await _store.hasUser()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_migratedToDbKey, true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return;

    final profile = UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final method = prefs.getString(_authMethodKey) == 'password'
        ? AuthLockMethod.password
        : AuthLockMethod.pin;
    final hash = await _readSecretHash(method);
    if (hash == null || hash.isEmpty) return;

    final record = AppUserRecord.fromProfile(
      profile: profile,
      secretHash: hash,
      authMethod: method == AuthLockMethod.password ? 'password' : 'pin',
      biometricEnabled: prefs.getBool(_biometricEnabledKey) ?? false,
    );
    await _store.upsertUser(record);
    await prefs.setBool(_migratedToDbKey, true);
  }

  Future<void> _mirrorProfilePrefs(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<bool> _verifySecret(String secret) async {
    await ensureAuthReady();
    final user = await _store.readUser();
    if (user != null && user.secretHash.isNotEmpty) {
      return secretsMatch(user.secretHash, secret);
    }
    final method = await getAuthLockMethod();
    final hash = await _readSecretHash(method);
    if (hash == null) return false;
    return secretsMatch(hash, secret);
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
