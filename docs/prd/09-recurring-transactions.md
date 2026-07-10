# PRD-09 — Recurring Transactions

| Field | Value |
|-------|-------|
| **Product** | Household Expense |
| **Document ID** | PRD-09 |
| **Feature** | Recurring expenses/income, auto-generation, missing payment banner |
| **Status** | Implemented |
| **Owner** | Product / Engineering |
| **Last updated** | 2026-07-10 |
| **Related code** | `lib/services/recurring_service.dart`, `lib/models/recurring_transaction.dart`, Settings Recurring tab in `settings_screen.dart`, `lib/widgets/missing_recurring_banner.dart` |

---

## 1. Purpose

Define how users set up repeating financial events (rent, salary, subscriptions) so the ledger stays complete without manual re-entry each month. The system auto-generates ledger rows and nudges users when an expected recurring expense appears missing.

---

## 2. Problem statement

Many household costs repeat monthly. Forgetting to log rent skews budgets and analytics. Users need:

- A template for recurring expense or income.
- Automatic creation when a month is opened/processed.
- A Home banner when a due recurring expense has no matching “real” transaction.
- Simple day-of-month scheduling without full calendar RRULE complexity.

---

## 3. Goals

| ID | Goal |
|----|------|
| G1 | CRUD recurring templates (expense or income). | 
| G2 | Fields: item, amount, category, dayOfMonth (1–28), payment method, active flag. |
| G3 | Auto-generate entries for current/eligible months via `RecurringService`. |
| G4 | Mark generated expenses with notes marker `recurring`. |
| G5 | Track `lastGeneratedMonth` to avoid duplicates. |
| G6 | Home `MissingRecurringBanner` for past-due gaps. |
| G7 | Manage list under Settings → Recurring. |

---

## 4. Non-goals

| ID | Non-goal |
|----|----------|
| NG1 | Weekly/biweekly/yearly advanced recurrence (v1 monthly only). |
| NG2 | Automatic bank charge detection beyond heuristics in insights. |
| NG3 | Pausing for N months with complex schedules. |
| NG4 | Multi-currency recurring. |

---

## 5. Personas

- **Renter** — rent on the 1st.
- **Salaried** — income on the 28th.
- **Subscriber** — OTT/mobile bills mid-month.

---

## 6. User stories

1. As a user, I can create a recurring rent expense on day 1.
2. As a user, when I open the app in a new month, rent is auto-added.
3. As a user, I can create recurring salary income.
4. As a user, I can deactivate a recurring item without deleting history.
5. As a user, I see a Home banner if rent is due but missing.
6. As a user, I can edit amount when rent increases.

---

## 7. Functional requirements

### 7.1 Template CRUD

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-R01 | Create recurring expense or income from Settings. | P0 |
| FR-R02 | Validate dayOfMonth in 1..28 (avoid 29–31 month-end bugs). | P0 |
| FR-R03 | Edit amount/category/payment/day. | P0 |
| FR-R04 | Soft-disable via `isActive=false`. | P0 |
| FR-R05 | Delete template; do not cascade-delete past generated rows. | P1 |

### 7.2 Generation

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-R10 | On month view / app resume processing, run generation for active templates. | P0 |
| FR-R11 | Create expense/income dated on dayOfMonth within month (clamp if needed). | P0 |
| FR-R12 | Update `lastGeneratedMonth` to `YYYY-MM`. | P0 |
| FR-R13 | Idempotent: do not double-generate same month. | P0 |
| FR-R14 | Generated expense notes include `recurring` token. | P0 |

### 7.3 Missing banner

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-R20 | Detect active expense recurrings past due day without matching non-stub txn. | P0 |
| FR-R21 | Show banner on Home with actionable copy. | P0 |
| FR-R22 | Dismiss for session or navigate to fix. | P1 |

---

## 8. User flows

### 8.1 Setup rent

