# PRD-05 — Bank Statement Import

| Field | Value |
|-------|-------|
| **Product** | Household Expense |
| **Document ID** | PRD-05 |
| **Feature** | Multi-format bank statement import, preview, commit |
| **Status** | Implemented |
| **Owner** | Product / Engineering |
| **Last updated** | 2026-07-10 |
| **Related code** | `lib/screens/import_statement_screen.dart`, `import_preview_screen.dart`, `lib/services/statement_import_service.dart`, `statement_reader_service.dart`, `csv_reader_service.dart`, `excel_reader_service.dart`, `pdf_reader_service.dart`, `pdf_statement_parser.dart`, `bank_detector.dart`, `transaction_parser.dart` |

---

## 1. Purpose

Define end-to-end requirements for importing bank statements into the household ledger. Import is a major differentiator: users avoid typing dozens of rows by loading CSV, Excel, or PDF statements, reviewing a preview, then committing selected transactions.

---

## 2. Problem statement

Manual entry does not scale for active bank accounts. Users receive monthly statements in heterogeneous formats. The product must:

- Accept common file types.
- Detect banks/layouts where possible (India-focused profiles + generic fallback).
- Let users fix categories and drop duplicates before commit.
- Work on Android (SAF MethodChannel) and iOS (`file_selector`) without locking the session incorrectly.

---

## 3. Goals

| ID | Goal |
|----|------|
| G1 | Support CSV, XLS, XLSX, PDF (including password-protected PDFs). |
| G2 | Account + bank hint selection with auto-detect when possible. |
| G3 | Preview with select/deselect, category/item edit, duplicate flags. |
| G4 | Classify debit vs credit vs investment-like rows. |
| G5 | Commit to expenses/income + retain bank_transactions history. |
| G6 | Gate behind trial/Pro entitlement. |
| G7 | Parity UX on Android and iOS. |

---

## 4. Non-goals

| ID | Non-goal |
|----|----------|
| NG1 | Direct bank API / Account Aggregator live sync. |
| NG2 | Perfect parsing of every bank PDF worldwide. |
| NG3 | Storing original statement files long-term in app storage (parse then discard/cache briefly). |
| NG4 | SMS inbox reading in production (disabled). |

---

## 5. Personas

- **India salary account user** — HDFC/SBI/ICICI PDF/CSV monthly.
- **Generic international user** — CSV with Debit/Credit columns.
- **Careful reviewer** — unchecks ATM fees already entered manually.

---

## 6. User stories

1. As a user, I can pick a statement file from device storage.
2. As a user, I can enter a PDF password when required.
3. As a user, I can preview parsed rows before anything is saved.
4. As a user, I can deselect duplicates or unwanted rows.
5. As a user, I can fix category and description per row.
6. As a user, I can commit and see new expenses/income in the ledger.
7. As a user without entitlement, I see upgrade prompt instead of import.

---

## 7. Functional requirements

### 7.1 Entry & entitlement

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-I01 | Import entry from Menu; requires `AppFeature.importStatement` access. | P0 |
| FR-I02 | If not entitled, show upgrade prompt (PRD-07). | P0 |

### 7.2 File pick

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-I10 | Android: MethodChannel `com.householdexpense.app/file_picker` copies to cache. | P0 |
| FR-I11 | iOS/desktop: `file_selector` with statement UTIs/extensions. | P0 |
| FR-I12 | Wrap picker in `runWithNativeSheetGuard` to avoid auth lock. | P0 |
| FR-I13 | Supported extensions: csv, xls, xlsx, pdf. | P0 |

### 7.3 Parsing

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-I20 | CSV via csv package / dedicated reader. | P0 |
| FR-I21 | Excel via excel / spreadsheet_decoder / excel2003 as needed. | P0 |
| FR-I22 | PDF text extraction via Syncfusion; password prompt on failure. | P0 |
| FR-I23 | Bank detector suggests profile (Axis, HDFC, ICICI, SBI, BoB, PNB, AU, IndusInd, CBI, Generic). | P0 |
| FR-I24 | Header detection + layout scoring for ambiguous sheets. | P1 |
| FR-I25 | DR/CR semantics resolver for signed amounts. | P0 |
| FR-I26 | Non-India regions: prefer Generic debit/credit layout. | P0 |

### 7.4 Preview

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-I30 | Show date, description, amount, suggested type, category. | P0 |
| FR-I31 | Multi-select; default select non-duplicates. | P0 |
| FR-I32 | Flag likely duplicates against existing ledger. | P0 |
| FR-I33 | Inline edit category and item text. | P0 |
| FR-I34 | Summarize counts: selected debits/credits. | P1 |

