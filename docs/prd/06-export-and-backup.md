# PRD-06 — Export & Encrypted Backup

| Field | Value |
|-------|-------|
| **Product** | Household Expense |
| **Document ID** | PRD-06 |
| **Feature** | PDF/CSV export, encrypted JSON backup & restore |
| **Status** | Implemented |
| **Owner** | Product / Engineering |
| **Last updated** | 2026-07-10 |
| **Related code** | `lib/services/export_service.dart`, `pdf_service.dart`, `backup_crypto_service.dart`, `lib/utils/backup_ui.dart`, Menu handlers in `lib/main.dart`, Settings Data tab |

---

## 1. Purpose

Specify how users take data **out** of the app for sharing, printing, archival, and disaster recovery—without operating a cloud sync service. Exports are user-initiated via the system share sheet. Backups are encrypted so shared files are not plaintext ledgers.

---

## 2. Problem statement

On-device apps fail if the phone is lost or reset. Users also need monthly PDF reports for family discussion and CSV for spreadsheets. Requirements:

- Human-readable **PDF** monthly report.
- Machine-readable **CSV** of expenses.
- **Encrypted backup** that can restore the database and related prefs.
- Restore that does **not** overwrite the user’s PIN hashes casually.
- Entitlement gating consistent with Pro/trial.

---

## 3. Goals

| ID | Goal |
|----|------|
| G1 | Generate monthly PDF with income, budget, expenses, investments, categories. |
| G2 | Export expenses CSV with stable columns. |
| G3 | Create AES-256-GCM encrypted JSON backup envelope. |
| G4 | Restore from backup with clear destructive warning. |
| G5 | Use share sheet on mobile; guard auth during share. |
| G6 | Gate features via entitlement flags (`exportPdf`, `exportCsv`, `backup`, `restore`). |

---

## 4. Non-goals

| ID | Non-goal |
|----|----------|
| NG1 | Automatic cloud backup to vendor servers. |
| NG2 | Continuous sync between two phones. |
| NG3 | Excel `.xlsx` export (CSV sufficient in v1). |
| NG4 | Emailing statements without user share UI. |

---

## 5. Personas

- **Archivist** — monthly backup to Google Drive / Files.
- **Reporter** — PDF for household meeting.
- **Analyst** — CSV into Google Sheets.
- **Recovering user** — new phone + backup file.

---

## 6. User stories

1. As a user, I can preview/share a PDF report for the selected month.
2. As a user, I can export CSV of expenses and open it in Sheets.
3. As a user, I can create an encrypted backup and save it to Drive.
4. As a user, I can restore a backup and see my expenses return.
5. As a user, I am warned that restore replaces current data.
6. As a user without entitlement, I am prompted to upgrade.

---

## 7. Functional requirements

### 7.1 PDF export

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-X01 | PDF includes month label, income split, budget, expense tables, investment section, category summary. | P0 |
| FR-X02 | Support preview/print via `printing` package. | P0 |
| FR-X03 | Share PDF file via share sheet. | P0 |
| FR-X04 | Respect currency formatting. | P0 |

### 7.2 CSV export

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-X10 | Columns: date, item, category, amount, payment, member, transfer, notes (as implemented). | P0 |
| FR-X11 | UTF-8; openable in Excel/Sheets. | P0 |
| FR-X12 | Scope: expenses for selected month or all — document actual behavior in UI copy. | P0 |

### 7.3 Encrypted backup

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-X20 | Envelope schema id: `household_expense_backup_envelope_v1`. | P0 |
| FR-X21 | Payload encrypted AES-256-GCM; key in secure storage `backup_aes_gcm_key_v1`. | P0 |
| FR-X22 | Include DB dump + monthly budgets + profile fields needed to rehydrate. | P0 |
| FR-X23 | Exclude PIN/password hashes from backup payload. | P0 |
| FR-X24 | Share encrypted file via share sheet. | P0 |

### 7.4 Restore

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-X30 | Pick backup file; decrypt with on-device key (or fail clearly if key mismatch). | P0 |
| FR-X31 | Confirm destructive replace. | P0 |
| FR-X32 | After restore, ledger matches backup; user still unlocks with existing PIN. | P0 |
| FR-X33 | Invalid file → non-destructive error. | P0 |

### 7.5 UX chrome

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-X40 | Entry points: Menu + Settings → Data. | P0 |
| FR-X41 | `backup_ui.dart` helpers for consistent dialogs. | P1 |
| FR-X42 | Native sheet guard during share/pick. | P0 |

