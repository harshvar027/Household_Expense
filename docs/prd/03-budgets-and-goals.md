# PRD-03 — Budgets & Goals

| Field | Value |
|-------|-------|
| **Product** | Household Expense |
| **Document ID** | PRD-03 |
| **Feature** | Monthly spending budget, category budgets, alerts, savings goals |
| **Status** | Implemented |
| **Owner** | Product / Engineering |
| **Last updated** | 2026-07-10 |
| **Related code** | `lib/screens/budget_screen.dart`, `lib/widgets/budget_progress_card.dart`, `category_budget_card.dart`, `goals_card.dart`, `lib/models/category_budget.dart`, `goal.dart`, `lib/screens/settings_screen.dart` (Goals tab) |

---

## 1. Purpose

Specify how users plan spending for a month, allocate limits per category, receive threshold alerts, and track longer-term savings goals. Budgets constrain behavior; goals motivate saving. Both read from the expense ledger (PRD-02).

---

## 2. Problem statement

Without budgets, expense tracking is retrospective only. Households need:

- A **monthly spending cap** with clear remaining balance.
- **Category caps** (e.g., Dining vs Groceries).
- **Early warnings** before overspend.
- **Goals** for investments/savings that can auto-track from categorized spend.

---

## 3. Goals

| ID | Goal |
|----|------|
| G1 | Set and edit a monthly total budget for the selected month. |
| G2 | Show income context (manual / imported / B/F) beside budget. |
| G3 | Per-category budgets unique per month+category. |
| G4 | Alert at 80% and 100% of monthly budget. |
| G5 | Category exceeded notifications/snackbars. |
| G6 | CRUD savings goals with optional linked category auto-progress. |
| G7 | Surface goals on Analytics and Settings → Goals. |

---

## 4. Non-goals

| ID | Non-goal |
|----|----------|
| NG1 | Envelope budgeting with forced remaining rollover accounting. |
| NG2 | Shared family budget negotiation workflows. |
| NG3 | Predictive ML budget recommendations. |
| NG4 | Debt payoff snowball planners. |

---

## 5. Personas

- **Planner** — sets budget on day 1 of month.
- **Category controller** — tight dining limit.
- **Saver** — goal for emergency fund / mutual funds.

---

## 6. User stories

1. As a user, I can set a monthly budget and see how much I have left after expenses.
2. As a user, I can assign category budgets and see progress bars.
3. As a user, I get warned when I cross 80% of my monthly budget.
4. As a user, I get alerted when I hit or exceed 100%.
5. As a user, I can create a goal with target amount and current progress.
6. As a user, linking a goal to Investment category updates progress when I spend in that category.
7. As a user, I can deactivate or delete goals I no longer need.

---

## 7. Functional requirements

### 7.1 Monthly budget

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-B01 | Store monthly budget amount keyed by `YYYY-MM`. | P0 |
| FR-B02 | Budget screen shows spend vs budget progress. | P0 |
| FR-B03 | Show income breakdown for context. | P1 |
| FR-B04 | Allow edit anytime in month; recalculate remaining immediately. | P0 |
| FR-B05 | Zero/unset budget shows empty/CTA state, not fake numbers. | P0 |

### 7.2 Category budgets

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-B10 | Create/update/delete category budget for selected month. | P0 |
| FR-B11 | UNIQUE constraint month+category. | P0 |
| FR-B12 | Progress = category spend (non-transfer) / limit. | P0 |
| FR-B13 | Editable from Budget screen and Analytics affordances. | P1 |

### 7.3 Alerts

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-B20 | Fire once per threshold per month for 80% monthly. | P0 |
| FR-B21 | Fire at 100% monthly. | P0 |
| FR-B22 | Category over-limit snack/banner. | P1 |
| FR-B23 | Persist “already alerted” flags so relaunch doesn’t spam. | P0 |

### 7.4 Goals

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-B30 | Goal fields: name, targetAmount, currentAmount, optional linkedCategory, isActive. | P0 |
| FR-B31 | Manual adjust currentAmount. | P0 |
| FR-B32 | If linkedCategory set, currentAmount can derive from investment/savings spend. | P1 |
| FR-B33 | Goals card on Analytics; management in Settings → Goals. | P0 |
| FR-B34 | Soft-delete or isActive=false hides from primary UI. | P1 |

---

## 8. User flows

### 8.1 Set monthly budget

```
Menu/Budget → Enter amount → Save
  → Progress card updates on Home/Budget/Analytics
```

### 8.2 Category limit

```
Budget → Add category budget → Pick category + limit
  → Card shows % used as expenses post
```

