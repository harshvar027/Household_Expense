# Phase 5 — Testing & Running on iPhone Simulator

Run **household_expense** from Cursor's integrated terminal or macOS Terminal.

**Project root:**

```bash
cd /Users/harshuuu/household_expense
```

---

## 5.1 Boot the iOS Simulator (required before `flutter run`)

Flutter only lists simulators that are **booted**. If you see `No supported devices found with name or id matching 'iPhone 17 Pro'`, the Simulator app is not running yet.

### Option A — One command (recommended)

```bash
flutter emulators --launch apple_ios_simulator
```

Wait ~10 seconds, then verify:

```bash
flutter devices
```

### Option B — Command line

```bash
open -a Simulator
xcrun simctl boot "iPhone 17 Pro"
```

If already booted, `simctl boot` may print an error — safe to ignore.

### Option C — Via Xcode

1. Open **Xcode**
2. **Xcode → Open Developer Tool → Simulator**
3. **File → Open Simulator → iOS 26.5 → iPhone 17 Pro**

### List all simulators

```bash
xcrun simctl list devices available
```

---

## 5.2 Confirm Flutter sees the simulator

```bash
flutter devices
```

Expected (example):

```
iPhone 17 Pro (mobile) • 06A141AA-... • ios • com.apple.CoreSimulator.SimRuntime.iOS-26-5 (simulator)
macOS (desktop)        • macos        • darwin-arm64
Chrome (web)           • chrome       • web-javascript
```

Copy the **device ID** (UUID) if you need an exact target.

---

## 5.3 Run the app (first launch)

### Default — Flutter picks the only iOS simulator

```bash
flutter run
```

### Explicit device name

```bash
flutter run -d "iPhone 17 Pro"
```

### Explicit device ID

```bash
flutter run -d 06A141AA-C081-474B-9AC2-8172E5B96FA0
```

### Release mode (faster UI, harder to debug)

```bash
flutter run -d "iPhone 17 Pro" --release
```

---

## 5.4 Running from Cursor IDE

### Integrated terminal

1. **Terminal → New Terminal** (`` Ctrl+` `` or `` Cmd+` ``)
2. Ensure cwd is project root:

   ```bash
   cd /Users/harshuuu/household_expense
   ```

3. Start Simulator:

   ```bash
   open -a Simulator
   ```

4. Run:

   ```bash
   flutter run -d "iPhone 17 Pro"
   ```

### Cursor / VS Code launch configuration (optional)

Create `.vscode/launch.json` at project root:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "household_expense (iPhone Simulator)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "deviceId": "iPhone 17 Pro"
    }
  ]
}
```

Then use **Run and Debug** (sidebar play icon) → select **household_expense (iPhone Simulator)**.

Install the **Dart** and **Flutter** extensions in Cursor if not already present.

---

## 5.5 Hot reload during development

With `flutter run` active:

| Key | Action |
|-----|--------|
| `r` | Hot reload |
| `R` | Hot restart |
| `q` | Quit |
| `p` | Toggle performance overlay |

---

## 5.6 Build without running (CI / sanity check)

Simulator build, no signing:

```bash
flutter build ios --simulator --no-codesign
```

Output: `build/ios/iphonesimulator/Runner.app`

---

## 5.7 Open in Xcode (debug native issues)

```bash
open ios/Runner.xcworkspace
```

In Xcode:

1. Select **Runner** scheme
2. Destination: **iPhone 17 Pro**
3. Press **▶ Run**

Useful for signing errors, plist issues, or Swift/ObjC crashes.

---

## 5.8 Common runtime issues

### "No supported devices found with name or id matching 'iPhone 17 Pro'"

The simulator is installed but **not booted**. Run:

```bash
flutter emulators --launch apple_ios_simulator
sleep 5
flutter devices
```

You should see `iPhone 17 Pro (mobile)` in the list before running `flutter run`.

### CocoaPods / plugin errors on run

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run -d "iPhone 17 Pro"
```

### Codesign error (Simulator only)

Use:

```bash
flutter run -d "iPhone 17 Pro" --no-codesign
```

Or build with:

```bash
flutter build ios --simulator --no-codesign
```

### App installs but crashes on CSV import

Your `lib/services/csv_import_service.dart` uses an Android `MethodChannel` for file picking. On iOS, `file_selector` path should work — but test import/export after first launch. See [07-project-specific-notes.md](./07-project-specific-notes.md).

### SQLite / database errors on fresh install

Normal on first launch — `sqflite` creates DB in app sandbox. Delete app from Simulator and reinstall to reset:

```bash
xcrun simctl uninstall booted com.householdexpense.app
flutter run -d "iPhone 17 Pro"
```

---

## 5.9 Success checklist

- [ ] Simulator shows home screen
- [ ] `flutter devices` lists iPhone simulator
- [ ] `flutter run` completes without build errors
- [ ] App icon appears on Simulator home screen
- [ ] App opens to your main UI (`lib/main.dart`)
- [ ] Hot reload (`r`) works

---

## Next step (optional)

→ [06-physical-device.md](./06-physical-device.md) for a real iPhone
