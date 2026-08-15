# Android downloads

- `latest.apk` — showcase debug build of Household Expense (`com.householdexpense.app`)
- `version.json` — metadata

For a Play-signed release APK, create `android/key.properties` + upload keystore, then run:

```bash
cd ..
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk website/public/downloads/latest.apk
```
