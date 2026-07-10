import 'package:shared_preferences/shared_preferences.dart';

import '../config/subscription_config.dart';
import '../models/app_region.dart';
import '../models/subscription_tier.dart';
import 'auth_service.dart';
import 'device_enrollment_service.dart';

/// Snapshot of the user's current plan and access rights.
class EntitlementStatus {
  final SubscriptionTier tier;
  final DateTime registrationDate;
  final DateTime? subscriptionExpiresAt;
  final DateTime evaluatedAt;

  const EntitlementStatus({
    required this.tier,
    required this.registrationDate,
    required this.subscriptionExpiresAt,
    required this.evaluatedAt,
  });

  DateTime get freeTrialEndsAt => _addMonths(
        registrationDate,
        SubscriptionConfig.freeTrialMonths,
      );

  bool get hasActivePremium =>
      tier != SubscriptionTier.free &&
      subscriptionExpiresAt != null &&
      evaluatedAt.isBefore(subscriptionExpiresAt!);

  bool get isFreeTrialActive =>
      tier == SubscriptionTier.free && evaluatedAt.isBefore(freeTrialEndsAt);

  bool get canUseApp => hasActivePremium || isFreeTrialActive;

  int get freeTrialDaysRemaining {
    if (!isFreeTrialActive) return 0;
    return freeTrialEndsAt.difference(evaluatedAt).inDays.clamp(0, 9999);
  }

  int get premiumDaysRemaining {
    if (!hasActivePremium || subscriptionExpiresAt == null) return 0;
    return subscriptionExpiresAt!.difference(evaluatedAt).inDays.clamp(0, 9999);
  }

  bool canAccess(AppFeature feature) {
    if (!canUseApp) return false;
    if (hasActivePremium || isFreeTrialActive) return true;

    return switch (feature) {
      AppFeature.basicUsage => true,
      AppFeature.backup ||
      AppFeature.restore ||
      AppFeature.exportCsv ||
      AppFeature.exportPdf ||
      AppFeature.importStatement =>
        false,
    };
  }

  /// Earliest month key (YYYY-MM) a lapsed free user may view.
  String? earliestAllowedMonthKey(DateTime now) {
    if (hasActivePremium || isFreeTrialActive) return null;

    final trialStart = DateTime(registrationDate.year, registrationDate.month);
    final trialWindowStart = _addMonths(
      DateTime(now.year, now.month),
      -(SubscriptionConfig.freeTrialMonths - 1),
    );
    final earliest =
        trialStart.isAfter(trialWindowStart) ? trialStart : trialWindowStart;
    return '${earliest.year}-${earliest.month.toString().padLeft(2, '0')}';
  }

  String planSummary() {
    if (hasActivePremium) {
      final until = subscriptionExpiresAt!;
      final date =
          '${until.day}/${until.month}/${until.year}';
      return switch (tier) {
        SubscriptionTier.monthly => 'Pro · valid until $date',
        SubscriptionTier.yearly => 'Yearly Pro · valid until $date',
        SubscriptionTier.free => '',
      };
    }
    if (isFreeTrialActive) {
      return 'Free trial · all features · $freeTrialDaysRemaining days left';
    }
    return 'Free trial ended · purchase yearly plan to continue';
  }
}

class EntitlementService {
  EntitlementService._();

  static final EntitlementService instance = EntitlementService._();

  static const _tierKey = 'subscription_tier_v1';
  static const _expiresKey = 'subscription_expires_at_v1';
  static const _registrationKey = 'registration_date_v1';

  Future<EntitlementStatus> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final regRaw = prefs.getString(_registrationKey);
    final enrollment = await DeviceEnrollmentService.instance.read();
    final DateTime registrationDate;
    if (regRaw != null) {
      registrationDate = DateTime.parse(regRaw);
    } else if (enrollment != null) {
      registrationDate = enrollment.registrationDate;
      await prefs.setString(
        _registrationKey,
        enrollment.registrationDate.toIso8601String(),
      );
    } else {
      // Trial starts only after account creation — until then treat trial as inactive.
      registrationDate = now.subtract(
        Duration(days: SubscriptionConfig.freeTrialMonths * 31),
      );
    }

