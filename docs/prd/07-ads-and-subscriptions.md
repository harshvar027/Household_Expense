# PRD-07 — Ads & Subscriptions

| Field | Value |
|-------|-------|
| **Product** | Household Expense |
| **Document ID** | PRD-07 |
| **Feature** | Free trial, AdMob banners, yearly Pro IAP, entitlements |
| **Status** | Implemented (store IDs must be productionized before release) |
| **Owner** | Product / Growth / Engineering |
| **Last updated** | 2026-07-10 |
| **Related code** | `lib/config/subscription_config.dart`, `ad_config.dart`, `lib/services/subscription_service.dart`, `entitlement_service.dart`, `ad_service.dart`, `lib/screens/subscription_screen.dart`, `lib/widgets/ads/*`, `upgrade_prompt.dart` |

---

## 1. Purpose

Define monetization: how the free trial works, when ads show, how yearly Pro is purchased/restored, and how feature gates (`AppFeature`) interact with trial vs premium. This PRD is the commercial contract for Play Store and App Store releases.

---

## 2. Problem statement

The app is free to try but costly to maintain (and ads fund trial). Users need a fair trial with full features, then a simple upgrade. Requirements:

- 3-month trial from registration with **all features** and **ads**.
- After trial, block usage until purchase.
- Yearly Pro: one-time style product id `household_expense_yearly_1800` at ₹1800 for 365 days, **ad-free**.
- Restore purchases for reinstalls.
- Test AdMob IDs must not ship to production.

---

## 3. Goals

| ID | Goal |
|----|------|
| G1 | Trial length = `SubscriptionConfig.freeTrialMonths` (3). |
| G2 | During trial: `canUseApp` true; ads visible; premium features unlocked. |
| G3 | After trial without Pro: blocking paywall. |
| G4 | Pro purchase grants ad-free + features for `yearlyDuration` (365 days). |
| G5 | Restore purchases works on Android and iOS. |
| G6 | Banner ads on Home/Expenses/Analytics ribbon; inline on Menu when not Pro. |
| G7 | Clear Subscription screen explaining plan. |

---

## 4. Non-goals

| ID | Non-goal |
|----|----------|
| NG1 | Monthly auto-renew SKU as primary offer (legacy enum may exist unused). |
| NG2 | Family Sharing complexity beyond store defaults. |
| NG3 | Server-side receipt validation backend (v1 relies on store + local entitlement). |
| NG4 | Rewarded video ads. |

---

## 5. Personas

- **Trial user** — explores import/export with ads.
- **Converter** — buys yearly when paywall hits.
- **Reinstaller** — restores Pro after phone change.

---

## 6. User stories

1. As a new user, I get 3 months of full features with ads.
2. As a trial user, I can open Subscription and see time remaining.
3. As an expired user, I must purchase or restore to continue.
4. As a Pro user, I see no banner ads.
5. As a Pro user, I can import/export/backup freely until expiry.
6. As a user, I can restore a previous purchase.

---

## 7. Functional requirements

### 7.1 Entitlement engine

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-S01 | Track `registration_date_v1`, `subscription_tier_v1`, `subscription_expires_at_v1`. | P0 |
| FR-S02 | `isFreeTrialActive` if within 3 months of registration. | P0 |
| FR-S03 | `hasActivePremium` if tier Pro and now < expiresAt. | P0 |
| FR-S04 | `canUseApp` = trial OR premium. | P0 |
| FR-S05 | `canAccess(feature)` true for all features while trial or premium. | P0 |
| FR-S06 | When `!canUseApp`, show blocking purchase UI. | P0 |

### 7.2 Product catalog

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-S10 | Product id `household_expense_yearly_1800`. | P0 |
| FR-S11 | Display price ₹1800 INR in UI copy (store may localize). | P0 |
| FR-S12 | On success, set tier + expiresAt = now + 365 days. | P0 |

### 7.3 Purchase UX

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-S20 | Subscription screen explains trial vs Pro. | P0 |
| FR-S21 | Buy button launches `in_app_purchase` flow. | P0 |
| FR-S22 | Handle pending/error/cancel gracefully. | P0 |
| FR-S23 | Restore purchases button. | P0 |
| FR-S24 | Menu shows plan banner / status. | P1 |

