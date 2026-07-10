# PRD-10 — Settings, Help & Feedback

| Field | Value |
|-------|-------|
| **Product** | Household Expense |
| **Document ID** | PRD-10 |
| **Feature** | Settings hub, Help & About, user feedback submission |
| **Status** | Implemented |
| **Owner** | Product / Engineering / Support |
| **Last updated** | 2026-07-10 |
| **Related code** | `lib/screens/settings_screen.dart`, `help_about_screen.dart`, `feedback_screen.dart`, `lib/services/feedback_service.dart`, `feedback_email_service.dart`, `feedback_sync_service.dart`, `lib/config/feedback_config.dart` |

---

## 1. Purpose

Define the secondary product surfaces where users configure the household, manage data tools, learn about the app, and send feedback to the creator/support inbox. Settings is a hub; Help builds trust; Feedback closes the loop.

---

## 2. Problem statement

Power features (members, accounts, recurring, goals, backup) must be discoverable without cluttering Home. Users also need:

- A single **Settings** place with clear tabs.
- **Help & About** with version, tips, contact.
- **Feedback** for bugs and feature requests stored locally and optionally emailed.
- A hidden path to admin tools (PRD-11) without exposing it to casual users.

---

## 3. Goals

| ID | Goal |
|----|------|
| G1 | Settings tabs: Household, Accounts, Recurring, Goals, Data. |
| G2 | Shortcuts to profile/security where appropriate. |
| G3 | Help screen with app blurb, tips, creator contact, version. |
| G4 | Feedback form: Bug / New requirement / General. |
| G5 | Persist feedback in `user_feedback` table. |
| G6 | Optional email via `flutter_email_sender` to support address. |
| G7 | Optional remote sync only if `FeedbackConfig.syncBaseUrl` set. |
| G8 | Version label 5× tap → admin login entry. |

---

## 4. Non-goals

| ID | Non-goal |
|----|----------|
| NG1 | Full in-app knowledge base / CMS. |
| NG2 | Live chat support. |
| NG3 | Crowdsourced public issue tracker inside app. |
| NG4 | Forced feedback nags every session. |

---

## 5. Personas

- **Configurator** — spends time in Settings tabs.
- **Confused new user** — opens Help tips.
- **Bug reporter** — sends feedback with repro steps.
- **Creator/admin** — uses hidden admin entry (PRD-11).

---

## 6. User stories

1. As a user, I can open Settings from Menu and manage household entities.
2. As a user, I can backup/restore from Settings → Data (PRD-06).
3. As a user, I can read what the app does and who built it.
4. As a user, I can submit a bug report that is saved on my device.
5. As a user, I can email feedback to support when a mail client exists.
6. As a developer, I can open admin by tapping version five times.

---

## 7. Functional requirements

### 7.1 Settings hub

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-K01 | Tabbed Settings with Household, Accounts, Recurring, Goals, Data. | P0 |
| FR-K02 | Each tab implements its PRD (08, 09, 03, 06). | P0 |
| FR-K03 | Merchant rules management accessible if exposed in Data/Settings. | P1 |
| FR-K04 | Navigation from Menu → Settings. | P0 |

### 7.2 Help & About

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-K10 | Show app name, short description, version from `FeedbackConfig.appVersion`. | P0 |
| FR-K11 | Show creator name and phone/email contact. | P0 |
| FR-K12 | Tips for import, budget, backup. | P1 |
| FR-K13 | CTA to open Feedback screen. | P0 |
| FR-K14 | Version widget counts taps for admin entry. | P0 |

### 7.3 Feedback

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-K20 | Types: Bug, New requirement, General. | P0 |
| FR-K21 | Fields: title/subject, details, optional contact. | P0 |
| FR-K22 | Save locally with status New + timestamps. | P0 |
| FR-K23 | Attempt email compose to `FeedbackConfig` support email. | P1 |
| FR-K24 | If `syncBaseUrl` empty, skip remote sync silently. | P0 |
| FR-K25 | Success/failure messaging without crashing when no mail app. | P0 |

