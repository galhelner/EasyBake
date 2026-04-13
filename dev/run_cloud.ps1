param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

# Read app secret from environment so this script is safe to commit.
$internalAppSecret = $env:INTERNAL_APP_SECRET

if ([string]::IsNullOrWhiteSpace($internalAppSecret)) {
  Write-Error "INTERNAL_APP_SECRET is not set in the environment. Set it before running $PSScriptRoot\\run_cloud.ps1."
  exit 1
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$mobileAppPath = Join-Path $repoRoot "apps\easy_bake_mobile"

if (-not (Test-Path $mobileAppPath)) {
  Write-Error "Could not find Flutter app at path: $mobileAppPath"
  exit 1
}

Push-Location $mobileAppPath
try {
  flutter run --dart-define "INTERNAL_APP_SECRET=$internalAppSecret" @FlutterArgs
}
finally {
  Pop-Location
}