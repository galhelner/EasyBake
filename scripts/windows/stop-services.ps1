# Stop EasyBake services
Write-Host "Stopping EasyBake services..." -ForegroundColor Yellow
Set-Location (Split-Path $PSCommandPath)
Set-Location ../..
docker compose down
Write-Host "Services stopped." -ForegroundColor Green
