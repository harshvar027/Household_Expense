# PRD-11 — Admin Feedback Console

| Field | Value |
|-------|-------|
| **Product** | Household Expense |
| **Document ID** | PRD-11 |
| **Feature** | Hidden admin login and on-device feedback moderation |
| **Status** | Implemented (change setup code before store release) |
| **Owner** | Engineering / Creator |
| **Last updated** | 2026-07-10 |
| **Related code** | `lib/screens/admin/admin_login_screen.dart`, `admin_feedback_screen.dart`, `lib/services/admin_auth_service.dart`, entry via Help version taps, `lib/config/feedback_config.dart` |

---

## 1. Purpose

Define the lightweight **on-device admin console** used by the app creator (or trusted operator) to review user feedback stored locally (and optionally pulled from a remote sync endpoint). This is not a multi-tenant SaaS admin; it is a hidden tool inside the same binary.

---

## 2. Problem statement

User feedback accumulates in `user_feedback`. Without a console:

- The creator cannot triage statuses on a test device easily.
- Exporting for offline review is harder.
- A future remote sync endpoint needs a place to reconcile items.

The console must be **hidden** from normal users and protected by credentials, with a one-time setup code that **must** be rotated before public release.

---

## 3. Goals

| ID | Goal |
|----|------|
| G1 | Hidden entry: tap app version 5 times on Help & About. |
| G2 | Admin login with username `admin` (configurable). |
| G3 | First-time setup using `adminSetupCode`. |
| G4 | List feedback with status filters. |
| G5 | Edit status and admin notes. |
| G6 | Export feedback JSON. |
| G7 | Optional remote pull when `syncBaseUrl` configured. |
| G8 | Session flag `admin_logged_in_v1`. |

---

## 4. Non-goals

| ID | Non-goal |
|----|----------|
| NG1 | Role-based access for multiple employees. |
| NG2 | Full CRM / ticket SLA system. |
| NG3 | Pushing replies into user notification inbox. |
| NG4 | Moderating other users’ devices remotely without sync backend. |

---

## 5. Personas

- **App creator** — primary operator on a device that collected feedback or synced data.
- **QA engineer** — uses admin on debug builds to verify feedback pipeline.
- **End user** — must not stumble into admin casually.

---

## 6. User stories

1. As an admin, I can reveal login by tapping version five times.
2. As an admin on first launch of admin, I set a password using the setup code.
3. As an admin, I can filter New vs Resolved feedback.
4. As an admin, I can add notes and change status.
5. As an admin, I can export JSON for backup/analysis.
6. As an admin, if sync URL is set, I can refresh from server.
7. As a normal user, I do not see an Admin menu item.

---

## 7. Functional requirements

### 7.1 Access control

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-D01 | No Menu entry labeled Admin. | P0 |
| FR-D02 | Help version 5 taps → `AdminLoginScreen`. | P0 |
| FR-D03 | Username default `admin`. | P0 |
| FR-D04 | First run: verify `adminSetupCode` then set password hash in secure storage. | P0 |
| FR-D05 | Subsequent: password login sets session flag. | P0 |
| FR-D06 | Logout clears session. | P0 |
| FR-D07 | Release builds must not ship default `CHANGE-BEFORE-PLAY-RELEASE` setup code. | P0 |

### 7.2 Feedback console

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-D10 | List items newest first. | P0 |
| FR-D11 | Filter by status: New, In progress, Resolved, Closed. | P0 |
| FR-D12 | Detail view: type, title, body, timestamps. | P0 |
| FR-D13 | Edit status + adminNotes; save to DB. | P0 |
| FR-D14 | Export all/filtered JSON via share. | P1 |
| FR-D15 | Pull remote if `syncBaseUrl` non-empty; merge carefully. | P2 |

### 7.3 Security posture

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-D20 | Admin password not logged. | P0 |
| FR-D21 | Setup code only for first-time bootstrap. | P0 |
| FR-D22 | Obfuscation of gesture is not cryptography—accept risk; rely on password. | P0 |

---

## 8. User flows

### 8.1 First-time admin setup

```
Help → tap version ×5
  → Admin login
  → Enter setup code + new password
  → Console opens
```

### 8.2 Triage

```
Filter New → Open item
  → Set In progress + note
  → Later Resolved
```

