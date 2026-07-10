# Pre-release checks before building the Play Store bundle.
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$failures = @()

function Warn($msg) { Write-Host "WARN: $msg" -ForegroundColor Yellow }
function Fail($msg) { $script:failures += $msg; Write-Host "FAIL: $msg" -ForegroundColor Red }
function Pass($msg) { Write-Host "OK:   $msg" -ForegroundColor Green }

Write-Host "Household Expense — Play preflight" -ForegroundColor Cyan
Write-Host ""

# Signing
if (-not (Test-Path (Join-Path $repoRoot "android\key.properties"))) {
    Fail "Missing android/key.properties — run .\scripts\android-release-setup.ps1"
} else { Pass "Release signing config present" }

if (-not (Test-Path (Join-Path $repoRoot "android\upload-keystore.jks"))) {
    Fail "Missing android/upload-keystore.jks"
} else { Pass "Upload keystore present" }

# AdMob
$admobPath = Join-Path $repoRoot "android\admob.properties"
$adConfigPath = Join-Path $repoRoot "lib\config\ad_config.dart"
if (-not (Test-Path $admobPath)) {
    Warn "android/admob.properties missing — release build will use AdMob TEST app ID"
} else {
    $admob = Get-Content $admobPath -Raw
    if ($admob -match "3940256099942544") { Fail "admob.properties still contains Google TEST app ID" }
    else { Pass "Production AdMob app ID configured" }
}
if (Test-Path $adConfigPath) {
    $adDart = Get-Content $adConfigPath -Raw
    if ($adDart -match "3940256099942544/6300978111") {
        Warn "lib/config/ad_config.dart still uses TEST banner ID — replace before Play upload"
    } else { Pass "Banner ad unit ID appears customized" }
}

# Dev flags
$devAuth = Join-Path $repoRoot "lib\config\dev_auth_config.dart"
if ((Get-Content $devAuth -Raw) -notmatch "enableTestRegistration = false") {
    Fail "enableTestRegistration must be false"
} else { Pass "Test registration disabled" }

$smsFlag = Join-Path $repoRoot "lib\config\app_feature_flags.dart"
if ((Get-Content $smsFlag -Raw) -notmatch "smsQuickEntryEnabled = false") {
    Fail "SMS quick entry must be disabled for Play"
} else { Pass "SMS quick entry disabled" }

# Manifest SMS permissions
$manifest = Join-Path $repoRoot "android\app\src\main\AndroidManifest.xml"
$manifestText = Get-Content $manifest -Raw
if ($manifestText -match "READ_SMS|RECEIVE_SMS|RECEIVE_MMS") {
    Fail "AndroidManifest contains SMS permissions"
} else { Pass "No SMS permissions in manifest" }

# Privacy policy doc
if (-not (Test-Path (Join-Path $repoRoot "docs\PRIVACY_POLICY.md"))) {
    Warn "docs/PRIVACY_POLICY.md missing — host publicly for Play Console"
} else { Pass "Privacy policy document present" }

Write-Host ""
if ($failures.Count -gt 0) {
    Write-Host "Preflight failed ($($failures.Count) blocking issue(s))." -ForegroundColor Red
    exit 1
}
Write-Host "Preflight passed (review WARN items before production upload)." -ForegroundColor Green
exit 0
