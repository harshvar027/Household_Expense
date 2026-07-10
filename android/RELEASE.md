# Android release build (Google Play)

See the full checklist: **[docs/GOOGLE_PLAY_RELEASE_CHECKLIST.md](../docs/GOOGLE_PLAY_RELEASE_CHECKLIST.md)**

## Package name

**`com.householdexpense.app`** — cannot change after first Play upload.

## Quick start

### 1. One-time signing setup

```powershell
.\scripts\android-release-setup.ps1
```

Creates `android/upload-keystore.jks` and `android/key.properties` (gitignored). **Back up the keystore and passwords.**

### 2. AdMob production IDs (before Play upload)

```powershell
copy android\admob.properties.example android\admob.properties
# Edit appId=your real AdMob App ID
```

Also update banner unit IDs in `lib/config/ad_config.dart`.

### 3. Preflight checks

```powershell
.\scripts\play-preflight.ps1
```

### 4. Build signed App Bundle (.aab)

```powershell
.\scripts\build-aab.ps1
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Upload in [Google Play Console](https://play.google.com/console).

## Security (release build)

- Release builds **require** upload keystore (no debug signing fallback)
- `allowBackup=false` — financial data not included in device backup
- R8 minify + resource shrinking enabled
- SMS permissions not declared; SMS quick entry disabled

## Privacy policy

Host `docs/PRIVACY_POLICY.md` at a public HTTPS URL and add it in Play Console.

## Play App Signing

Enable **Google Play App Signing** on first upload. Google holds the app signing key; you keep the upload keystore.