### 8.3 Export

```
Console → Export JSON → Share to Drive
```

---

## 9. UI / UX requirements

1. Admin UI can be denser/utilitarian (not consumer neo-glass heavy).
2. Status chips color-coded.
3. Confirm before bulk export of sensitive feedback.
4. Clear “Not for end users” subtitle on login (optional, debug only).
5. Back navigation returns to Help without leaking session if logged out.

---

## 10. Data model

Reuses `user_feedback` (PRD-10) plus admin auth secrets in secure storage and session pref `admin_logged_in_v1`.

Statuses:

| Status | Meaning |
|--------|---------|
| New | Untouched |
| In progress | Being handled |
| Resolved | Fix/answer done |
| Closed | No further action |

---

## 11. Configuration

```dart
adminUsername = 'admin'
adminSetupCode = 'CHANGE-BEFORE-PLAY-RELEASE' // MUST CHANGE
syncBaseUrl = '' // empty disables remote
adminSessionKey = 'admin_logged_in_v1'
```

---

## 12. Business rules

| ID | Rule |
|----|------|
| BR-D1 | Admin console does not bypass app PIN for expense data; it is a separate gate after app unlock. |
| BR-D2 | Feedback export may contain PII—handle like support data. |
| BR-D3 | Remote sync is optional and off by default. |
| BR-D4 | Shipping default setup code is a release blocker. |

---

## 13. Edge cases

| Case | Behavior |
|------|----------|
| Wrong setup code | Reject; no lockout complexity required in v1 |
| Forgotten admin password | Document reinstall/clear app data last resort; or add reset via setup code if implemented |
| Empty feedback list | Empty state |
| syncBaseUrl down | Show error; keep local list |

---

## 14. Acceptance criteria

- [ ] No visible Admin in Menu.
- [ ] 5 taps opens login.
- [ ] First-time setup code works once; password thereafter.
- [ ] Status edits persist across app restart (while DB intact).
- [ ] Export produces parseable JSON.
- [ ] With empty syncBaseUrl, no failed network calls on open.
- [ ] Release checklist includes setup code rotation.

---

## 15. Threat model (brief)

| Threat | Mitigation |
|--------|------------|
| Curious user finds gesture | Password required |
| Attacker knows default setup code | Change before release |
| Feedback JSON shared widely | Operator caution |
| Malicious sync server | Keep syncBaseUrl empty unless trusted |

---

## 16. Dependencies

- PRD-10 feedback capture
- `AdminAuthService`
- Secure storage
- Optional HTTP client for sync

---

## 17. Privacy

Admin sees only feedback on **this device** (plus remote if enabled). No access to other customers’ phones.

---

## 18. Open questions / future

| ID | Item |
|----|------|
| OQ-D1 | Hosted admin web dashboard |
| OQ-D2 | Reply-to-user email from console |
| OQ-D3 | Biometric gate for admin |
| OQ-D4 | Audit log of status changes |

---

## 19. QA matrix

| # | Test | Pass |
|---|------|------|
| 1 | Gesture | Opens login |
| 2 | Setup | Password set |
| 3 | Login | Console |
| 4 | Filter | Status works |
| 5 | Export | JSON ok |
| 6 | Logout | Session cleared |

---

## 20. Release checklist (admin-specific)

1. Change `adminSetupCode` to a high-entropy secret.
2. Decide whether admin entry should be compiled out of production (`kReleaseMode` guard) — optional hardening.
3. Verify syncBaseUrl empty for store build unless backend ready.
4. Test feedback → admin list path on release candidate.

---

## 21. Traceability

| Area | Path |
|------|------|
| Login | `admin_login_screen.dart` |
| Console | `admin_feedback_screen.dart` |
| Auth | `admin_auth_service.dart` |
| Config | `feedback_config.dart` |
| Entry | `help_about_screen.dart` version gesture |

---

## 22. Summary

The admin feedback console is a hidden, password-protected triage tool for on-device (and optionally synced) user feedback. It is essential for the creator workflow but must ship with a rotated setup code and no end-user discoverability beyond the obscure version gesture.

---

## Appendix A — Detailed service contracts (Admin Feedback Console)

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

This document is the feature-level source of truth for **Admin Feedback Console** until superseded by a dated revision in this folder.
