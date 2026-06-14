# Bumps the build number, then builds a signed Android App Bundle for Google Play.
# Run from the project root: .\tool\build_android_release.ps1

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "Current version:" -ForegroundColor Cyan
dart run tool/bump_build.dart show

Write-Host "`nBumping build number..." -ForegroundColor Cyan
dart run tool/bump_build.dart bump

Write-Host "`nBuilding release app bundle..." -ForegroundColor Cyan
flutter build appbundle --release

Write-Host "`nDone. Commit pubspec.yaml before uploading to Google Play." -ForegroundColor Green