### 7.4 Ads

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-S30 | Init Mobile Ads only on Android/iOS. | P0 |
| FR-S31 | Load delay 2s; refresh every 5 min; height 50. | P1 |
| FR-S32 | Bottom ribbon under nav on Home/Expenses/Analytics when not Pro. | P0 |
| FR-S33 | Inline ribbon on Menu when not Pro. | P1 |
| FR-S34 | No ads when `hasActivePremium`. | P0 |
| FR-S35 | Use platform-specific unit IDs from `AdConfig`. | P0 |
| FR-S36 | Android App ID via `admob.properties`; iOS `GADApplicationIdentifier` in Info.plist. | P0 |

### 7.5 Upgrade prompts

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-S40 | Feature taps when not entitled show `UpgradePrompt`. | P0 |
| FR-S41 | Deep-link feel to Subscription screen. | P1 |

---

## 8. State matrix

| State | canUseApp | Features | Ads |
|-------|-----------|----------|-----|
| Trial active | Yes | All | Yes |
| Trial expired, no Pro | No | Blocked | N/A |
| Pro active | Yes | All | No |
| Pro expired | No (unless still in trial—normally no) | Blocked | N/A |

---

## 9. User flows

### 9.1 Trial journey

```
Register → trial starts
  → Use app with ads
  → Day 90+ → paywall
```

### 9.2 Purchase

```
Paywall / Menu → Subscription
  → Buy yearly → Store sheet
  → Success → ads disappear; expiresAt set
```

### 9.3 Restore

```
Reinstall → Register/Unlock
  → Subscription → Restore
  → Entitlement refreshed from store
```

---

## 10. UI / UX requirements

1. Paywall must state what user gets (ad-free, full features, 1 year).
2. Do not dark-pattern block cancel of store sheet.
3. Ads must not cover FABs or primary CTAs; ribbon reserved space.
4. Test ads labeled by Google in debug; production units in release.
5. ATT string on iOS for personalized ads (`NSUserTrackingUsageDescription`).

---

## 11. Configuration constants

```dart
freeTrialMonths = 3
yearlyPriceInr = 1800
yearlyProductId = 'household_expense_yearly_1800'
yearlyDuration = 365 days
```

AdConfig currently ships Google **test** IDs — replace before store.

---

## 12. Business rules

| ID | Rule |
|----|------|
| BR-S1 | Trial is time-based from registration/enrollment, not from first ad impression. |
| BR-S2 | Device enrollment helps prevent trial reset abuse (PRD-01). |
| BR-S3 | Ads allowed during trial by design. |
| BR-S4 | Legacy monthly tier not sold. |
| BR-S5 | Price copy INR-centric; international stores may show localized price. |

---

## 13. Edge cases

| Case | Behavior |
|------|----------|
| Store product missing | Show configuration error; don’t crash |
| Offline purchase | Store handles; show pending |
| Clock skew | Prefer store purchase time when available |
| User refunds | Entitlement may remain until re-query; document limitation without server |
| Ad load fail | Hide ribbon gap gracefully |

---

## 14. Acceptance criteria

- [ ] New registration: features work; ads show within load delay.
- [ ] Simulate trial end: paywall blocks Home.
- [ ] Successful purchase: ads gone; import works.
- [ ] Restore on second account/device per store rules.
- [ ] Cancel purchase: remains on trial/expired state correctly.
- [ ] Production build checklist: real AdMob + real IAP ids.

---

## 15. Store setup checklist

### Google Play
1. Create app `com.householdexpense.app`.
2. Create in-app product `household_expense_yearly_1800` (managed product / as designed).
3. Configure AdMob Android app + banner unit; fill `admob.properties`.

### App Store
1. Bundle `com.householdexpense.app`.
2. Create IAP with matching product id.
3. Set `GADApplicationIdentifier` + banner unit in `AdConfig.iosBannerId`.
4. Privacy nutrition labels for tracking/ads/purchases.

---

## 16. Dependencies

- `google_mobile_ads`, `in_app_purchase`
- PRD-01 registration date
- All feature PRDs for gating
- Release docs: `android/RELEASE.md`, `ios/RELEASE.md`

---

## 17. Privacy

Disclose ads and purchase data use. ATT on iOS when requesting tracking. No sale of ledger contents to ad networks.

---

## 18. Open questions / future

| ID | Item |
|----|------|
| OQ-S1 | Server receipt validation |
| OQ-S2 | Intro pricing / offers |
| OQ-S3 | Lifetime SKU |
| OQ-S4 | UMP consent form for EEA |

---

## 19. QA matrix

