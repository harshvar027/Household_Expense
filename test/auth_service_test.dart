import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:household_expense/config/dev_auth_config.dart';
import 'package:household_expense/config/subscription_config.dart';
import 'package:household_expense/services/device_enrollment_service.dart';
import 'package:household_expense/models/app_region.dart';
import 'package:household_expense/models/registration_guard.dart';
import 'package:household_expense/models/user_profile.dart';
import 'package:household_expense/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _seedProfile(UserProfile profile, {String pin = '1234'}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    'user_profile_v1',
    jsonEncode(profile.toJson()),
  );
  await prefs.setString(
    'user_pin_hash_v1',
    base64Url.encode(utf8.encode('household_expense_pin_$pin')),
  );
  await prefs.setString('user_auth_method_v1', 'pin');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DevAuthConfig.setDisabledForTests(true);
  });

  tearDown(() async {
    await DeviceEnrollmentService.instance.clear();
    DevAuthConfig.setDisabledForTests(false);
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
      await _seedProfile(
        const UserProfile(
          name: 'Test User',
          email: 'test@example.com',
          phone: '9876543210',
          region: 'india',
        ),
      );

      final check = await AuthService.instance.checkRegistrationAllowed(
        email: 'other@example.com',
        phone: '9123456789',
      );
      expect(check.allowed, isFalse);
      expect(check.reason, RegistrationBlockReason.deviceAlreadyRegistered);
    });

    test('blocks re-register with same email and phone', () async {
      await _seedProfile(
        const UserProfile(
          name: 'Test User',
          email: 'test@example.com',
          phone: '9876543210',
          region: 'india',
        ),
      );

      final check = await AuthService.instance.checkRegistrationAllowed(
        email: 'test@example.com',
        phone: '9876543210',
        region: AppRegion.india,
      );
      expect(check.allowed, isFalse);
      expect(check.reason, RegistrationBlockReason.identityMatchesExisting);
    });

    test('blocks a different user when device enrollment exists without profile', () async {
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
  });

  group('AuthService identity recovery', () {
    test('resets PIN when email and phone match', () async {
      await _seedProfile(
        const UserProfile(
          name: 'Test User',
          email: 'test@example.com',
          phone: '9876543210',
          region: 'india',
        ),
      );
      await AuthService.instance.logout();

      await AuthService.instance.resetLockAfterIdentityCheck(
        email: 'test@example.com',
        phone: '9876543210',
        newSecret: '5678',
      );

      expect(await AuthService.instance.unlockWithSecret('5678'), isTrue);
      expect(await AuthService.instance.isLoggedIn(), isTrue);
    });

    test('rejects reset when identity does not match', () async {
      await _seedProfile(
        const UserProfile(
          name: 'Test User',
          email: 'test@example.com',
          phone: '9876543210',
          region: 'india',
        ),
      );

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
}
