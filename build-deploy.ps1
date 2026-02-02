# Quick Deploy Script for cPanel
# This script builds and prepares your Flutter Web app for cPanel deployment

Write-Host "Build Script - Sexta Compania ERP" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# Step 1: Clean previous builds
Write-Host "Step 1: Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Flutter clean failed" -ForegroundColor Red
    exit 1
}
Write-Host "Clean complete`n" -ForegroundColor Green

# Step 2: Get dependencies
Write-Host "Step 2: Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to get dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "Dependencies installed`n" -ForegroundColor Green

# Step 3: Build for web production
Write-Host "Step 3: Building Flutter Web..." -ForegroundColor Yellow
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "Build complete`n" -ForegroundColor Green

# Step 4: Copy .htaccess to build folder
Write-Host "Step 4: Copying .htaccess..." -ForegroundColor Yellow
Copy-Item -Path ".htaccess" -Destination "build\web\.htaccess" -Force
Write-Host ".htaccess copied`n" -ForegroundColor Green

# Step 5: Create ZIP file
Write-Host "Step 5: Creating deployment ZIP..." -ForegroundColor Yellow
$zipPath = "sgi-build-$(Get-Date -Format 'yyyy-MM-dd-HHmm').zip"
Compress-Archive -Path "build\web\*" -DestinationPath $zipPath -Force
Write-Host "ZIP created: $zipPath`n" -ForegroundColor Green

# Step 6: Show file size
$zipSize = (Get-Item $zipPath).Length / 1MB
Write-Host "Build Information:" -ForegroundColor Cyan
Write-Host "   File: $zipPath" -ForegroundColor White
Write-Host "   Size: $([math]::Round($zipSize, 2)) MB`n" -ForegroundColor White

Write-Host "SUCCESS! Build ready for deployment" -ForegroundColor Green
Write-Host "Upload to /public_html/sgi/ in cPanel" -ForegroundColor Cyan
