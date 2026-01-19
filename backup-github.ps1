# Script para respaldar codigo en GitHub
# Uso: .\backup-github.ps1 "Tu mensaje de commit"

param(
    [Parameter(Mandatory = $true)]
    [string]$mensaje
)

Write-Host "Respaldando codigo en GitHub..." -ForegroundColor Cyan
Write-Host ""

# 1. Verificar estado
Write-Host "Verificando cambios..." -ForegroundColor Yellow
git status --short

Write-Host ""

# 2. Agregar todos los cambios
Write-Host "Agregando archivos..." -ForegroundColor Yellow
git add .

# 3. Hacer commit
Write-Host "Guardando cambios localmente..." -ForegroundColor Yellow
git commit -m $mensaje

# 4. Subir a GitHub
Write-Host "Subiendo a GitHub..." -ForegroundColor Yellow
git push

Write-Host ""
Write-Host "Codigo respaldado exitosamente!" -ForegroundColor Green
Write-Host "Ver en: https://github.com/Bishop0609/Sexta-web-app" -ForegroundColor Cyan
