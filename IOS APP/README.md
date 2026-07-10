# Household Expense — iOS Setup Roadmap

Run the **same Flutter app** (features + UI from `lib/`) as a native iOS build. Android and iOS share one codebase; `ios/` is the native shell.

**Machine snapshot:**

| Item | Status |
|------|--------|
| macOS | 26.5.1 (Apple Silicon) |
| Flutter | `/Users/harshuuu/Downloads/FOLDERS/flutter` (3.44.4) |
| Xcode | 26.6 |
| Bundle ID | `com.householdexpense.app` (matches Android) |
| CocoaPods | Required (`ios/Podfile` present; some plugins need pods) |
| Simulator build | Verified on iPhone 17 Pro |

---

## Quick start

From project root (`/Users/harshuuu/household_expense`):

```bash
export PATH="/Users/harshuuu/Downloads/FOLDERS/flutter/bin:$PATH"
cd /Users/harshuuu/household_expense
flutter pub get
cd ios && pod install && cd ..
open -a Simulator
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null || true
flutter run -d "iPhone 17 Pro"
```

Open Xcode when needed:

```bash
open ios/Runner.xcworkspace
```

---

## What was upgraded for Android parity

| Area | iOS status |
|------|------------|
| Bundle ID | `com.householdexpense.app` |
| Portrait lock | Matches Android |
| AdMob | Test App ID + full SKAdNetwork list in `Info.plist` |
| Face ID | `NSFaceIDUsageDescription` |
| ATT | `NSUserTrackingUsageDescription` (for trial ads) |
| Statement import | `file_selector` (CSV / XLS / XLSX / PDF) |
| IAP / ads / SQLCipher / biometrics | Same Dart services as Android |
| App icons | Generated from Android launcher |
| SMS quick-entry | Not on iOS (disabled on Android too) |

See also: [ios/RELEASE.md](../ios/RELEASE.md)

---

## Docs in this folder

| Doc | Purpose |
|-----|---------|
| [01-platform-generation.md](./01-platform-generation.md) | When to regenerate `ios/` |
| [02-macos-prerequisites.md](./02-macos-prerequisites.md) | Xcode / licenses |
| [03-cocoapods-environment.md](./03-cocoapods-environment.md) | CocoaPods install |
| [04-dependency-syncing.md](./04-dependency-syncing.md) | `flutter pub get` + `pod install` |
| [05-testing-and-running.md](./05-testing-and-running.md) | Simulator run |
| [06-physical-device.md](./06-physical-device.md) | Real iPhone signing |
| [07-project-specific-notes.md](./07-project-specific-notes.md) | Feature checklist |
| [08-bank-statement-storage.md](./08-bank-statement-storage.md) | How imports store data |

`IOS APP/` is documentation only. App code lives in `lib/` and `ios/`.
