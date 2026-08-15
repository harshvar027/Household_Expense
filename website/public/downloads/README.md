# Android downloads

`latest.apk` is the 64-bit release APK served from the website at `/downloads/latest.apk`.

Rebuild:

```bash
flutter build apk --release --split-per-abi --target-platform android-arm64
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk website/public/downloads/latest.apk
```