### 8.3 Goal with link

```
Settings → Goals → Add
  → Name, target, link Mutual Funds
  → As MF expenses post, progress moves
```

### 8.4 Threshold alert

```
Expense pushes spend to ≥80% of budget
  → Snack/dialog once
  → Further expenses don’t re-show 80% until next month
```

---

## 9. UI / UX requirements

1. Progress visuals: linear/circular consistent with neo-glass theme.
2. Over-budget state uses warning color (not only red text).
3. Currency formatting matches region.
4. Goals show % complete and remaining to target.
5. Confirm before deleting a goal with progress.
6. Budget screen should not feel like a second “settings dump”; one job: plan this month.

---

## 10. Data model

### 10.1 Monthly budget (prefs)

`budget_YYYY-MM` → numeric string/double.

### 10.2 `category_budgets`

| Column | Notes |
|--------|-------|
| id | PK |
| month | `YYYY-MM` |
| category | string |
| limitAmount | number |
| UNIQUE(month, category) | enforced |

### 10.3 `goals`

| Column | Notes |
|--------|-------|
| id | PK |
| name | |
| targetAmount | |
| currentAmount | |
| linkedCategory | nullable |
| isActive | bool |

### 10.4 Alert prefs

Keys including month token for 80/100 fired flags.

---

## 11. Business rules

| ID | Rule |
|----|------|
| BR-B1 | Spend for budget excludes transfers (PRD-02). |
| BR-B2 | Alerts are UX only; they do not block new expenses. |
| BR-B3 | Category budget independent of monthly total (can sum above or below). |
| BR-B4 | Goals are not financial accounts; they are progress trackers. |
| BR-B5 | Entitlement: budget features available during trial and Pro (PRD-07). |

---

## 12. Edge cases

| Case | Behavior |
|------|----------|
| Budget set to 0 | Treat as unset or 100% immediately — product should validate >0 |
| Negative remaining | Show overspend amount clearly |
| Category renamed historically | Budgets keyed by category string; orphaned budgets possible |
| Goal target < current | Show 100%+ complete |
| Month rollover | New month needs new budget entry; do not auto-copy unless future feature |

---

## 13. Acceptance criteria

- [ ] Set budget 20000; spend 5000 → shows 25% used / 15000 left.
- [ ] Category Dining 2000; spend 2500 → over state.
- [ ] Cross 80% → alert once; relaunch → no duplicate 80% alert.
- [ ] Hit 100% → alert.
- [ ] Create goal; update current; Analytics card reflects.
- [ ] Linked category updates progress after matching expense.

---

## 14. Dependencies

- PRD-02 Expenses & Income
- PRD-04 Analytics (display)
- PRD-08 Members (indirect via spend attribution)
- PRD-07 Entitlements

---

## 15. Privacy

Budget and goal names stay on-device. No cloud sync in v1.

---

## 16. Open questions / future

| ID | Item |
|----|------|
| OQ-B1 | Auto-carry unused budget to next month |
| OQ-B2 | Weekly micro-budgets |
| OQ-B3 | Push notifications for alerts (currently in-app) |
| OQ-B4 | Goal contributions as explicit transactions |

---

## 17. QA matrix

| # | Scenario | Pass criteria |
|---|----------|---------------|
| 1 | Budget CRUD | Value persists after kill |
| 2 | Category unique | Second insert same month+cat updates/rejects cleanly |
| 3 | Alert spam | Only one 80% per month |
| 4 | Goal link | MF expense increases goal current |
| 5 | Inactive goal | Hidden from Analytics card |

---

## 18. Traceability

| Area | Path |
|------|------|
| Budget UI | `lib/screens/budget_screen.dart` |
| Progress widgets | `lib/widgets/budget_progress_card.dart`, `category_budget_card.dart` |
| Goals UI | `lib/widgets/goals_card.dart`, Settings Goals tab |
| Models | `lib/models/category_budget.dart`, `goal.dart` |
| Persistence | `database_helper.dart` + SharedPreferences |

---

## 19. Metrics (product success)

- % users with budget set by day 7 of trial
- % users with ≥1 category budget
- % users with ≥1 active goal
- Alert dismiss → subsequent spend behavior (qualitative)

---

## 20. Summary

Budgets turn the ledger into a control system; goals turn savings categories into motivation. Alerts must be timely but not noisy. This PRD locks the rules for monthly and category limits and goal tracking across the Flutter clients.

---

## Appendix A — Detailed service contracts (Budgets & Goals)

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

This document is the feature-level source of truth for **Budgets & Goals** until superseded by a dated revision in this folder.
