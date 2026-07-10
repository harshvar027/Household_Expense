# PRD-01 — Authentication & Security

| Field | Value |
|-------|-------|
| **Product** | Household Expense |
| **Document ID** | PRD-01 |
| **Feature** | Authentication, session lock, biometrics, device enrollment |
| **Status** | Implemented (production-ready with release checklist items) |
| **Owner** | Product / Engineering |
| **Last updated** | 2026-07-10 |
| **Related code** | `lib/screens/auth/`, `lib/services/auth_service.dart`, `biometric_auth_service.dart`, `device_enrollment_service.dart`, `database_key_service.dart` |

---

## 1. Purpose

This document defines the product requirements for how users create an account, unlock the app, recover credentials, manage security settings, and how the application protects financial data at rest and during session transitions.

Household Expense is an **on-device** finance app. There is no cloud account server for login. “Registration” creates a local profile and cryptographic material on the device. Security must therefore be strong enough that a lost phone or casual access does not expose expense history, while remaining usable for daily household use.

---

## 2. Problem statement

Household finance data is sensitive. Users need:

1. A clear first-run setup (who they are, household, region, currency).
2. Fast daily unlock (PIN or biometrics) without re-entering long passwords every time.
3. Protection when the app is backgrounded (e.g., after checking a bank PDF).
4. Local recovery if they forget a PIN, without depending on SMS OTP infrastructure.
5. Assurance that database contents are encrypted even if the filesystem is inspected.

Without a coherent auth model, either usability suffers (constant friction) or security fails (unlocked data on a shared phone).

---

## 3. Goals

| ID | Goal |
|----|------|
| G1 | One registration per device enrollment; trial clock starts at enrollment. |
| G2 | Support PIN (primary) and password lock methods. |
| G3 | Optional biometric unlock where hardware allows. |
| G4 | Lock the UI when the app goes to background (with controlled exceptions). |
| G5 | Local forgot-credentials flow using email + phone already stored on device. |
| G6 | Keep SQLCipher DB key separate from user PIN/password material. |
| G7 | Provide Account Security screen for profile and lock management. |

---

## 4. Non-goals

| ID | Non-goal |
|----|----------|
| NG1 | Cloud identity provider (Firebase Auth, OAuth, Sign in with Apple/Google). |
| NG2 | Multi-device sync of the same account. |
| NG3 | SMS or email OTP for recovery. |
| NG4 | Enterprise MDM / SSO. |
| NG5 | Sharing one live session across family phones. |

---

## 5. Personas

### 5.1 Primary — Household finance owner
Adult who installs the app, registers the household, and unlocks daily. Values speed (Face ID / PIN) and privacy.

### 5.2 Secondary — Shared-device user
Spouse or parent who may briefly hand the phone to a child. Needs automatic lock on background.

### 5.3 Edge — Returning user after reinstall
May lose local profile; device enrollment rules and backup/restore (PRD-06) interact with this persona.

---

## 6. User stories

1. As a new user, I can register with name, email, phone, household name, region, and currency so the app personalizes money formatting and banks.
2. As a registered user, I can unlock with a 4–6 digit PIN (or password) to open my dashboard.
3. As a user with biometrics enabled, I can unlock with Face ID / fingerprint without typing my PIN each time.
4. As a user who forgot my PIN, I can prove identity with email + phone and set a new lock secret.
5. As a security-conscious user, I expect the app to lock when I leave it, except when I am picking a file or sharing a report.
6. As a user, I can change my lock method and update profile fields from Account Security.
7. As product, we prevent trivial re-registration on the same device solely to reset the free trial.

---

## 7. Functional requirements

### 7.1 First-run & registration

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-A01 | Show Welcome → Register when no local profile / login flag exists. | P0 |
| FR-A02 | Collect: full name, email, phone, household name, region, preferred currency, optional primary bank. | P0 |
| FR-A03 | Validate email format, phone rules per region, and non-empty required fields. | P0 |
| FR-A04 | Require user to choose lock method (PIN default) and confirm secret. | P0 |
| FR-A05 | Persist profile in SharedPreferences; store hashed lock secret in secure storage. | P0 |
| FR-A06 | Initialize SQLCipher key via `DatabaseKeyService` on first successful setup. | P0 |
| FR-A07 | Call device enrollment to record trial start anchor. | P0 |
| FR-A08 | Block or discourage re-registration that would reset trial on same device. | P0 |

