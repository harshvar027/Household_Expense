# PRD-02 — Expenses & Income

| Field | Value |
|-------|-------|
| **Product** | Household Expense |
| **Document ID** | PRD-02 |
| **Feature** | Expense and income capture, history, filters, transfers, balance brought forward |
| **Status** | Implemented |
| **Owner** | Product / Engineering |
| **Last updated** | 2026-07-10 |
| **Related code** | `lib/screens/add_expense_screen.dart`, `lib/screens/tabs/expenses_tab.dart`, `lib/screens/tabs/home_tab.dart`, `lib/models/expense.dart`, `income.dart`, `lib/services/balance_service.dart`, `merchant_rule_service.dart` |

---

## 1. Purpose

Define how users record day-to-day money movement: spending, income, transfers, savings/investment categorization, monthly navigation, and history management. This is the core ledger of the product; other features (budgets, analytics, import) consume these records.

---

## 2. Problem statement

Households need a simple ledger that:

- Separates **spending** from **savings/investments** and **income**.
- Supports **who paid** (household member) and **which account**.
- Allows **transfers** without inflating spend totals.
- Works for both **manual entry** and **imported** bank rows.
- Remains understandable when browsing prior months.

---

## 3. Goals

| ID | Goal |
|----|------|
| G1 | Fast add/edit/delete for expenses with category, payment method, date, member, account, notes. |
| G2 | Manual income entry and imported income coexistence. |
| G3 | Mark transfers so they are excluded from spending analytics. |
| G4 | Month-scoped views with entitlement-aware history depth. |
| G5 | Balance brought forward (B/F) as system income for continuity. |
| G6 | Merchant learning when user corrects categories after import. |
| G7 | Clear separation of Savings & Investments in history UI. |

---

## 4. Non-goals

| ID | Non-goal |
|----|----------|
| NG1 | Double-entry accounting / chart of accounts. |
| NG2 | Multi-currency conversion engine. |
| NG3 | Live bank Open Banking APIs. |
| NG4 | SMS auto-capture in store builds (disabled; see feature flags). |
| NG5 | Shared real-time collaborative editing. |

---

## 5. Personas

- **Daily logger** — adds 1–5 expenses per day via FAB.
- **Importer** — bulk loads statement then corrects a few categories.
- **Reviewer** — uses Expenses tab filters to find a merchant or amount.

---

## 6. User stories

1. As a user, I can add an expense with amount, category, and date in under 30 seconds.
2. As a user, I can mark a transaction as a transfer so it does not count as spending.
3. As a user, I can log income (salary, refund) for the selected month.
4. As a user, I can filter expenses by category, payment method, and text search.
5. As a user, I can switch months to review past spending (within entitlement rules).
6. As a user, I can see Savings & Investments separately from lifestyle expenses.
7. As a user, when I change an imported merchant’s category, the app can remember that rule.
8. As a user, I can delete a single expense or clear the current month’s data intentionally.

---

## 7. Functional requirements

### 7.1 Expense CRUD

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-E01 | Add expense: item/title, amount (>0), category, payment method, date, optional member, account, notes. | P0 |
| FR-E02 | Edit any user-created or imported expense field allowed by UI. | P0 |
| FR-E03 | Delete expense with confirmation. | P0 |
| FR-E04 | Optional `isTransfer` flag; transfers excluded from spend totals and budget burn. | P0 |
| FR-E05 | Default categories seeded (groceries, utilities, Mutual Funds, Investment, etc.). | P0 |
| FR-E06 | Payment methods depend on region (e.g., India includes UPI). | P0 |

### 7.2 Income

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-E10 | Manual income with description, amount, date. | P0 |
| FR-E11 | Imported credits can create income rows. | P0 |
| FR-E12 | System **balance brought forward** income for month continuity; not user-deletable/editable. | P0 |
| FR-E13 | Income breakdown visible on budget/home summaries (manual / imported / B/F). | P1 |

### 7.3 History & filters

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-E20 | Expenses tab segments: Expenses / Income / Savings & Investments. | P0 |
| FR-E21 | Filter bar: category, payment method, search query. | P0 |
| FR-E22 | Month selector (~±2 years UI range; gated when trial lapsed without Pro). | P0 |
| FR-E23 | List items show amount, category, payment, member, transfer badge. | P0 |

### 7.4 Home integration

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-E30 | Home shows month summary cards driven by expense/income aggregates. | P0 |
| FR-E31 | FAB opens add expense on Home and Expenses tabs. | P0 |
| FR-E32 | Quick transaction dialog may offer accelerated entry paths. | P1 |

### 7.5 Merchant rules

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-E40 | When user changes category on a merchant-like item, optionally persist merchant→category rule. | P1 |
| FR-E41 | Future imports apply learned rules via `MerchantRuleService`. | P1 |

### 7.6 Destructive actions

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-E50 | Delete all expenses/income for current month with strong confirmation. | P1 |
| FR-E51 | Clear all data available from Menu with multi-step confirm (does not remove PIN). | P1 |

---

## 8. User flows

### 8.1 Add expense

```
FAB → Add Expense screen
  → Fill fields → Save
  → Return to list; Home totals refresh
```

### 8.2 Mark transfer

```
Add/Edit → Toggle Transfer
  → Save
  → Appears in list with badge; excluded from spend charts
```

### 8.3 Browse prior month

```
Month selector → Previous month
  → Lists and summaries reload for that month
```

### 8.4 Correct imported category

```
Expenses → Open imported row → Change category → Save
  → Merchant rule may update → Next import auto-categorizes
```

---

## 9. UI / UX requirements

