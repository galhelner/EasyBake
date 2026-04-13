param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

# Read app secret from environment so this script is safe to commit.
$internalAppSecret = $env:INTERNAL_APP_SECRET

if ([string]::IsNullOrWhiteSpace($internalAppSecret)) {
  Write-Error "INTERNAL_APP_SECRET is not set in the environment. Set it before running $PSScriptRoot\\run_local.ps1."
  exit 1
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$mobileAppPath = Join-Path $repoRoot "apps\easy_bake_mobile"
$startServicesScript = Join-Path $repoRoot "scripts\windows\start-services.ps1"

if (-not (Test-Path $mobileAppPath)) {
  Write-Error "Could not find Flutter app at path: $mobileAppPath"
  exit 1
}

if (-not (Test-Path $startServicesScript)) {
  Write-Error "Could not find services startup script at path: $startServicesScript"
  exit 1
}

Write-Host "Starting backend services..."
& $startServicesScript

if ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) {
  Write-Error "Failed to start backend services (exit code: $LASTEXITCODE)."
  exit $LASTEXITCODE
}

Push-Location $mobileAppPath
try {
  flutter run --dart-define "INTERNAL_APP_SECRET=$internalAppSecret" --dart-define "DEV_MODE=true" --dart-define "LOCAL_API_BASE_URL=http://10.231.1.139:4000" @FlutterArgs
}
finally {
  Pop-Location
}
