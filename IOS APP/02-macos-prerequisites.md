# Phase 2 — macOS System Prerequisites

Apple Silicon Mac (M-series). All commands run in **Terminal** or the **Cursor integrated terminal**.

---

## 2.1 Install Xcode (full app, not only CLI tools)

1. Open **App Store** on your Mac
2. Search **Xcode** → Install (large download, ~10–15 GB)
3. Open Xcode once after install → allow additional components

**Your status:** Xcode **26.6** is already at `/Applications/Xcode.app` ✓

To confirm:

```bash
xcodebuild -version
```

Expected output similar to:

```
Xcode 26.6
Build version 17F113
```

---

## 2.2 Point `xcode-select` at full Xcode

Required so `flutter`, `pod`, and simulators use the correct toolchain:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

Verify:

```bash
xcode-select -p
```

Expected:

```
/Applications/Xcode.app/Contents/Developer
```

---

## 2.3 Install Xcode Command Line Tools

Usually installed with Xcode. If missing or broken:

```bash
xcode-select --install
```

A GUI dialog appears → click **Install**.

Verify:

```bash
clang --version
git --version
```

---

## 2.4 Accept Xcode license (terminal)

Must be done once per Xcode major version. Requires admin password.

```bash
sudo xcodebuild -license accept
```

If that fails or you need to read first:

```bash
sudo xcodebuild -license
```

Press **space** to scroll, type `agree` at the end.

---

## 2.5 Run first-launch Xcode setup

Opens Xcode and installs extra platform pieces:

```bash
sudo xcodebuild -runFirstLaunch
```

---

## 2.6 Install iOS Simulator runtime

**Your status:** Simulators for **iOS 26.5** are already installed ✓

List available devices:

```bash
xcrun simctl list devices available
```

To install more runtimes via GUI:

1. Open **Xcode**
2. **Xcode → Settings → Platforms** (or **Components** on older Xcode)
3. Download **iOS** simulator runtime if missing

---

## 2.7 Flutter on PATH

Your Flutter is at `/Users/harshuuu/Downloads/FOLDERS/flutter`. Add to `~/.zshrc` if not already:

```bash
echo 'export PATH="$PATH:/Users/harshuuu/Downloads/FOLDERS/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

Verify:

```bash
which flutter
flutter --version
```

---

## 2.8 Full environment check

```bash
cd /Users/harshuuu/household_expense
flutter doctor -v
```

### What you should see when Phase 2 is complete

| Check | Expected |
|-------|----------|
| Flutter | ✓ green |
| Xcode | ✓ at `/Applications/Xcode.app` |
| CocoaPods | ✗ until Phase 3 |
| Connected device | macOS, Chrome; iOS appears after Simulator boots (Phase 5) |

Android warnings are OK for iOS-only work.

---

## 2.9 Optional: Rosetta (rarely needed on Apple Silicon)

Most Flutter/iOS tooling is arm64-native. Install Rosetta only if a gem or tool errors with `x86_64` / `bad CPU type`:

```bash
softwareupdate --install-rosetta --agree-to-license
```

---

## Next step

→ [03-cocoapods-environment.md](./03-cocoapods-environment.md)
