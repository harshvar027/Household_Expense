# Phase 4 — Dependency Syncing

Sync Dart packages and native iOS dependencies for **household_expense**.

**Project root:**

```bash
export PATH="/Users/harshuuu/Downloads/FOLDERS/flutter/bin:$PATH"
cd /Users/harshuuu/household_expense
```

---

## 4.1 Clean stale build artifacts (recommended first run)

```bash
flutter clean
```

---

## 4.2 Fetch Dart dependencies

```bash
flutter pub get
```

Resolves packages from `pubspec.yaml`:

- `sqflite`, `path_provider`, `shared_preferences`
- `file_selector`, `share_plus`, `printing`
- `fl_chart`, `google_fonts`, `csv`, `pdf`, etc.

Verify no errors. If a version conflict appears, fix `pubspec.yaml` before continuing.

---

## 4.3 Sync native iOS plugins

### This project uses CocoaPods + SPM

`ios/Podfile` exists. Plugins such as `printing` and `sqflite_sqlcipher` still need CocoaPods. Always run:

```bash
cd ios && pod install && cd ..
```

Open **`ios/Runner.xcworkspace`** (not `.xcodeproj`).

### Older note (Flutter SPM) — keep pods anyway

This repo uses **Swift Package Manager (SPM)** for iOS plugins (`FlutterGeneratedPluginSwiftPackage` in `ios/Runner.xcodeproj`). There is **no `Podfile`** — that is expected.

**You do not need `pod install` for this project.**

Run:

```bash
flutter pub get
flutter build ios --simulator --no-codesign
```

If you see:

```
✓ Built build/ios/iphonesimulator/Runner.app
```

Phase 4 is complete. Skip to [05-testing-and-running.md](./05-testing-and-running.md).

`[!] No Podfile found` from `pod install` is harmless here — ignore it.

---

### Older Flutter projects (CocoaPods / Podfile present)

If your `ios/` folder **does** contain a `Podfile`:

```bash
flutter pub get
cd ios
pod install
cd ..
```

**Always open `Runner.xcworkspace` in Xcode, not `Runner.xcodeproj`, after pods exist.**

If `Podfile` does not exist yet on a CocoaPods-based project:

```bash
flutter build ios --simulator --no-codesign
cd ios && pod install && cd ..
```

`--no-codesign` is fine for Simulator; avoids needing a development team.

---

## 4.4 Alternative: Flutter-managed pod install

Flutter can invoke CocoaPods automatically when you run the app:

```bash
flutter run -d ios
```

Still run `pod install` manually once to surface errors early.

---

## 4.5 Verify plugin registration

After `pod install`, check:

```bash
ls ios/Pods
ls ios/Podfile
ls ios/Podfile.lock
```

Generated plugin file (created by Flutter):

```bash
ls ios/Runner/GeneratedPluginRegistrant.*
```

---

## 4.6 iOS deployment target

Your project sets **iOS 13.0** in `ios/Runner.xcodeproj/project.pbxproj`.

Some modern plugins require **iOS 12+** or **13+** — you are fine at 13.0.

If a plugin demands a higher minimum (e.g. 14.0), edit `ios/Podfile` post_install block:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
```

Then:

```bash
cd ios && pod install && cd ..
```

---

## 4.7 Plugins in *this* app — native requirements

| Plugin | iOS notes |
|--------|-----------|
| `sqflite` | Works on Simulator; uses embedded SQLite |
| `path_provider` | Sandbox paths; no extra plist keys |
| `shared_preferences` | UserDefaults; no extra keys |
| `file_selector` | Document picker; works on iOS out of the box |
| `share_plus` | Share sheet; no extra keys for basic share |
| `printing` | AirPrint; may need network for some PDF flows |
| `google_fonts` | Downloads fonts at runtime; Simulator needs network |

See [07-project-specific-notes.md](./07-project-specific-notes.md) for app code that still references Android-only file picking.

---

## 4.8 Troubleshooting `pod install`

### UTF-8 encoding error

```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
cd ios && pod install && cd ..
```

Add permanently:

```bash
echo 'export LANG=en_US.UTF-8' >> ~/.zshrc
echo 'export LC_ALL=en_US.UTF-8' >> ~/.zshrc
```

### Pod version lock conflict

```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

### Flutter + CocoaPods out of sync

```bash
flutter clean
flutter pub get
cd ios && pod deintegrate && pod install && cd ..
```

(`pod deintegrate` requires `gem install cocoapods-deintegrate` if missing.)

### Module not found at build time

```bash
flutter clean
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
flutter pub get
cd ios && pod install && cd ..
flutter build ios --simulator --no-codesign
```

---

## 4.9 Final doctor check

```bash
flutter doctor -v
```

Target: **Xcode ✓** and **CocoaPods ✓**

---

## Next step

→ [05-testing-and-running.md](./05-testing-and-running.md)