| # | Scenario | Pass |
|---|----------|------|
| 1 | Trial day 0 ads | Banner visible |
| 2 | Pro purchase sandbox | Ads hidden |
| 3 | Feature gate | Import blocked when expired |
| 4 | Restore sandbox | Entitlement returns |
| 5 | Ad fail | Layout stable |

---

## 20. Traceability

| Area | Path |
|------|------|
| Config | `subscription_config.dart`, `ad_config.dart` |
| Logic | `entitlement_service.dart`, `subscription_service.dart`, `ad_service.dart` |
| UI | `subscription_screen.dart`, `upgrade_prompt.dart`, `widgets/ads/*` |
| Model | `subscription_tier.dart` |

---

## 21. Summary

Monetization is a simple trial → yearly Pro funnel with ads during trial and a hard paywall after. Entitlements unlock the same feature set on Android and iOS; store configuration and production AdMob IDs are release-critical follow-ups.

---

## Appendix A — Detailed service contracts (Ads & Subscriptions)

This appendix enumerates expected service-level behaviors for engineering implementation and code review. Methods may be named slightly differently in Dart; the **behavior** is normative.

### A.1 Read paths

1. Load entities for the currently selected month key `YYYY-MM`.
2. Return empty collections rather than null for list UIs.
3. Never throw across the UI boundary without a user-visible error mapper.
4. Prefer a single DB transaction when reading multiple related tables for one screen.
5. Cache-in-memory for the duration of a tab visit is allowed; invalidate on CRUD.

### A.2 Write paths

1. Validate inputs before opening a write transaction.
2. On constraint violation (unique month+category, etc.), surface a recoverable message.
3. After successful write, notify listeners / setState / inherited refresh so Home, Expenses, and Analytics stay consistent.
4. Do not write if `canUseApp` is false (paywall), except where reading Help is allowed by shell rules.
5. Log failures with non-PII context only (no amounts/names in logcat beyond debug builds).

### A.3 Idempotency

Operations that can be retried (import commit chunks, recurring generation, restore) must be safe to invoke twice without corrupting totals. Use natural keys (`lastGeneratedMonth`, duplicate hashes, backup schema version) to enforce this.

### A.4 Testing hooks

- Unit tests for pure parsers/calculators under `test/`.
- Widget tests for critical forms where practical.
- Manual QA scripts in each PRD’s QA matrix remain the release gate for UX.

---

## Appendix B — Accessibility & internationalization

| Topic | Requirement |
|-------|-------------|
| Screen reader | Icon-only buttons need semantic labels (Add, Delete, Filter). |
| Contrast | Warning/over-budget colors meet readable contrast on glass backgrounds. |
| Text scale | Layouts should not clip at 1.3× system font where feasible. |
| Language | UI strings English in v1; keep strings out of business logic for future l10n. |
| Region | Currency, date order, phone validation, payment methods, bank lists from `RegionConfig`. |
| RTL | Not required in v1. |

---

## Appendix C — Rollout & feature flags

| Flag / config | Effect |
|---------------|--------|
| `AppFeatureFlags.smsQuickEntryEnabled` | Must remain `false` for store builds. |
| Entitlement `canAccess` | Gates premium surfaces during expired trial. |
| `DevAuthConfig.enableTestRegistration` | Debug-only; false in release. |
| AdMob test vs prod IDs | Swap before store upload. |
| `FeedbackConfig.adminSetupCode` | Rotate before Play/App Store. |

Rollout steps: internal dogfood → closed testing track → production. Monitor crash-free sessions after enabling ads/IAP.

---

## Appendix D — Support macros

**Macro 1 — “Feature not available”**  
Ask whether trial expired; guide to Subscription → Purchase/Restore.

**Macro 2 — “Data missing after update”**  
Confirm unlock works; ask if Clear Data was used; ask for backup file availability.

**Macro 3 — “Numbers look wrong”**  
Verify month selector, transfer flags, and savings category separation before escalating to parser bugs.

**Macro 4 — “Cannot import”**  
Collect file type, bank, OS version; remind entitlement; try Generic profile.

---

## Appendix E — Revision history

| Version | Date | Author | Notes |
|---------|------|--------|-------|
| 1.0 | 2026-07-10 | Product/Engineering | Initial PRD aligned to Flutter codebase `1.0.0+1` |
| 1.1 | 2026-07-10 | Product/Engineering | Appendices for contracts, a11y, rollout, support |

---

## Appendix F — Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Product | | | |
| Engineering | | | |
| QA | | | |
| Release manager | | | |

This document is the feature-level source of truth for **Ads & Subscriptions** until superseded by a dated revision in this folder.
