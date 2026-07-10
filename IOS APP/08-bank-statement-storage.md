# Bank Statement File Storage

Where CSV / bank statement files live in this project and at runtime.

---

## Summary

| Location | Persists? | Used by app? |
|----------|-----------|--------------|
| `lib/backup CSV/*.csv` | Yes (in repo folder) | **No** — manual developer copies only |
| Android app cache | Temporary | Yes — during import only |
| iOS file picker | In memory only | Yes — during import only |
| SQLite database | Yes (parsed rows) | Yes — expenses/income after import |

**The app does not permanently save the original CSV file** after import. It parses transactions and stores them in the local SQLite database as expenses and income entries.

---

## 1. Project directory (your Mac)

These files exist in the source tree as **manual backups** (not wired into the app):

```
lib/backup CSV/
├── Trans_202604.csv
├── Trans_202605.csv
└── trans_202606.csv
```

- They are **not** read automatically by the app.
- They are **not** copied to Android or iOS builds as assets.
- Safe to move out of `lib/` if you prefer (e.g. `docs/sample-statements/`) — `lib/` is normally for Dart code only.

---

## 2. Android runtime

When you pick a CSV on Android, `MainActivity.kt` copies the file **temporarily** to app cache:

```
/data/data/com.householdexpense.app/cache/csv_import_<timestamp>.csv
```

Relevant code: `android/app/src/main/kotlin/.../MainActivity.kt` lines 99–107.

- Flutter reads this path once, then parses content.
- Android may **delete cache files** when storage is low or app is cleared.
- **Not** the same as saving to Downloads or project folder.

---

## 3. iOS runtime

On iOS, `CsvImportService` uses `file_selector` (`openFile`):

- User picks a file from Files app / iCloud / On My iPhone.
- Content is read into **memory** as a string.
- **No copy** is written to the app documents directory.
- Original file stays wherever the user stored it (Files, email attachment, etc.).

---

## 4. After import — database only

`ImportService` writes selected rows to:

- `expenses` table (debits)
- `income` table (credits)

The `bank_transactions` table exists in schema but import flow primarily uses in-memory `BankTransaction` objects during preview; **source CSV path is not stored** in the database.

Database file location at runtime:

| Platform | Typical path |
|----------|----------------|
| iOS Simulator | App sandbox `Documents/` or Library |
| Android | `/data/data/com.householdexpense.app/databases/` |

---

## Recommendations

1. **Keep personal CSVs outside `lib/`** — use `backup CSV/` at project root or outside the repo.
2. **Add to `.gitignore`** if statements contain real bank data:
   ```
   lib/backup CSV/
   **/*.csv
   ```
3. **To persist imported CSV files in-app** (future feature): save to `path_provider` `getApplicationDocumentsDirectory()` with filename + import date.

---

## Quick verification commands

From project root:

```bash
find . -name "*.csv" -not -path "./.dart_tool/*" -not -path "./build/*"
```

List Android cache path (device connected):

```bash
adb shell run-as com.householdexpense.app ls cache/
```
