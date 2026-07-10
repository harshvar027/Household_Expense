import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:household_expense/config/dev_auth_config.dart';
import 'package:household_expense/models/app_region.dart';
import 'package:household_expense/models/app_user_record.dart';
import 'package:household_expense/models/registration_guard.dart';
import 'package:household_expense/models/user_profile.dart';
import 'package:household_expense/services/auth_credential_store.dart';
import 'package:household_expense/services/auth_service.dart';
import 'package:household_expense/services/device_enrollment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _testProfile = UserProfile(
  name: 'Test User',
  email: 'test@example.com',
  phone: '9876543210',
  region: 'india',
);

Future<void> _seedDbAccount({
  UserProfile profile = _testProfile,
  String pin = '1234',
  String authMethod = 'pin',
}) async {
  final store = InMemoryAuthCredentialStore();
  AuthService.instance.debugUseStore(store);
  await store.upsertUser(
    AppUserRecord.fromProfile(
      profile: profile,
      secretHash: AuthService.hashSecret(pin),
      authMethod: authMethod,
    ),
  );
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_profile_v1', jsonEncode(profile.toJson()));
  await prefs.setString('user_auth_method_v1', authMethod);
  await prefs.setBool('user_logged_in_v1', false);
}

Future<void> _seedLegacyPrefsOnly({
  UserProfile profile = _testProfile,
  String pin = '1234',
}) async {
  AuthService.instance.debugUseStore(InMemoryAuthCredentialStore());
  AuthService.instance.debugResetMigrationFlag();
  SharedPreferences.setMockInitialValues({
    'user_profile_v1': jsonEncode(profile.toJson()),
    'user_pin_hash_v1': AuthService.hashSecret(pin),
    'user_auth_method_v1': 'pin',
    'user_logged_in_v1': false,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DevAuthConfig.setDisabledForTests(true);
    AuthService.instance.debugUseStore(InMemoryAuthCredentialStore());
    AuthService.instance.debugResetMigrationFlag();
    await DeviceEnrollmentService.instance.clear();
  });

  tearDown(() async {
    await DeviceEnrollmentService.instance.clear();
    DevAuthConfig.setDisabledForTests(false);
    AuthService.instance.debugUseStore(InMemoryAuthCredentialStore());
    AuthService.instance.debugResetMigrationFlag();
  });

  group('AuthService.hashSecret / identifier matching', () {
    test('hashSecret is stable for the same PIN', () {
      expect(AuthService.hashSecret('1234'), AuthService.hashSecret('1234'));
      expect(AuthService.hashSecret('1234'), isNot(AuthService.hashSecret('5678')));
    });

    test('identifierMatchesAccount accepts email, name, and phone', () {
      final user = AppUserRecord.fromProfile(
        profile: _testProfile,
        secretHash: AuthService.hashSecret('1234'),
      );
      expect(AuthService.identifierMatchesAccount(user, 'test@example.com'), isTrue);
      expect(AuthService.identifierMatchesAccount(user, 'TEST@EXAMPLE.COM'), isTrue);
      expect(AuthService.identifierMatchesAccount(user, 'Test User'), isTrue);
      expect(AuthService.identifierMatchesAccount(user, '9876543210'), isTrue);
      expect(AuthService.identifierMatchesAccount(user, 'wrong@example.com'), isFalse);
      expect(AuthService.identifierMatchesAccount(user, ''), isFalse);
    });

    test('secretsMatch verifies PIN against stored hash', () {
      final hash = AuthService.hashSecret('1234');
      expect(AuthService.secretsMatch(hash, '1234'), isTrue);
      expect(AuthService.secretsMatch(hash, '9999'), isFalse);
    });
  });

  group('AuthService database account lifecycle', () {
    test('hasAccount is false when database has no user', () async {
      expect(await AuthService.instance.hasAccount(), isFalse);
    });

    test('register stores credentials in the credential store', () async {
      await AuthService.instance.register(
        profile: _testProfile,
        pin: '1234',
      );

      expect(await AuthService.instance.hasAccount(), isTrue);
      expect(await AuthService.instance.isLoggedIn(), isTrue);

      final profile = await AuthService.instance.getProfile();
      expect(profile?.email, 'test@example.com');
      expect(profile?.name, 'Test User');
    });

    test('login succeeds with email and correct PIN', () async {
      await _seedDbAccount();
      await AuthService.instance.logout();

      final ok = await AuthService.instance.login(
        identifier: 'test@example.com',
        secret: '1234',
      );
      expect(ok, isTrue);
      expect(await AuthService.instance.isLoggedIn(), isTrue);
    });

    test('login succeeds with username and correct PIN', () async {
      await _seedDbAccount();
      await AuthService.instance.logout();

      final ok = await AuthService.instance.login(
        identifier: 'Test User',
        secret: '1234',
      );
      expect(ok, isTrue);
    });

    test('login fails with wrong PIN', () async {
      await _seedDbAccount();
      await AuthService.instance.logout();

      final ok = await AuthService.instance.login(
        identifier: 'test@example.com',
        secret: '9999',
      );
      expect(ok, isFalse);
      expect(await AuthService.instance.isLoggedIn(), isFalse);
    });

    test('login fails with wrong email even if PIN is correct', () async {
      await _seedDbAccount();
      await AuthService.instance.logout();

      final ok = await AuthService.instance.login(
        identifier: 'other@example.com',
        secret: '1234',
      );
      expect(ok, isFalse);
      expect(await AuthService.instance.isLoggedIn(), isFalse);
    });

    test('login fails when no account exists', () async {
      final ok = await AuthService.instance.login(
        identifier: 'test@example.com',
        secret: '1234',
      );
      expect(ok, isFalse);
    });

    test('logout keeps account but clears session', () async {
      await _seedDbAccount();
      await AuthService.instance.unlockSession();
      expect(await AuthService.instance.isLoggedIn(), isTrue);

      await AuthService.instance.logout();
      expect(await AuthService.instance.isLoggedIn(), isFalse);
      expect(await AuthService.instance.hasAccount(), isTrue);
    });

    test('clearProfile removes account so create-account is allowed again', () async {
      await _seedDbAccount();
      expect(await AuthService.instance.hasAccount(), isTrue);

      await AuthService.instance.clearProfile();
      expect(await AuthService.instance.hasAccount(), isFalse);

      final check = await AuthService.instance.checkRegistrationAllowed(
        email: 'new@example.com',
        phone: '9123456789',
      );
      expect(check.allowed, isTrue);
    });
  });

  group('AuthService legacy migration', () {
    test('migrates prefs profile + PIN hash into the credential store', () async {
      await _seedLegacyPrefsOnly();

      expect(await AuthService.instance.hasAccount(), isTrue);
      final profile = await AuthService.instance.getProfile();
      expect(profile?.email, 'test@example.com');

      final ok = await AuthService.instance.login(
        identifier: 'test@example.com',
        secret: '1234',
      );
      expect(ok, isTrue);
    });
  });

  group('AuthService registration guard', () {
    test('allows registration when no profile exists', () async {
      final check = await AuthService.instance.checkRegistrationAllowed(
        email: 'new@example.com',
        phone: '9876543210',
      );
      expect(check.allowed, isTrue);
    });

    test('blocks second account on same device', () async {
      await _seedDbAccount();

      final check = await AuthService.instance.checkRegistrationAllowed(
        email: 'other@example.com',
        phone: '9123456789',
      );
      expect(check.allowed, isFalse);
      expect(check.reason, RegistrationBlockReason.deviceAlreadyRegistered);
    });

    test('blocks re-register with same email and phone', () async {
      await _seedDbAccount();

      final check = await AuthService.instance.checkRegistrationAllowed(
        email: 'test@example.com',
        phone: '9876543210',
        region: AppRegion.india,
      );
      expect(check.allowed, isFalse);
      expect(check.reason, RegistrationBlockReason.identityMatchesExisting);
    });

    test('blocks a different user when device enrollment exists without profile',
        () async {
      await DeviceEnrollmentService.instance.record(
        email: 'owner@example.com',
        phone: '9876543210',
        region: AppRegion.india,
        registrationDate: DateTime(2025, 1, 1),
      );

      final check = await AuthService.instance.checkRegistrationAllowed(
        email: 'other@example.com',
        phone: '9123456789',
        region: AppRegion.india,
      );
      expect(check.allowed, isFalse);
      expect(check.reason, RegistrationBlockReason.deviceAlreadyRegistered);
    });

    test('allows original user to re-register after profile loss', () async {
      await DeviceEnrollmentService.instance.record(
        email: 'owner@example.com',
        phone: '9876543210',
        region: AppRegion.india,
        registrationDate: DateTime(2025, 1, 1),
      );

      final check = await AuthService.instance.checkRegistrationAllowed(
        email: 'owner@example.com',
        phone: '9876543210',
        region: AppRegion.india,
      );
      expect(check.allowed, isTrue);
    });

    test('blocks enrollment probe without identity when no profile', () async {
      await DeviceEnrollmentService.instance.record(
        email: 'owner@example.com',
        phone: '9876543210',
        region: AppRegion.india,
        registrationDate: DateTime(2025, 1, 1),
      );

      final check = await AuthService.instance.checkRegistrationAllowed();
      expect(check.allowed, isFalse);
      expect(check.reason, RegistrationBlockReason.deviceAlreadyRegistered);
    });
  });

  group('AuthService identity recovery', () {
    test('resets PIN when email and phone match', () async {
      await _seedDbAccount();
      await AuthService.instance.logout();

      await AuthService.instance.resetLockAfterIdentityCheck(
        email: 'test@example.com',
        phone: '9876543210',
        newSecret: '5678',
      );

      expect(
        await AuthService.instance.login(
          identifier: 'test@example.com',
          secret: '5678',
        ),
        isTrue,
      );
      expect(await AuthService.instance.isLoggedIn(), isTrue);
    });

    test('rejects reset when identity does not match', () async {
      await _seedDbAccount();

      expect(
        () => AuthService.instance.resetLockAfterIdentityCheck(
          email: 'wrong@example.com',
          phone: '9876543210',
          newSecret: '5678',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService change PIN', () {
    test('updates database hash and requires new PIN to login', () async {
      await _seedDbAccount(pin: '1234');
      await AuthService.instance.changePin(
        currentSecret: '1234',
        newPin: '4321',
      );
      await AuthService.instance.logout();

      expect(
        await AuthService.instance.login(
          identifier: 'test@example.com',
          secret: '1234',
        ),
        isFalse,
      );
      expect(
        await AuthService.instance.login(
          identifier: 'test@example.com',
          secret: '4321',
        ),
        isTrue,
      );
    });
  });
}
