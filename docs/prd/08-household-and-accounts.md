# PRD-08 — Household Members & Accounts

| Field | Value |
|-------|-------|
| **Product** | Household Expense |
| **Document ID** | PRD-08 |
| **Feature** | Household members, payment attribution, financial accounts |
| **Status** | Implemented |
| **Owner** | Product / Engineering |
| **Last updated** | 2026-07-10 |
| **Related code** | `lib/screens/settings_screen.dart` (Household, Accounts tabs), `lib/models/household_member.dart`, `account.dart`, `lib/widgets/member_spending_card.dart`, `DatabaseHelper._seedDefaults` |

---

## 1. Purpose

Define how a household is modeled inside the app: people (members) who pay for expenses, and accounts that hold or source funds. These entities enrich the ledger (PRD-02), power member analytics (PRD-04), and target statement imports (PRD-05).

---

## 2. Problem statement

Single-user expense apps fail multi-person homes. Users need:

- Tag **who paid** (Self, Spouse, Parent, etc.).
- Multiple **accounts** (Main, Salary, Wallet) for import and filtering.
- Sensible defaults so first-run is not empty configuration hell.
- Protection against deleting critical defaults.

---

## 3. Goals

| ID | Goal |
|----|------|
| G1 | Seed default member **Self** (not deletable). |
| G2 | CRUD additional members with name/role. |
| G3 | Seed default **Main Account**. |
| G4 | CRUD accounts with type, default flag, optional bankId. |
| G5 | Expense forms offer member + account pickers. |
| G6 | Analytics member spending uses memberId. |
| G7 | Import can target a selected account. |

---

## 4. Non-goals

| ID | Non-goal |
|----|----------|
| NG1 | Per-member login / permissions. |
| NG2 | Settling IOUs between members. |
| NG3 | Bank balance reconciliation ledger per account (beyond import tagging). |
| NG4 | Shared cloud household. |

---

## 5. Personas

- **Family lead** — adds Spouse and Child members.
- **Multi-bank user** — HDFC salary + Axis savings accounts.
- **Solo user** — never leaves Self + Main Account.

---

## 6. User stories

1. As a user, I see Self pre-created after registration.
2. As a user, I can add a member “Spouse” and tag expenses as paid by Spouse.
3. As a user, I cannot delete Self.
4. As a user, I can add a second account for another bank.
5. As a user, I can mark one account as default for new expenses.
6. As a user, I can view spending by member on Analytics.
7. As a user, I can import a statement into a specific account.

---

## 7. Functional requirements

### 7.1 Members

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-H01 | Table `household_members` with name, role, flags. | P0 |
| FR-H02 | Seed Self on DB init. | P0 |
| FR-H03 | Add/edit member from Settings → Household. | P0 |
| FR-H04 | Delete member only if not protected; handle expenses with that member (null or block). | P0 |
| FR-H05 | Expense form “Paid by” dropdown. | P0 |

### 7.2 Accounts

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-H10 | Table `accounts` with name, type (e.g., Savings), isDefault, bankId. | P0 |
| FR-H11 | Seed Main Account. | P0 |
| FR-H12 | CRUD in Settings → Accounts. | P0 |
| FR-H13 | Only one default account at a time. | P0 |
| FR-H14 | Expense form account picker defaults to isDefault. | P0 |
| FR-H15 | Import screen account selector. | P0 |

### 7.3 Analytics linkage

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-H20 | Member spending card aggregates by memberId. | P0 |
| FR-H21 | Unassigned expenses grouped clearly. | P1 |

---

## 8. User flows

### 8.1 Add member

```
Settings → Household → Add
  → Name + role → Save
  → Appears in Paid by lists
```

### 8.2 Add account

```
Settings → Accounts → Add
  → Name, type, bank → Set default optional
  → Import/Expense pickers update
```

### 8.3 Retire member

```
Delete member → Confirm
  → Historical expenses retain name snapshot OR null memberId per implementation
```

---

## 9. UI / UX requirements

1. Household and Accounts are separate Settings tabs (single job each).
2. Default badges on Self / default account.
3. Empty custom lists still show seeded defaults.
4. Destructive delete confirms impact.

---

## 10. Data model

### 10.1 `household_members`

| Column | Notes |
|--------|-------|
| id | PK |
| name | |
| role | optional string |
| isDefault / isProtected | Self protection |

### 10.2 `accounts`

| Column | Notes |
|--------|-------|
| id | PK |
| name | |
| type | Savings/Current/Cash/... |
| isDefault | bool |
| bankId | optional region bank key |

### 10.3 FKs on expenses

`memberId`, `accountId` nullable or required per form validation rules.

---

## 11. Business rules

| ID | Rule |
|----|------|
| BR-H1 | Self cannot be deleted. |
| BR-H2 | At least one account should remain. |
| BR-H3 | Setting a new default clears previous default. |
| BR-H4 | Member analytics exclude transfers if spend rules say so (align PRD-04). |
| BR-H5 | Region bank list feeds account bankId suggestions. |

---

## 12. Edge cases

| Case | Behavior |
|------|----------|
| Delete member with expenses | Block or reassign; never orphan crash |
| Rename member | Analytics label updates |
| No members somehow | Re-seed Self |
| Duplicate names | Allowed; distinguish by id |

---

## 13. Acceptance criteria

- [ ] Fresh DB has Self + Main Account.
- [ ] Add Spouse; tag expense; Analytics shows Spouse amount.
- [ ] Cannot delete Self.
- [ ] Two accounts; default switches correctly on new expense.
- [ ] Import into non-default account tags rows to that account.

---

## 14. Dependencies

- PRD-02 expense form fields
- PRD-04 member card
- PRD-05 import account
- RegionConfig banks
- Database seed

---

## 15. Privacy

Member names are PII stored on-device. Included in encrypted backups (PRD-06).

---

## 16. Open questions / future

| ID | Item |
|----|------|
| OQ-H1 | Member avatars |
| OQ-H2 | Per-member budgets |
| OQ-H3 | Account balance field manual |
| OQ-H4 | Settle-up report |

---

## 17. QA matrix

| # | Test | Pass |
|---|------|------|
| 1 | Seed defaults | Present |
| 2 | Add/delete custom member | OK / Self blocked |
| 3 | Default account | Picker preselect |
| 4 | Member chart | Sums match |

---

## 18. Traceability

| Area | Path |
|------|------|
| Settings UI | `settings_screen.dart` |
| Models | `household_member.dart`, `account.dart` |
| Analytics | `member_spending_card.dart` |
| Seed | `database_helper.dart` |

---

## 19. Copy guidelines

- Use “Paid by” not “Owner” in expense UI.
- Use “Account” not “Wallet” unless type is Cash.
- Role examples: Self, Spouse, Parent, Other.

---

## 20. Summary

Members and accounts are the organizational spine of household finance in the app. Defaults remove setup friction; CRUD in Settings supports real families and multi-bank users without introducing multi-login complexity.

---

## Appendix A — Detailed service contracts (Household Members & Accounts)

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

This document is the feature-level source of truth for **Household Members & Accounts** until superseded by a dated revision in this folder.