### 7.2 Login / unlock

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-A10 | After registration, cold start shows unlock (PIN/password), not welcome. | P0 |
| FR-A11 | Successful unlock opens `ExpenseScreen` main shell. | P0 |
| FR-A12 | Failed unlock shows clear error; does not reveal whether email exists (N/A locally). | P1 |
| FR-A13 | Optional biometric prompt when enabled and hardware available. | P0 |
| FR-A14 | Biometric failure falls back to PIN/password. | P0 |

### 7.3 Session lock

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-A20 | When app lifecycle goes to paused/inactive/background, require unlock on resume. | P0 |
| FR-A21 | Suppress lock while `AuthService.runWithNativeSheetGuard` is active (file picker, share, email). | P0 |
| FR-A22 | Lock must not corrupt in-progress form state beyond normal Flutter disposal rules. | P1 |

### 7.4 Forgot credentials

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-A30 | Forgot flow asks for email + phone matching stored profile. | P0 |
| FR-A31 | On match, allow setting a new PIN or password. | P0 |
| FR-A32 | On mismatch, show generic failure; do not wipe data. | P0 |
| FR-A33 | Do not send network OTP. | P0 |

### 7.5 Account security

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-A40 | Edit display name, household, region, bank preference. | P0 |
| FR-A41 | Change lock method and secret with current-secret confirmation. | P0 |
| FR-A42 | Toggle biometric unlock. | P0 |
| FR-A43 | Logout clears session flag and returns to unlock/welcome as designed. | P0 |

### 7.6 Cryptography & storage

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-A50 | Expense DB encrypted with SQLCipher; key never logged. | P0 |
| FR-A51 | Auth secrets and DB key use platform secure storage options appropriate to Android/iOS. | P0 |
| FR-A52 | Backup encryption key is separate (see PRD-06); PIN hashes are not included in backup. | P0 |

---

## 8. User flows

### 8.1 Happy path — first install

```
Install → Splash (AuthGate)
  → Welcome
  → Register (profile + region + lock secret)
  → Enrollment + DB key init
  → Main app (trial starts)
```

### 8.2 Happy path — daily use

```
Cold start → Unlock (biometric or PIN)
  → Home tab
  → User backgrounds app
  → Resume → Unlock again
```

### 8.3 File import without false lock

```
Menu → Import → Native file picker (guard ON)
  → User selects PDF
  → Guard OFF → Preview (still unlocked)
```

### 8.4 Forgot PIN

```
Unlock → Forgot credentials
  → Enter email + phone
  → Match → New PIN confirm
  → Unlock with new PIN
```

---

## 9. UI / UX requirements

1. **Splash / AuthGate** — branded, short; no flash of main UI before auth decision.
2. **Welcome** — clear CTA: Create account / I already have an account (local).
3. **Register** — multi-section form; region selection drives currency and phone hints.
4. **Unlock** — large PIN pad or password field; biometric affordance when enabled.
5. **Errors** — human-readable; avoid stack traces.
6. **Accessibility** — sufficient contrast on neo-glass surfaces; large tap targets for PIN keys.
7. **iOS** — `NSFaceIDUsageDescription` present explaining expense unlock.
8. **Android** — `USE_BIOMETRIC` permission; activity must support fragment biometrics (`FlutterFragmentActivity`).

---

## 10. Data model

### 10.1 Profile (SharedPreferences / structured prefs)

| Field | Description |
|-------|-------------|
| name | Display name |
| email | Recovery + identity |
| phone | Recovery + identity |
| householdName | Label |
| region / currency | Formatting & banks |
| primaryBank | Optional preference |
| login / registered flags | Gate AuthGate routing |

### 10.2 Secure storage

| Key purpose | Notes |
|-------------|-------|
| PIN/password hash | Not reversible |
| SQLCipher DB key | 256-bit material |
| Biometric preference | Flag |
| Backup AES key | PRD-06 |

### 10.3 Device enrollment

Stores an enrollment record used to anchor trial start and detect re-registration attempts on the same device.

---

## 11. Business rules

| ID | Rule |
|----|------|
| BR-A1 | Free trial duration is measured from registration/enrollment date (`SubscriptionConfig.freeTrialMonths = 3`). |
| BR-A2 | Auth success does not imply premium; entitlement is separate (PRD-07). |
| BR-A3 | Dev-only test registration bypass exists (`DevAuthConfig.enableTestRegistration`) and must remain **false** for store builds. |
| BR-A4 | Logout must not delete the encrypted database unless user explicitly clears data elsewhere. |

