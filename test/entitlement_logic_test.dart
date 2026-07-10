import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:household_expense/config/subscription_config.dart';
import 'package:household_expense/models/subscription_tier.dart';
import 'package:household_expense/services/entitlement_service.dart';

/// Builds a status snapshot for tests.
EntitlementStatus _status({
  required SubscriptionTier tier,
  required DateTime registrationDate,
  DateTime? expiresAt,
  DateTime? now,
}) {
  return EntitlementStatus(
    tier: tier,
    registrationDate: registrationDate,
    subscriptionExpiresAt: expiresAt,
    evaluatedAt: now ?? DateTime.now(),
  );
}

const _allFeatures = AppFeature.values;

void main() {
  group('Free trial (all features, 3 months)', () {
    test('brand new user has full access during trial', () {
      final now = DateTime(2026, 1, 1);
      final status = _status(
        tier: SubscriptionTier.free,
        registrationDate: now,
        now: now,
      );

      expect(status.canUseApp, isTrue);
      expect(status.isFreeTrialActive, isTrue);
      expect(status.hasActivePremium, isFalse);
      for (final f in _allFeatures) {
        expect(status.canAccess(f), isTrue, reason: 'trial should unlock $f');
      }
    });

    test('trial active on the last day before expiry', () {
      final reg = DateTime(2026, 1, 1);
      final trialEnd = DateTime(reg.year, reg.month + SubscriptionConfig.freeTrialMonths, reg.day);
      final now = trialEnd.subtract(const Duration(days: 1));
      final status = _status(
        tier: SubscriptionTier.free,
        registrationDate: reg,
        now: now,
      );
      expect(status.canUseApp, isTrue);
      expect(status.canAccess(AppFeature.backup), isTrue);
    });

    test('trial expired locks every feature and blocks the app', () {
      final reg = DateTime(2025, 1, 1);
      final now = DateTime(2025, 4, 2); // > 3 months later
      final status = _status(
        tier: SubscriptionTier.free,
        registrationDate: reg,
        now: now,
      );

      expect(status.isFreeTrialActive, isFalse);
      expect(status.canUseApp, isFalse);
      for (final f in _allFeatures) {
        expect(status.canAccess(f), isFalse, reason: '$f must be locked');
      }
    });

    test('trial days remaining never negative', () {
      final reg = DateTime(2020, 1, 1);
      final now = DateTime(2026, 7, 8);
      final status = _status(
        tier: SubscriptionTier.free,
        registrationDate: reg,
        now: now,
      );
      expect(status.freeTrialDaysRemaining, greaterThanOrEqualTo(0));
    });
  });

  group('Yearly plan (₹1800 one-time, 1 year, ad-free)', () {
    test('price and product id match the new plan', () {
      expect(SubscriptionConfig.yearlyPriceInr, 1800);
      expect(SubscriptionConfig.yearlyProductId, 'household_expense_yearly_1800');
      expect(SubscriptionConfig.productIds, {SubscriptionConfig.yearlyProductId});
      expect(SubscriptionConfig.yearlyDuration, const Duration(days: 365));
    });

    test('active yearly unlocks everything even after trial window', () {
      final reg = DateTime(2024, 1, 1); // trial long gone
      final now = DateTime(2026, 3, 1);
      final status = _status(
        tier: SubscriptionTier.yearly,
        registrationDate: reg,
        expiresAt: now.add(const Duration(days: 200)),
        now: now,
      );

      expect(status.hasActivePremium, isTrue);
      expect(status.canUseApp, isTrue);
      for (final f in _allFeatures) {
        expect(status.canAccess(f), isTrue);
      }
      expect(status.premiumDaysRemaining, greaterThan(0));
    });

    test('expired yearly falls back to locked (trial also over)', () {
      final reg = DateTime(2024, 1, 1);
      final now = DateTime(2026, 3, 1);
      final status = _status(
        tier: SubscriptionTier.yearly,
        registrationDate: reg,
        expiresAt: now.subtract(const Duration(days: 1)),
        now: now,
      );

      expect(status.hasActivePremium, isFalse);
      expect(status.canUseApp, isFalse);
      expect(status.premiumDaysRemaining, 0);
    });
  });

  group('Randomized fuzz — must never throw or contradict itself', () {
    test('1000 random snapshots keep invariants', () {
      final rng = Random(20260708);

      for (var i = 0; i < 1000; i++) {
        final regYear = 2020 + rng.nextInt(7);
        final reg = DateTime(
          regYear,
          1 + rng.nextInt(12),
          1 + rng.nextInt(28),
        );
        final now = reg.add(Duration(days: rng.nextInt(1500)));
        final tier = SubscriptionTier.values[rng.nextInt(SubscriptionTier.values.length)];
        DateTime? expires;
        if (tier != SubscriptionTier.free) {
          // Randomly in the past or future relative to now.
          final offset = rng.nextInt(800) - 400;
          expires = now.add(Duration(days: offset));
        }

        final status = _status(
          tier: tier,
          registrationDate: reg,
          expiresAt: expires,
          now: now,
        );

        // These must never throw.
        final canUse = status.canUseApp;
        final summary = status.planSummary();
        final earliest = status.earliestAllowedMonthKey(now);

        // Invariant 1: canUseApp iff (active premium OR active trial).
        expect(
          canUse,
          status.hasActivePremium || status.isFreeTrialActive,
        );

        // Invariant 2: if cannot use app, no feature is accessible.
        if (!canUse) {
          for (final f in _allFeatures) {
            expect(status.canAccess(f), isFalse);
          }
        } else {
          // Invariant 3: usable app unlocks all features under new plan.
          for (final f in _allFeatures) {
            expect(status.canAccess(f), isTrue);
          }
        }

        // Invariant 4: summary is always a string (may be empty).
        expect(summary, isA<String>());

        // Invariant 5: earliest month null when usable, formatted otherwise.
        if (canUse) {
          expect(earliest, isNull);
        } else {
          expect(earliest, matches(RegExp(r'^\d{4}-\d{2}$')));
        }

        // Invariant 6: day counters non-negative.
        expect(status.freeTrialDaysRemaining, greaterThanOrEqualTo(0));
        expect(status.premiumDaysRemaining, greaterThanOrEqualTo(0));
      }
    });
  });
}
