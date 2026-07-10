# Build signed release App Bundle (.aab) for Google Play.
# Run from repo root: .\scripts\build-aab.ps1

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$keyProps = Join-Path $repoRoot "android\key.properties"

if (-not (Test-Path $keyProps)) {
    Write-Host "Missing android/key.properties"
    Write-Host "Run: .\scripts\android-release-setup.ps1"
    exit 1
}

Set-Location $repoRoot
flutter pub get
flutter build appbundle --release

$bundle = Join-Path $repoRoot "build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $bundle) {
    Write-Host ""
    Write-Host "Release bundle ready:"
    Write-Host "  $bundle"
} else {
    Write-Host "Build finished but bundle not found at expected path."
    exit 1
}
