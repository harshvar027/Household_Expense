# PRD-04 — Analytics & Insights

| Field | Value |
|-------|-------|
| **Product** | Household Expense |
| **Document ID** | PRD-04 |
| **Feature** | Charts, statistics, member spending, rule-based insights |
| **Status** | Implemented |
| **Owner** | Product / Engineering |
| **Last updated** | 2026-07-10 |
| **Related code** | `lib/screens/tabs/analytics_tab.dart`, `lib/widgets/expense_pie_chart.dart`, `monthly_trend_chart.dart`, `insights_card.dart`, `member_spending_card.dart`, `lib/services/insights_service.dart`, `lib/theme/chart_styles.dart` |

---

## 1. Purpose

Define the analytics experience: how users understand where money went, how trends change month-over-month, how members compare, and what automated insights appear. Analytics is read-mostly over PRD-02 data, with light write paths for category budgets/goals.

---

## 2. Problem statement

Raw transaction lists do not answer:

- What categories dominate this month?
- Is spending rising vs last month?
- Who in the household is spending?
- Which merchants or “subscriptions” stand out?

Users need visual and textual insight without leaving the app or exporting to spreadsheets.

---

## 3. Goals

| ID | Goal |
|----|------|
| G1 | Category pie chart for selected month spend. |
| G2 | Monthly trend / bar visualizations. |
| G3 | Quick stats: top category, largest expense, txn count, % budget used. |
| G4 | Drill-down from category slice to expense list sheet. |
| G5 | Member spending breakdown card. |
| G6 | Local heuristic insights (MoM change, spikes, merchants, budget status). |
| G7 | Show goals progress on Analytics. |

---

## 4. Non-goals

| ID | Non-goal |
|----|----------|
| NG1 | Cloud ML / personalized AI coach. |
| NG2 | Tax filing reports. |
| NG3 | Real-time multi-user dashboards. |
| NG4 | Custom chart builder / SQL explorer. |

---

## 5. Personas

- **Visualizer** — opens Analytics weekly.
- **Investigator** — taps pie slice to find a surprise merchant.
- **Household lead** — checks member spending card.

---

## 6. User stories

1. As a user, I can see a pie of categories for the current month.
2. As a user, I can tap a category to list its expenses.
3. As a user, I can see whether this month is higher or lower than last month.
4. As a user, I can view quick stats without reading every row.
5. As a user, I can compare spending by household member.
6. As a user, I can read short insight cards generated on-device.
7. As a user, I can see goal progress near analytics content.

---

## 7. Functional requirements

### 7.1 Charts

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-N01 | Pie chart of non-transfer spend by category for selected month. | P0 |
| FR-N02 | Legend readable on small phones; truncate long labels. | P0 |
| FR-N03 | Monthly trend chart across recent months. | P0 |
| FR-N04 | Empty state when no expenses. | P0 |
| FR-N05 | Chart colors from `neo_palette` / `chart_styles` for consistency. | P1 |

### 7.2 Interaction

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-N10 | Tap category → `category_expenses_sheet` with filtered list. | P0 |
| FR-N11 | Sheet allows navigation to edit expense when supported. | P1 |
| FR-N12 | Month selector shared with rest of app. | P0 |

### 7.3 Quick statistics

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-N20 | Top category by spend. | P0 |
| FR-N21 | Largest single expense. | P0 |
| FR-N22 | Transaction count. | P0 |
| FR-N23 | % of monthly budget used (if budget set). | P0 |

### 7.4 Member spending

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-N30 | Aggregate spend by `memberId` for month. | P0 |
| FR-N31 | Unassigned member bucket labeled clearly. | P1 |

### 7.5 Insights engine

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-N40 | MoM spend % change insight. | P0 |
| FR-N41 | Category spike vs prior month. | P1 |
| FR-N42 | Top merchants list insight. | P1 |
| FR-N43 | Recurring/subscription-like detection heuristic. | P2 |
| FR-N44 | Budget status insight (under/over). | P0 |
| FR-N45 | All insights computed locally in `InsightsService`. | P0 |

### 7.6 Goals on Analytics

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-N50 | Display active goals card. | P0 |
| FR-N51 | Allow light edit affordances consistent with PRD-03. | P1 |

---

## 8. User flows

### 8.1 Explore category

