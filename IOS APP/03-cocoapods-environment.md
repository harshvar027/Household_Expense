# Phase 3 — CocoaPods Environment (Apple Silicon)

`flutter doctor` on your Mac reports: **CocoaPods not installed.**

Flutter iOS plugins (`sqflite`, `path_provider`, `share_plus`, `file_selector`, `printing`, etc.) link native code through CocoaPods (or Swift Package Manager for some plugins). You need CocoaPods working before the first successful iOS build.

---

## 3.1 Prerequisites

Homebrew (recommended package manager for Mac):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After install on Apple Silicon, follow the shell snippet Homebrew prints (adds brew to PATH).

Verify:

```bash
brew --version
```

---

## 3.2 Install Ruby dependencies (recommended path)

Use Homebrew Ruby — avoids system Ruby permission issues on macOS:

```bash
brew install ruby
```

Add Homebrew Ruby to PATH (Apple Silicon default location):

```bash
echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc
echo 'export PATH="/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

> **Note:** Gem bin path follows your Homebrew Ruby version. Find yours with:
> ```bash
> gem environment gemdir
> # Then append /bin — e.g. /opt/homebrew/lib/ruby/gems/4.0.0/bin
> ```

---

## 3.3 Install CocoaPods

```bash
sudo gem install cocoapods
```

**Without sudo** (if you use Homebrew Ruby only):

```bash
gem install cocoapods
```

Verify:

```bash
pod --version
```

Expected: `1.16.x` or similar.

---

## 3.4 Initialize CocoaPods master repo (first time only)

```bash
pod setup
```

This can take several minutes. Alternatively, modern CocoaPods uses CDN and may skip heavy setup — if `pod install` works later, you can ignore slow `pod setup`.

---

## 3.5 Apple Silicon troubleshooting

### Problem: `ffi` gem errors / wrong architecture

```bash
sudo gem uninstall ffi
sudo gem install ffi -- --enable-libffi-alloc
```

Or via Homebrew:

```bash
brew install libffi
gem install ffi
```

### Problem: `pod: command not found` after install

```bash
echo 'export PATH="$(gem environment gemdir)/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
which pod
```

### Problem: Permission denied on `/Library/Ruby/Gems/`

Do **not** fight system Ruby. Switch to Homebrew Ruby (section 3.2) and run:

```bash
gem install cocoapods
```

### Problem: SSL / CDN errors during `pod install`

```bash
pod repo update
```

Or remove stale spec repo:

```bash
pod repo remove trunk
pod install
```

### Problem: Xcode tools not found during pod install

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

### Problem: Extremely slow first `pod install`

Normal. Flutter projects with many plugins can take 5–15 minutes the first time.

---

## 3.6 Confirm Flutter sees CocoaPods

```bash
cd /Users/harshuuu/household_expense
flutter doctor
```

CocoaPods line under **Xcode** should turn green ✓

---

## Next step

→ [04-dependency-syncing.md](./04-dependency-syncing.md)
