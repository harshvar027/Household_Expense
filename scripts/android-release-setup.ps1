# Creates upload keystore + android/key.properties for Play Store release signing.
# Run from repo root: .\scripts\android-release-setup.ps1

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$androidDir = Join-Path $repoRoot "android"
$keystorePath = Join-Path $androidDir "upload-keystore.jks"
$keyPropsPath = Join-Path $androidDir "key.properties"

if (Test-Path $keystorePath) {
    Write-Host "Keystore already exists: $keystorePath"
    Write-Host "Delete it first if you want to regenerate."
    exit 1
}

$storePass = Read-Host "Enter keystore password (min 6 chars)" -AsSecureString
$storePassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePass)
)
$keyPassPlain = Read-Host "Enter key password (press Enter to reuse keystore password)" 
if ([string]::IsNullOrWhiteSpace($keyPassPlain)) {
    $keyPassPlain = $storePassPlain
}

$dname = "CN=Household Expense, OU=Mobile, O=Household Expense, L=India, ST=India, C=IN"

& keytool -genkeypair -v `
    -storetype PKCS12 `
    -keystore $keystorePath `
    -alias upload `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -storepass $storePassPlain `
    -keypass $keyPassPlain `
    -dname $dname

@"
storePassword=$storePassPlain
keyPassword=$keyPassPlain
keyAlias=upload
storeFile=upload-keystore.jks
"@ | Set-Content -Path $keyPropsPath -Encoding UTF8

Write-Host ""
Write-Host "Created:"
Write-Host "  $keystorePath"
Write-Host "  $keyPropsPath"
Write-Host ""
Write-Host "BACK UP upload-keystore.jks and passwords securely."
Write-Host "Google Play cannot recover a lost upload key without support."