```
Analytics → Pie → Tap Food
  → Sheet lists Food expenses
  → Optional edit → totals refresh
```

### 8.2 Read insights

```
Open Analytics / Home insights
  → Cards render from InsightsService
  → User adjusts behavior offline
```

### 8.3 Member compare

```
Analytics → Member card
  → See Self vs Spouse amounts
```

---

## 9. UI / UX requirements

1. Analytics tab is scrollable; charts must not overflow horizontally on narrow devices.
2. Prefer one primary chart above the fold; secondary charts below.
3. Insight cards: short title + one sentence; avoid walls of text.
4. Loading: show placeholders if DB read is slow (rare on-device).
5. Portrait-only (matches app orientation lock).
6. Home may reuse a subset of analytics widgets; keep styling identical.

---

## 10. Data & computation

### 10.1 Inputs

- Expenses (filtered by month, exclude transfers as required)
- Income (for context if shown)
- Budgets & category budgets
- Members
- Goals

### 10.2 Aggregations

```
byCategory[cat] += amount
byMember[memberId] += amount
momDelta = (thisMonth - lastMonth) / lastMonth
```

### 10.3 Performance

Target: <100ms aggregate for 2k rows on mid-range phones; if slower, consider indexed month queries (engineering).

---

## 11. Business rules

| ID | Rule |
|----|------|
| BR-N1 | Transfers excluded from spend charts. |
| BR-N2 | Savings/investment categories may be excluded from “lifestyle” pie or shown separately — follow `category_utils` conventions consistently with Expenses tab. |
| BR-N3 | Insights are advisory, not financial advice disclaimer in Help. |
| BR-N4 | No network calls for insights. |

---

## 12. Edge cases

| Case | Behavior |
|------|----------|
| One category 100% | Pie still renders; legend OK |
| No budget | Hide % budget or show “Set budget” CTA |
| New user month 1 | MoM insight suppressed or “not enough history” |
| Null member | Group as Unassigned |
| Huge label | Ellipsis |

---

## 13. Acceptance criteria

- [ ] Pie matches sum of category spends in list.
- [ ] Tap slice opens correct filtered sheet.
- [ ] Trend includes multiple months with data.
- [ ] Quick stats match manual calculation on sample dataset.
- [ ] Member card sums equal total attributed spend.
- [ ] Insights appear without internet.
- [ ] Goals card shows active goals only.

---

## 14. Dependencies

- PRD-02 ledger
- PRD-03 budgets/goals
- PRD-08 members
- `fl_chart` package
- Theme tokens

---

## 15. Privacy

Analytics never uploads transaction graphs. Screenshots are user responsibility.

---

## 16. Open questions / future

| ID | Item |
|----|------|
| OQ-N1 | Export analytics PNG |
| OQ-N2 | Compare year-over-year |
| OQ-N3 | Cashflow waterfall chart |
| OQ-N4 | Optional on-device LLM summaries |

---

## 17. QA matrix

| # | Fixture | Check |
|---|---------|-------|
| 1 | 3 categories | Pie angles proportional |
| 2 | Transfers present | Not in pie |
| 3 | 2 members | Card split correct |
| 4 | Budget 10k spend 9k | ~90% stat |
| 5 | Offline airplane | Insights still show |

---

## 18. Traceability

| Area | Path |
|------|------|
| Tab | `lib/screens/tabs/analytics_tab.dart` |
| Charts | `expense_pie_chart.dart`, `monthly_trend_chart.dart`, `monthly_bar_chart.dart` |
| Stats | `quick_statistics_card.dart` |
| Insights | `insights_card.dart`, `insights_service.dart` |
| Members | `member_spending_card.dart` |
| Drill-down | `category_expenses_sheet.dart` |
| Styles | `lib/theme/chart_styles.dart`, `neo_palette.dart` |

---

## 19. Success metrics

- Analytics tab open rate per WAUs
- Drill-down rate from pie
- Correlation: insight view → budget set within 24h

---

## 20. Summary

Analytics translates the encrypted ledger into visual and heuristic understanding—fully on-device, entitlement-aware, and consistent with budget and member models. This PRD is the contract for the Analytics tab and shared insight widgets.

---

## Appendix A — Detailed service contracts (Analytics & Insights)

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

This document is the feature-level source of truth for **Analytics & Insights** until superseded by a dated revision in this folder.
