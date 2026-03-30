# Start EasyBake services in detached mode with rebuilds
Write-Host "Starting EasyBake services..." -ForegroundColor Green
Set-Location (Split-Path $PSCommandPath)
Set-Location ../..
docker compose up -d --build
Write-Host "Services started. Run 'docker compose ps' to check status." -ForegroundColor Green