    final tierName = prefs.getString(_tierKey) ?? SubscriptionTier.free.storageKey;
    final tier = SubscriptionTier.values.firstWhere(
      (t) => t.storageKey == tierName,
      orElse: () => SubscriptionTier.free,
    );

    final expiresRaw = prefs.getString(_expiresKey);
    final expiresAt = expiresRaw != null ? DateTime.parse(expiresRaw) : null;

    return EntitlementStatus(
      tier: tier,
      registrationDate: registrationDate,
      subscriptionExpiresAt: expiresAt,
      evaluatedAt: now,
    );
  }

  Future<void> ensureRegistrationDate() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_registrationKey)) return;

    final enrollment = await DeviceEnrollmentService.instance.read();
    if (enrollment == null) return;

    await prefs.setString(
      _registrationKey,
      enrollment.registrationDate.toIso8601String(),
    );
  }

  /// Records device enrollment for accounts created before enrollment existed.
  Future<void> migrateDeviceEnrollmentIfNeeded() async {
    if (await DeviceEnrollmentService.instance.isEnrolled()) return;

    final profile = await AuthService.instance.getProfile();
    if (profile == null) return;

    final prefs = await SharedPreferences.getInstance();
    final regRaw = prefs.getString(_registrationKey);
    final registrationDate = regRaw != null
        ? DateTime.parse(regRaw)
        : DateTime.now();

    await DeviceEnrollmentService.instance.record(
      email: profile.email,
      phone: profile.phone,
      region: AppRegion.fromStorage(profile.region),
      registrationDate: registrationDate,
    );
  }

  Future<void> setRegistrationDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_registrationKey, date.toIso8601String());
  }

  Future<void> activateYearly({DateTime? from}) async {
    final prefs = await SharedPreferences.getInstance();
    final start = from ?? DateTime.now();
    final expires = start.add(SubscriptionConfig.yearlyDuration);
    await prefs.setString(_tierKey, SubscriptionTier.yearly.storageKey);
    await prefs.setString(_expiresKey, expires.toIso8601String());
  }

  Future<void> resetToFree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tierKey, SubscriptionTier.free.storageKey);
    await prefs.remove(_expiresKey);
  }

  Future<bool> canAccess(AppFeature feature) async {
    final status = await getStatus();
    return status.canAccess(feature);
  }

  Future<void> requireFeature(AppFeature feature) async {
    if (!await canAccess(feature)) {
      throw EntitlementException(feature);
    }
  }

  /// For backup file metadata (optional future use).
  Future<Map<String, dynamic>> exportEntitlementMeta() async {
    final status = await getStatus();
    return {
      'tier': status.tier.storageKey,
      'registrationDate': status.registrationDate.toIso8601String(),
      'subscriptionExpiresAt': status.subscriptionExpiresAt?.toIso8601String(),
    };
  }

  Future<void> importEntitlementMeta(Map<String, dynamic>? meta) async {
    if (meta == null) return;
    final prefs = await SharedPreferences.getInstance();
    final tier = meta['tier'] as String?;
    if (tier != null) await prefs.setString(_tierKey, tier);
    final expires = meta['subscriptionExpiresAt'] as String?;
    if (expires != null) {
      await prefs.setString(_expiresKey, expires);
    }
  }
}

DateTime _addMonths(DateTime date, int months) {
  var month = date.month + months;
  var year = date.year;
  while (month > 12) {
    month -= 12;
    year++;
  }
  while (month <= 0) {
    month += 12;
    year--;
  }
  final day = date.day;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > lastDay ? lastDay : day);
}

class EntitlementException implements Exception {
  final AppFeature feature;

  EntitlementException(this.feature);

  @override
  String toString() => 'Entitlement required for $feature';
}