---

## 8. User flows

### 8.1 PDF share

```
Menu → Export PDF → Generate
  → Preview/Share → Drive/WhatsApp/Files
```

### 8.2 Backup

```
Settings → Data → Backup
  → Encrypt → Share file
  → User stores off-device
```

### 8.3 Restore on same device

```
Settings → Data → Restore
  → Pick file → Confirm wipe → Decrypt → Reload UI
```

### 8.4 New device limitation

```
New install → new backup key
  → Old backup may not decrypt
  → Product should document: restore best on same secure-storage identity OR future passphrase-wrapped backups
```

*(Document current key model honestly in Help; future may add user passphrase.)*

---

## 9. UI / UX requirements

1. Destructive restore: red confirm, type-to-confirm optional.
2. Progress indicators for large DB export.
3. Success toasts with filename hints.
4. Help text: “Keep backups private; they contain your finances.”

---

## 10. Data & crypto

### 10.1 Envelope (logical)

```
{
  "schema": "household_expense_backup_envelope_v1",
  "nonce": "...",
  "ciphertext": "...",
  "meta": { "createdAt": "...", "appVersion": "..." }
}
```

### 10.2 Algorithms

- AES-256-GCM via `cryptography` package / `BackupCryptoService`.

### 10.3 Threat model

- Protects backups at rest in Drive from casual inspection.
- Does not protect against attacker with device unlock + keychain access.
- Not a substitute for full-disk encryption.

---

## 11. Business rules

| ID | Rule |
|----|------|
| BR-X1 | Entitlement required for export/backup/restore features. |
| BR-X2 | PIN remains local; backup restore must not silently set a new PIN. |
| BR-X3 | Share is always user-initiated. |
| BR-X4 | Android/iOS both use temp files + `share_plus`. |

---

## 12. Edge cases

| Case | Behavior |
|------|----------|
| Empty DB PDF | Still generates shell report |
| Backup decrypt fail | Error; DB untouched |
| User cancels share | Temp file cleaned when possible |
| Low disk | Fail gracefully |
| Concurrent write during backup | Prefer consistent snapshot; document best-effort |

---

## 13. Acceptance criteria

- [ ] PDF opens and shows month expenses matching UI.
- [ ] CSV imports cleanly into Sheets.
- [ ] Backup file is not valid plaintext JSON of expenses.
- [ ] Restore brings back expenses after intentional delete (same device/key).
- [ ] Cancel restore leaves data intact.
- [ ] Locked entitlement blocks export with upgrade CTA.

---

## 14. Dependencies

- `pdf`, `printing`, `share_plus`, `path_provider`, `file_selector`, `cryptography`
- PRD-01 auth guard
- PRD-02/03 data
- PRD-07 entitlements

---

## 15. Privacy

Exports may leave the device. UI must warn. Privacy policy covers user-controlled sharing.

---

## 16. Open questions / future

| ID | Item |
|----|------|
| OQ-X1 | User-chosen backup passphrase (portable across devices) |
| OQ-X2 | Scheduled reminder to backup |
| OQ-X3 | Incremental backups |
| OQ-X4 | Encrypted iCloud/Drive specific integrations |

---

## 17. QA matrix

| # | Test | Result |
|---|------|--------|
| 1 | PDF share | File received |
| 2 | CSV columns | Stable header |
| 3 | Backup roundtrip | Counts match |
| 4 | Bad file restore | No wipe |
| 5 | Airplane mode | All local ops work |

---

## 18. Traceability

| Area | Path |
|------|------|
| Export | `export_service.dart` |
| PDF layout | `pdf_service.dart` |
| Crypto | `backup_crypto_service.dart` |
| UI helpers | `backup_ui.dart` |
| Entry | `menu_tab.dart`, `settings_screen.dart`, `main.dart` |

---

## 19. Support playbook

- “I lost my phone” → need backup file + understand key limitation.
- “PDF missing rows” → verify month selector and filters.
- “CSV garb characters” → open as UTF-8.

---

## 20. Summary

Export and backup give users portability and recovery without a backend. PDF/CSV serve communication; encrypted envelopes serve archival. Entitlement and auth-guard rules keep the feature aligned with the rest of the product.

---

## Appendix A — Detailed service contracts (Export & Encrypted Backup)

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

This document is the feature-level source of truth for **Export & Encrypted Backup** until superseded by a dated revision in this folder.