### 7.5 Commit

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-I40 | Debits → expenses (investment categories when detected). | P0 |
| FR-I41 | Credits → income (unless user reclassified). | P0 |
| FR-I42 | Attach selected accountId / bank metadata. | P0 |
| FR-I43 | Write `bank_transactions` staging/history rows. | P1 |
| FR-I44 | Apply merchant rules for categories when matching. | P1 |
| FR-I45 | Show success summary; navigate back to ledger. | P0 |

---

## 8. User flows

### 8.1 Happy path CSV

```
Menu → Import Statement
  → Choose account + bank hint
  → Pick CSV
  → Preview → adjust → Import selected
  → Expenses/Income updated
```

### 8.2 Password PDF

```
Pick PDF → Password dialog
  → Parse → Preview → Commit
```

### 8.3 Partial import

```
Preview → Uncheck 5 duplicates → Commit rest
```

---

## 9. UI / UX requirements

1. Clear file type help text on import screen.
2. Progress indicator during parse (PDF can be slow).
3. Error messages actionable (“Wrong password”, “No transactions found”).
4. Preview must be usable on small screens (horizontal scroll or compact rows).
5. Never leave user unsure whether commit happened (snack + counts).

---

## 10. Data model

### 10.1 Parsed row (in-memory)

date, description, amount, direction (debit/credit), category suggestion, selected, duplicate flag, raw line ref.

### 10.2 `bank_transactions`

Stores imported row history for audit/debug and duplicate detection assistance.

### 10.3 Accounts

Import targets an `accounts` row (PRD-08); bankId optional hint.

---

## 11. Business rules

| ID | Rule |
|----|------|
| BR-I1 | Only selected rows commit. |
| BR-I2 | Duplicate detection is advisory; user may still import. |
| BR-I3 | Original file not required after successful parse; cache may be deleted. |
| BR-I4 | Sample CSVs under `lib/backup CSV/` are developer fixtures, not bundled assets. |
| BR-I5 | Entitlement required. |

---

## 12. Edge cases

| Case | Behavior |
|------|----------|
| Empty file | Error, no crash |
| Scanned image-only PDF | Fail gracefully (no OCR in v1) |
| Wrong bank profile | User can switch to Generic and re-parse if UI allows |
| Mixed credits/debits | Both types in one preview |
| Huge CSV (10k+ rows) | Warn or paginate; avoid UI jank |
| Permission denied | Explain Files/storage access |

---

## 13. Acceptance criteria

- [ ] Import sample Axis/HDFC-like CSV successfully on Android.
- [ ] Import same via Files on iOS Simulator/device.
- [ ] Password PDF success and failure paths work.
- [ ] Deselected rows do not appear in ledger.
- [ ] Duplicate flags appear for re-import of same file.
- [ ] Auth does not lock mid-picker.
- [ ] Without Pro/trial, import blocked with upgrade CTA.

---

## 14. Platform matrix

| Step | Android | iOS |
|------|---------|-----|
| Pick file | SAF MethodChannel | file_selector |
| PDF password | In-app dialog | In-app dialog |
| Share later | N/A | N/A |

---

## 15. Dependencies

- Syncfusion PDF, excel packages
- PRD-01 auth guard
- PRD-02 ledger writers
- PRD-07 entitlements
- PRD-08 accounts
- RegionConfig bank lists

---

## 16. Privacy & compliance

Statements contain PII and account numbers. Files should not be uploaded. Cache files should not be world-readable. Privacy policy must mention local parsing only.

---

## 17. Open questions / future

| ID | Item |
|----|------|
| OQ-I1 | OCR for scanned PDFs |
| OQ-I2 | Account Aggregator (India) |
| OQ-I3 | Auto-import from Watch folder |
| OQ-I4 | More international bank profiles |

---

## 18. QA fixtures

Use `lib/backup CSV/*.csv` and `savings/*.csv` as regression inputs. Maintain expected row counts in `test/statement_parser_test.dart`.

---

## 19. Traceability

| Area | Path |
|------|------|
| UI | `import_statement_screen.dart`, `import_preview_screen.dart` |
| Orchestration | `statement_import_service.dart` |
| Readers | `csv_reader_service.dart`, `excel_reader_service.dart`, `pdf_reader_service.dart` |
| Parse | `pdf_statement_parser.dart`, `transaction_parser.dart`, `header_detector.dart` |
| Bank | `bank_detector.dart`, `bank_profile.dart` |
| Semantics | `dr_cr_semantics_resolver.dart`, `statement_amount_inferrer.dart` |
| Types | `file_type_groups.dart`, `file_type_sniffer.dart` |
| Android native | `MainActivity.kt` file_picker channel |

---

## 20. Summary

Bank statement import converts heterogeneous bank exports into reviewed ledger entries with strong user control at preview time. Android and iOS share Dart parsing; only file picking differs. This PRD is the contract for import quality and entitlement gating.

---

## Appendix A — Detailed service contracts (Bank Statement Import)

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

This document is the feature-level source of truth for **Bank Statement Import** until superseded by a dated revision in this folder.