---

## 12. Edge cases & error handling

| Case | Expected behavior |
|------|-------------------|
| Biometrics unavailable after OS revoke | Fall back to PIN; show enable hint in Account Security. |
| User changes region | Currency symbol and bank lists update; historical amounts stay numeric. |
| Secure storage wiped by OS | App may be unable to open DB; guide user to restore backup if available. |
| Rapid background during navigation | Still lock; no double AuthGate stacks. |
| Empty PIN confirm mismatch | Block save; highlight fields. |
| Reinstall without backup | New registration path; enrollment may limit trial abuse. |

---

## 13. Acceptance criteria

- [ ] Fresh install shows Welcome, not main tabs.
- [ ] After register, kill app → Unlock required.
- [ ] Wrong PIN rejected; correct PIN opens Home.
- [ ] Enable Face ID / fingerprint → unlock works; disable → PIN only.
- [ ] Background app 5s → resume requires unlock.
- [ ] During CSV/PDF pick, returning from picker does **not** force unlock mid-flow.
- [ ] Forgot credentials with wrong phone fails; correct pair allows reset.
- [ ] DB file on disk is not readable as plaintext SQLite.
- [ ] `enableTestRegistration` is false in release configuration.

---

## 14. Platform notes

| Platform | Notes |
|----------|-------|
| Android | `MainActivity` extends `FlutterFragmentActivity`; backup disabled at app level. |
| iOS | Face ID usage string; Keychain via `flutter_secure_storage` IOSOptions. |
| Web/desktop | Biometrics skipped; product focus remains mobile. |

---

## 15. Dependencies

- `flutter_secure_storage`
- `local_auth`
- `shared_preferences`
- `sqflite_sqlcipher` + `DatabaseKeyService`
- EntitlementService (trial clock)
- PRD-06 Backup (recovery of data, not of PIN)

---

## 16. Analytics & privacy

No auth credentials are sent to analytics backends (none required for auth). Privacy policy must state: credentials and DB stay on device; recovery is local email+phone match.

---

## 17. Open questions / future

| ID | Item | Disposition |
|----|------|-------------|
| OQ-A1 | Cloud sync of encrypted vaults | Out of scope v1 |
| OQ-A2 | Hardware security key | Not planned |
| OQ-A3 | Auto-lock timeout (N minutes idle) vs immediate background lock | Current: lifecycle-based; may add idle timeout later |
| OQ-A4 | Multiple profiles on one device | Not supported |

---

## 18. Test plan (QA)

| # | Scenario | Steps | Pass |
|---|----------|-------|------|
| 1 | Register IN region | Complete form, PIN 1234 confirm | Opens app; ₹ formatting |
| 2 | Biometric | Enable in Account Security; kill; unlock with bio | Success |
| 3 | Guard | Start import; background during picker | No spurious lock failure |
| 4 | Forgot | Wrong email; then correct email+phone | Only second succeeds |
| 5 | Logout | Logout → unlock/welcome as designed | Data still present after unlock |

---

## 19. Release checklist (auth-specific)

1. Confirm `DevAuthConfig.enableTestRegistration == false`.
2. Verify Face ID string on iOS and biometric permission on Android.
3. Manual test of lock-on-background on both OS versions targeted.
4. Document for support: “Forgot PIN needs the same email and phone you registered with.”

---

## 20. Traceability

| Requirement area | Primary implementation |
|------------------|------------------------|
| Gate / splash | `lib/screens/auth/auth_gate.dart` |
| Welcome / register / login | `welcome_auth_screen.dart`, `register_screen.dart`, `login_screen.dart` |
| Forgot | `forgot_credentials_screen.dart` |
| Account security | `account_security_screen.dart` |
| Auth logic | `lib/services/auth_service.dart` |
| Biometrics | `lib/services/biometric_auth_service.dart` |
| Enrollment | `lib/services/device_enrollment_service.dart` |
| DB key | `lib/services/database_key_service.dart` |
| Validators | `lib/utils/auth_validators.dart` |

---

## 21. Summary

Authentication in Household Expense is a **local trust boundary**: registration creates identity and crypto material on-device; unlock protects the UI; SQLCipher protects data at rest; controlled native-sheet guards preserve usability during import/share. This PRD is the source of truth for auth behavior across Android and iOS parity builds.
