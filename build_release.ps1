# Production.INC Release Build Script
# This script builds the app with proper deobfuscation and debug symbols

Write-Host "Building Production.INC Release with deobfuscation and debug symbols..." -ForegroundColor Green

# Clean previous build
Write-Host "Cleaning previous build..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Build the app bundle with debug symbols
Write-Host "Building app bundle..." -ForegroundColor Yellow
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Check if build was successful
if ($LASTEXITCODE -eq 0) {
    Write-Host "Build successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Files generated:" -ForegroundColor Cyan
    Write-Host "- App Bundle: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor White
    Write-Host "- Debug Symbols: build/app/outputs/symbols/" -ForegroundColor White
    Write-Host "- Deobfuscation file: build/app/outputs/mapping/release/mapping.txt" -ForegroundColor White
    Write-Host ""
    Write-Host "Upload Instructions:" -ForegroundColor Yellow
    Write-Host "1. Upload the app-release.aab to Google Play Console"
    Write-Host "2. Upload the mapping.txt as the deobfuscation file"
    Write-Host "3. Upload the debug symbols from the symbols folder"
} else {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}