1. Amounts use region currency formatting (`money_format.dart`).
2. Neo-glass cards for entries; clear destructive affordances (delete).
3. Empty states explain how to add first expense or import a statement.
4. Date picker respects regional date order (DMY vs MDY).
5. Keyboard: numeric for amount; avoid covering Save button (scroll/insets).
6. Accessibility: announce amount and category in list semantics where practical.

---

## 10. Data model

### 10.1 `expenses` table (conceptual)

| Field | Notes |
|-------|-------|
| id | PK |
| item / title | Merchant or description |
| amount | Numeric |
| category | String / FK-like to categories |
| paymentMethod | Region list |
| date | ISO / stored date |
| memberId | Optional FK household_members |
| accountId | Optional FK accounts |
| isTransfer | Bool |
| notes | Text; may include `recurring` marker |
| source | Manual vs import metadata as applicable |

### 10.2 `income` table

| Field | Notes |
|-------|-------|
| id | PK |
| description | |
| amount | |
| date | |
| source type | Manual / imported / system B/F |

### 10.3 `categories` / `merchant_rules`

Seeded defaults; rules map normalized merchant keys to categories.

### 10.4 Prefs

Monthly budget amount may live in prefs `budget_YYYY-MM` (see PRD-03) while line items stay in SQL.

---

## 11. Business rules

| ID | Rule |
|----|------|
| BR-E1 | Transfers do not count toward monthly spend or category budget consumption. |
| BR-E2 | Categories named for investments (e.g., Mutual Funds, Investment) roll into Savings & Investments views. |
| BR-E3 | B/F income is generated/maintained by `BalanceService` logic; users cannot treat it as normal editable income. |
| BR-E4 | Amounts stored as device-local currency; no FX conversion. |
| BR-E5 | SMS quick entry remains disabled (`AppFeatureFlags.smsQuickEntryEnabled = false`). |

---

## 12. Calculations

### 12.1 Month spend

```
spend = sum(expenses where month matches
            AND NOT isTransfer
            AND category NOT IN savings/investment set)
```

Exact category sets are defined in code (`category_utils` / defaults).

### 12.2 Net / remaining budget

```
remaining = monthlyBudget - spend
```

Income is shown separately; budget is a spending cap, not a full P&L unless UI states otherwise.

---

## 13. Edge cases

| Case | Behavior |
|------|----------|
| Amount 0 or negative | Reject on validate |
| Future date | Allowed unless product later restricts |
| Delete category in use | Keep historical category string; manage via category list rules |
| Huge import month | List virtualization / performance acceptable for thousands of rows target |
| Entitlement lapsed | Month navigation and add may be blocked by paywall (PRD-07) |
| Concurrent edit | Single-user local DB; last write wins |

---

## 14. Acceptance criteria

- [ ] Add expense appears immediately in Expenses list and Home totals.
- [ ] Edit updates aggregates without duplicate rows.
- [ ] Transfer excluded from Analytics spend pie.
- [ ] Manual income appears under Income segment.
- [ ] B/F row visible and not deletable from normal UI.
- [ ] Filters narrow list correctly in combination.
- [ ] Savings categories appear under Savings & Investments segment.
- [ ] Delete month data removes only selected month’s ledger rows.

---

## 15. Platform notes

| Topic | Notes |
|-------|-------|
| Entry | Same Flutter UI on Android/iOS |
| Soft input | Android `adjustResize`; iOS safe area |
| Localization | English UI; region drives formats only |

---

## 16. Dependencies

- PRD-01 Auth (must be unlocked)
- PRD-03 Budgets (consumes spend)
- PRD-04 Analytics (aggregations)
- PRD-05 Import (creates rows)
- PRD-08 Members & accounts (foreign keys)
- PRD-09 Recurring (auto-generated expenses with notes)

---

## 17. Privacy

Expense descriptions may contain sensitive merchant names. Data never leaves device except via user-initiated export/share/backup/email feedback.

---

## 18. Open questions / future

| ID | Item |
|----|------|
| OQ-E1 | Receipt photo attachments |
| OQ-E2 | Split expense across members |
| OQ-E3 | Tags beyond category |
| OQ-E4 | Recurring templates from expense detail |

---

## 19. QA matrix

| # | Test | Expected |
|---|------|----------|
| 1 | Add grocery 500 UPI | Listed; Home spend +500 |
| 2 | Mark as transfer | Spend unchanged |
| 3 | Add income 50000 | Income segment shows it |
| 4 | Filter category Food | Only food rows |
| 5 | Switch to prior month | Different dataset |
| 6 | Investment category | Under Savings segment |

---

## 20. Traceability

| Area | Files |
|------|-------|
| Add/Edit UI | `lib/screens/add_expense_screen.dart` |
| Expenses tab | `lib/screens/tabs/expenses_tab.dart` |
| Home | `lib/screens/tabs/home_tab.dart` |
| Models | `lib/models/expense.dart`, `income.dart` |
| Balance B/F | `lib/services/balance_service.dart` |
| Filters | `lib/widgets/expense_filter_bar.dart`, `lib/utils/expense_filter_utils.dart` |
| Categories | `lib/constants/default_categories.dart`, `lib/utils/category_utils.dart` |
| Merchant learning | `lib/services/merchant_rule_service.dart` |
| DB | `lib/database/database_helper.dart` |

---

## 21. Summary

Expenses & Income form the system of record for Household Expense. Manual entry, imports, transfers, B/F, and savings separation must stay consistent so budgets and analytics remain trustworthy. This PRD defines the ledger behavior expected on both Android and iOS.
