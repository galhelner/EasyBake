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
$stopServicesScript = Join-Path $repoRoot "scripts\windows\stop-services.ps1"

if (-not (Test-Path $mobileAppPath)) {
  Write-Error "Could not find Flutter app at path: $mobileAppPath"
  exit 1
}

if (-not (Test-Path $startServicesScript)) {
  Write-Error "Could not find services startup script at path: $startServicesScript"
  exit 1
}

if (-not (Test-Path $stopServicesScript)) {
  Write-Error "Could not find services shutdown script at path: $stopServicesScript"
  exit 1
}

$cleanupDone = $false

function Invoke-Cleanup {
  if ($cleanupDone) {
    return
  }

  $script:cleanupDone = $true
  Write-Host "Stopping backend services..."
  & $stopServicesScript

  if ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) {
    Write-Warning "Cleanup script exited with code: $LASTEXITCODE"
  }
}

trap [System.Management.Automation.PipelineStoppedException] {
  Write-Warning "Execution interrupted. Running cleanup..."
  Invoke-Cleanup
  exit 130
}

Write-Host "Starting backend services..."
& $startServicesScript

if ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) {
  Write-Error "Failed to start backend services (exit code: $LASTEXITCODE)."
  exit $LASTEXITCODE
}

# Resolve active local IP address dynamically to prevent stale hardcoded IPs.
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "172.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1).IPAddress
if ([string]::IsNullOrWhiteSpace($localIP)) {
  $localIP = "10.231.1.140"
}
Write-Host "Resolved local host IP: $localIP"

Push-Location $mobileAppPath
$flutterExitCode = 0
try {
  flutter run --dart-define "INTERNAL_APP_SECRET=$internalAppSecret" --dart-define "DEV_MODE=true" --dart-define "LOCAL_API_BASE_URL=http://${localIP}:4000" --dart-define "LOCAL_CHAT_BASE_URL=http://${localIP}:4001" @FlutterArgs
  if ($LASTEXITCODE -ne $null) {
    $flutterExitCode = $LASTEXITCODE
  }
}
finally {
  Pop-Location
  Invoke-Cleanup
}

if ($flutterExitCode -ne 0) {
  exit $flutterExitCode
}