### 7.4 Config

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-K30 | Support email configurable in `feedback_config.dart`. | P0 |
| FR-K31 | `adminSetupCode` must be changed before Play release (documented). | P0 |

---

## 8. User flows

### 8.1 Change household setup

```
Menu → Settings → Household/Accounts/...
  → Edit → Back to Menu
```

### 8.2 Send bug

```
Help → Send feedback → Type Bug
  → Write steps → Submit
  → Saved + optional email composer
```

### 8.3 Admin reveal

```
Help → Tap version 5×
  → Admin login screen (PRD-11)
```

---

## 9. UI / UX requirements

1. Settings tabs: one job per tab; avoid mega-scroll of unrelated controls.
2. Help tone: calm, trustworthy, not salesy.
3. Feedback: require enough detail (min characters) to be useful.
4. Do not advertise admin entry in copy.
5. Respect safe areas; works with ad ribbon on Menu underneath.

---

## 10. Data model

### 10.1 `user_feedback`

| Column | Notes |
|--------|-------|
| id | PK |
| type | bug / requirement / general |
| title | |
| body | |
| status | New / In progress / … (admin updates) |
| createdAt | |
| adminNotes | nullable |

### 10.2 Config keys

`appVersion`, support email, creator phone, `syncBaseUrl`, admin username/setup code.

---

## 11. Business rules

| ID | Rule |
|----|------|
| BR-K1 | Feedback always stores locally first. |
| BR-K2 | Email is best-effort. |
| BR-K3 | Remote sync off by default. |
| BR-K4 | Admin entry hidden behind gesture. |
| BR-K5 | Settings available whenever `canUseApp` (or limited when paywalled—align with shell). |

---

## 12. Edge cases

| Case | Behavior |
|------|----------|
| No email app | Local save still succeeds; explain email skipped |
| Empty feedback | Block submit |
| Rapid 5 taps accidental | Acceptable; admin still needs credentials |
| syncBaseUrl misconfigured | Fail soft; keep local |

---

## 13. Acceptance criteria

- [ ] All five Settings tabs open and perform their CRUD.
- [ ] Help shows version and contact.
- [ ] Feedback saves and appears for admin list after admin login.
- [ ] Email composer opens when available.
- [ ] 5 taps opens admin login.
- [ ] With empty syncBaseUrl, no network error spam.

---

## 14. Dependencies

- PRD-03 Goals tab
- PRD-06 Data tab
- PRD-08 Household/Accounts
- PRD-09 Recurring
- PRD-11 Admin
- `flutter_email_sender`, `url_launcher` as used

---

## 15. Privacy

Feedback may include personal data; treat as support PII. Email leaves device only if user sends.

---

## 16. Open questions / future

| ID | Item |
|----|------|
| OQ-K1 | In-app FAQ search |
| OQ-K2 | Screenshot attach on feedback |
| OQ-K3 | Public changelog screen |
| OQ-K4 | Localized Help |

---

## 17. QA matrix

| # | Test | Pass |
|---|------|------|
| 1 | Tab navigation | All tabs |
| 2 | Feedback save | Row in DB |
| 3 | Email | Composer or graceful skip |
| 4 | Version gesture | Admin login |
| 5 | Help tips | Readable |

---

## 18. Traceability

| Area | Path |
|------|------|
| Settings | `settings_screen.dart` |
| Help | `help_about_screen.dart` |
| Feedback UI | `feedback_screen.dart` |
| Services | `feedback_service.dart`, `feedback_email_service.dart`, `feedback_sync_service.dart` |
| Config | `feedback_config.dart` |

---

## 19. Support SLAs (product intent)

- Feedback is best-effort human response via email.
- No guaranteed response time in-app.
- Critical security issues: prefer email subject prefix `[SECURITY]`.

---

## 20. Summary

Settings, Help, and Feedback form the product’s control plane and support channel. They connect configuration PRDs, educate users, and capture issues locally—with optional email—while keeping admin tools intentionally obscure.

---

## Appendix A — Detailed service contracts (Settings, Help & Feedback)

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

This document is the feature-level source of truth for **Settings, Help & Feedback** until superseded by a dated revision in this folder.
