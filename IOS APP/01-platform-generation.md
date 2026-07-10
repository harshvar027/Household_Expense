# Phase 1 — Platform Generation (`ios/` directory)

## Current state of *your* project

Your repo **already contains** a valid `ios/` folder:

```
household_expense/
├── lib/                 ← your Dart code (untouched)
├── android/             ← your Android config (untouched)
├── ios/                 ← already present
│   ├── Runner/
│   ├── Runner.xcodeproj/
│   ├── Runner.xcworkspace/
│   └── Flutter/
└── pubspec.yaml
```

You do **not** need to delete or recreate `ios/` unless it is corrupted or you intentionally want a fresh template.

---

## When to use `flutter create` (safe injection)

Flutter can add or refresh platform folders **without touching** `lib/` or `android/` if you use the right flags.

### Option A — You already have `ios/` (recommended for you)

**Skip regeneration.** Only refresh iOS metadata if Flutter asks you to after an upgrade:

```bash
cd /Users/harshuuu/household_expense
flutter create . --platforms=ios
```

What this does:

- Updates `ios/` scaffolding to match your Flutter SDK version
- Does **not** overwrite `lib/`
- Does **not** modify `android/` (because `--platforms=ios` limits scope)
- Preserves your app name from `pubspec.yaml`

### Option B — `ios/` folder is missing or completely broken

If you ever need to inject `ios/` from scratch:

```bash
cd /Users/harshuuu/household_expense
flutter create . --platforms=ios --org com.householdexpense --project-name household_expense
```

| Flag | Purpose |
|------|---------|
| `.` | Target the **current** directory (not a new folder) |
| `--platforms=ios` | Only create/update `ios/` — leaves `lib/` and `android/` alone |
| `--org com.householdexpense` | Sets bundle ID prefix → `com.householdexpense.app` |
| `--project-name household_expense` | Must match `name:` in `pubspec.yaml` |

### Option C — Nuclear reset of `ios/` only (last resort)

Only if `ios/` is unrecoverable. **Back up first.**

```bash
cd /Users/harshuuu/household_expense
mv ios ios_backup_$(date +%Y%m%d)
flutter create . --platforms=ios --org com.householdexpense --project-name household_expense
```

Then re-apply any custom `Info.plist` keys (see [07-project-specific-notes.md](./07-project-specific-notes.md)).

---

## Verify generation succeeded

```bash
cd /Users/harshuuu/household_expense
ls -la ios/
ls ios/Runner.xcworkspace
flutter doctor
```

Expected:

- `ios/Runner/Info.plist` exists
- `ios/Runner.xcodeproj` exists
- `flutter doctor` shows Xcode (may still warn about CocoaPods until Phase 3)

---

## What Flutter will NOT change

| Path | Safe? |
|------|-------|
| `lib/**` | Yes — never modified by `flutter create .` |
| `android/**` | Yes — when using `--platforms=ios` only |
| `pubspec.yaml` | Not overwritten (may suggest dependency updates separately) |
| Your SQLite data / runtime DB | Unaffected (lives in app sandbox at runtime) |

---

## Next step

→ [02-macos-prerequisites.md](./02-macos-prerequisites.md)
