# Script de Build y Deploy para DirectAdmin
# ==========================================

Write-Host "Iniciando build de produccion..." -ForegroundColor Cyan

# 1. Limpiar build anterior
Write-Host "`nLimpiando build anterior..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error en flutter clean" -ForegroundColor Red
    exit 1
}

# 2. Obtener dependencias
Write-Host "`nObteniendo dependencias..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error en flutter pub get" -ForegroundColor Red
    exit 1
}

# 3. Build para web
Write-Host "`nCompilando para web..." -ForegroundColor Yellow
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error en flutter build" -ForegroundColor Red
    exit 1
}

# 4. Crear ZIP compatible con DirectAdmin usando TAR
Write-Host "`nCreando ZIP compatible..." -ForegroundColor Yellow
$timestamp = Get-Date -Format 'yyyyMMdd-HHmm'
$zipName = "sexta-deploy-$timestamp.zip"

# Eliminar ZIP anterior si existe
if (Test-Path $zipName) {
    Remove-Item $zipName -Force
}

# Crear ZIP con TAR (formato compatible DirectAdmin)
Set-Location build\web
tar -a -c -f "..\..\$zipName" *
Set-Location ..\..

if (Test-Path $zipName) {
    $size = [math]::Round((Get-Item $zipName).Length / 1MB, 2)
    Write-Host "`nBUILD COMPLETADO" -ForegroundColor Green
    Write-Host "===================" -ForegroundColor Green
    Write-Host "Archivo: $zipName" -ForegroundColor White
    Write-Host "Tamanio: $size MB" -ForegroundColor White
    Write-Host "`nListo para subir a DirectAdmin" -ForegroundColor Cyan
}
else {
    Write-Host "Error creando ZIP" -ForegroundColor Red
    exit 1
}