```
Settings → Recurring → Add Expense
  → Rent, 15000, Housing, day 1, UPI
  → Save
```

### 8.2 New month

```
Open app on May 1+
  → RecurringService generates May rent
  → Appears in Expenses; budget updates
```

### 8.3 Missing detection

```
User deleted auto row OR generation failed
  → After due day → Home banner “Rent not logged”
```

---

## 9. UI / UX requirements

1. Recurring list shows next due hint.
2. Day picker limited to 1–28 with helper text why.
3. Distinguish expense vs income templates visually.
4. Banner not permanently blocking Home content; dismissible.
5. Editing amount should not rewrite past months’ generated rows.

---

## 10. Data model

### 10.1 `recurring_transactions`

| Column | Notes |
|--------|-------|
| id | PK |
| item | description |
| amount | |
| category | |
| dayOfMonth | 1–28 |
| paymentMethod | |
| type | expense / income |
| isActive | |
| lastGeneratedMonth | `YYYY-MM` nullable |

### 10.2 Generated ledger rows

Normal `expenses` / `income` rows; notes marker for expenses.

---

## 11. Business rules

| ID | Rule |
|----|------|
| BR-R1 | Monthly frequency only in v1. |
| BR-R2 | Day >28 rejected to avoid Feb/short month issues. |
| BR-R3 | Inactive templates skip generation. |
| BR-R4 | Generation respects entitlement (`canUseApp`); if paywalled, skip or defer. |
| BR-R5 | Auto rows count toward budgets like manual rows. |

---

## 12. Edge cases

| Case | Behavior |
|------|----------|
| App not opened all month | Generate when next opened (backfill policy: current month only vs catch-up — document actual: typically current processing month) |
| User edits generated row | Remains; lastGeneratedMonth still set |
| User deletes generated row | Banner may appear; user can recreate manually |
| Timezone midnight | Use local device date |
| Amount change mid-month | Affects future generations only |

---

## 13. Acceptance criteria

- [ ] Create recurring expense day 1; in new month row appears once.
- [ ] Second open same month does not duplicate.
- [ ] Income recurring creates income row.
- [ ] Deactivate stops future generation.
- [ ] Delete generated rent → banner can show after due.
- [ ] day 31 rejected by validation.

---

## 14. Dependencies

- PRD-02 ledger writers
- PRD-03 budgets consume generated spend
- PRD-07 entitlement
- Home tab hosts banner
- Settings Recurring tab

---

## 15. Privacy

Recurring templates stored on-device; included in backups.

---

## 16. Open questions / future

| ID | Item |
|----|------|
| OQ-R1 | Weekly cadence |
| OQ-R2 | End date / occurrence count |
| OQ-R3 | Variable amount (approx) |
| OQ-R4 | Link to merchant rules |

---

## 17. QA matrix

| # | Scenario | Pass |
|---|----------|------|
| 1 | Generate once | Single row |
| 2 | Idempotent | Still single |
| 3 | Income type | Income segment |
| 4 | Inactive | No new row |
| 5 | Banner | Shows when missing |

---

## 18. Traceability

| Area | Path |
|------|------|
| Service | `recurring_service.dart` |
| Model | `recurring_transaction.dart` |
| UI | Settings Recurring tab |
| Banner | `missing_recurring_banner.dart` |
| DB | `database_helper.dart` schema v9 |

---

## 19. Support notes

- “Duplicate rent” → check lastGeneratedMonth / manual duplicates.
- “Rent missing” → ensure template active and day reached.
- “Wrong day” → edit template; won’t move past row.

---

## 20. Summary

Recurring transactions keep monthly obligations visible in the ledger with minimal friction. Constraining day-of-month to 1–28 and tracking last generated month keeps behavior predictable across Android and iOS.

---

## Appendix A — Detailed service contracts (Recurring Transactions)

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

This document is the feature-level source of truth for **Recurring Transactions** until superseded by a dated revision in this folder.
