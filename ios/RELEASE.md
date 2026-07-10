# iOS Release Checklist — Household Expense

Parity target: Android package `com.householdexpense.app` / same Flutter UI in `lib/`.

## Identity

| Item | Value |
|------|-------|
| Bundle ID | `com.householdexpense.app` |
| Display name | Household Expense |
| Min iOS | 13.0 |
| Orientation | Portrait (matches Android) |

## Before App Store upload

1. **Signing** — Open `ios/Runner.xcworkspace` in Xcode → Runner target → Signing & Capabilities → select your Team.
2. **AdMob** — Replace test `GADApplicationIdentifier` in `ios/Runner/Info.plist` and `iosBannerId` / `iosAppId` in `lib/config/ad_config.dart` with production iOS AdMob IDs.
3. **IAP** — Create App Store Connect product id `household_expense_yearly_1800` (or update `lib/config/subscription_config.dart` to match).
4. **Privacy** — Complete App Privacy questionnaire (on-device encrypted storage, ads, purchase).
5. **Icons** — Confirm AppIcon set matches Android branding (currently generated from Android launcher).

## Build & run (Simulator)

```bash
export PATH="/Users/harshuuu/Downloads/FOLDERS/flutter/bin:$PATH"
cd /Users/harshuuu/household_expense
flutter pub get
cd ios && pod install && cd ..
open -a Simulator
flutter run -d ios
```

## Feature parity notes

- Shared Dart UI/features already run on iOS (auth, expenses, budgets, analytics, statement import, export, ads, IAP, Face ID).
- Bank statement pick uses `file_selector` on iOS (Android uses a MethodChannel SAF picker).
- SMS quick-entry is Android-only and disabled via feature flag — not ported.
