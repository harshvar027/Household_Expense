# Google Play release checklist — Household Expense

Package: **`com.householdexpense.app`**  
Version: **`1.0.0` (code 1)** from `pubspec.yaml`

## Pre-upload (required)

### 1. Signing key
```powershell
.\scripts\android-release-setup.ps1
```
- Back up `android/upload-keystore.jks` and passwords offline.
- Enable **Google Play App Signing** on first upload.

### 2. AdMob production IDs (required for ads)
Google **rejects** apps that ship with test ad IDs in production.

1. Copy `android/admob.properties.example` → `android/admob.properties`
2. Set your real **AdMob App ID** (`appId=ca-app-pub-...~...`)
3. Update `lib/config/ad_config.dart`:
   - `androidBannerId` → your production banner unit ID
   - `iosBannerId` when publishing iOS

### 3. In-app product (subscription)
In [Google Play Console](https://play.google.com/console) → Monetize → Products:

| Product ID | Type | Price |
|---|---|---|
| `household_expense_yearly_1800` | One-time / managed | ₹1800 |

Must match `lib/config/subscription_config.dart`.

### 4. Security config (verify before release)
| Item | Status |
|---|---|
| `enableTestRegistration` | `false` in `dev_auth_config.dart` |
| SMS quick entry | Disabled (`app_feature_flags.dart`) |
| No `READ_SMS` / `RECEIVE_SMS` in manifest | ✓ |
| Release requires upload keystore | ✓ enforced in `build.gradle.kts` |
| `allowBackup=false` (no cloud backup of DB) | ✓ |
| SQLCipher encrypted database | ✓ |
| PIN/password hashed (not stored plain) | ✓ |
| R8 minify + shrink resources | ✓ |
| Change `adminSetupCode` in `feedback_config.dart` | **You must change** |

### 5. Privacy policy (required)
- Host `docs/PRIVACY_POLICY.md` on a public URL (GitHub Pages, website, etc.)
- Enter URL in Play Console → App content → Privacy policy
- Required because: ads (AdMob), financial data, device identifiers

### 6. Play Console declarations

**Data safety** (typical answers for this app):
- Data collected: email, phone (account recovery), financial info (expenses — stored **on device only**)
- Data shared: AdMob may collect advertising IDs (declare per Google’s AdMob data safety guide)
- Data encrypted in transit: N/A for local-only storage; HTTPS if feedback API enabled
- Data deletion: user can clear app data / uninstall

**Ads declaration**: Yes — contains ads (banner during free trial)

**Financial features**: Household budgeting / expense tracking (not a regulated bank)

**Target audience**: 18+ recommended (financial app)

**Content rating**: Complete IARC questionnaire (likely Everyone / Teen)

### 7. Store listing assets
- App name: **Household Expense**
- Short + full description
- Screenshots (phone, 16:9 or 9:16)
- Feature graphic 1024×500
- App icon 512×512 (use `ic_launcher` source)

## Build release bundle

```powershell
.\scripts\play-preflight.ps1   # optional checks
.\scripts\build-aab.ps1
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

Upload in Play Console → Production (or Internal testing first).

## Post-upload

1. Internal testing track → install on real device → smoke test:
   - Register / login / biometric
   - Add expense, import statement, PDF export
   - Subscription purchase (license test account)
   - Ads show only during trial (not premium)
2. Complete all policy tasks until green checkmarks
3. Submit for review

## Common rejection reasons (avoided in this project)

| Risk | Mitigation |
|---|---|
| SMS permissions without justification | SMS feature disabled, no SMS permissions |
| Test AdMob IDs in production | `admob.properties` + banner IDs in `ad_config.dart` |
| Missing privacy policy | `docs/PRIVACY_POLICY.md` |
| Debug signing on release | Keystore required for release build |
| Backup leaking financial DB | `allowBackup=false` |
| Wrong package name | `com.householdexpense.app` (fixed) |

## Support contact (store listing)
- **Krishan Singh Shekhawat**
- Email: krishanshekhawat@gmail.com
- Phone: +91 8975505854
