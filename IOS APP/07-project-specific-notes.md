# Project-Specific Notes — household_expense

Items unique to **this** codebase for iOS (parity with Android).

---

## Configured (matches Android product)

| Item | Value |
|------|-------|
| Display name | `Household Expense` |
| Bundle ID | `com.householdexpense.app` |
| Min iOS | 13.0 |
| Orientation | Portrait |
| AdMob App ID (test) | `ca-app-pub-3940256099942544~1458002511` in `Info.plist` |
| Face ID | `NSFaceIDUsageDescription` |
| ATT | `NSUserTrackingUsageDescription` |
| Export compliance | `ITSAppUsesNonExemptEncryption = false` |

---

## Shared features (same UI as Android)

All screens/services in `lib/` run on iOS once the app builds:

- Auth + Face ID / Touch ID
- Encrypted SQLCipher database
- Expenses, income, budgets, goals, members, analytics
- Bank statement import (CSV / Excel / PDF) via `file_selector`
- Export / share + encrypted backup
- AdMob banners (trial) + yearly IAP unlock
- Settings, help, feedback

### File pick difference

| Platform | Mechanism |
|----------|-----------|
| Android | MethodChannel `com.householdexpense.app/file_picker` (SAF) |
| iOS | `file_selector` plugin (Files app) |

No iOS MethodChannel is required for import.

### Not ported

SMS quick-entry is Android-only and **disabled** (`smsQuickEntryEnabled = false`).

---

## Recommended test plan (Simulator)

1. Launch on **iPhone 17 Pro**
2. Register / login, enable biometrics if prompted
3. Add expense / income; open Budget + Analytics
4. Import a sample from `lib/backup CSV/` via Files
5. Export PDF / share; backup / restore
6. Confirm trial ad ribbon; open Subscription screen
7. Kill app and relaunch (DB persistence)

---

## Command cheat sheet

```bash
export PATH="/Users/harshuuu/Downloads/FOLDERS/flutter/bin:$PATH"
cd /Users/harshuuu/household_expense
flutter clean
flutter pub get
cd ios && pod install && cd ..
open -a Simulator
flutter run -d "iPhone 17 Pro"

# Reset app data
xcrun simctl uninstall booted com.householdexpense.app

open ios/Runner.xcworkspace
```

Before App Store: replace AdMob test IDs and create IAP product `household_expense_yearly_1800` (see `ios/RELEASE.md`).
