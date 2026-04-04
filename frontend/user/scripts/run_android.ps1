param(
  [string]$DeviceId = "",
  [int]$Port = 5000,
  [string]$ApiBaseUrl = "https://german-bharatham-backend.onrender.com"
)

$ErrorActionPreference = "Stop"

function Get-AdbPath {
  $cmd = Get-Command adb -ErrorAction SilentlyContinue
  if ($cmd -and $cmd.Source) { return $cmd.Source }

  $candidates = @()
  if ($env:LOCALAPPDATA) { $candidates += "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" }
  if ($env:ANDROID_SDK_ROOT) { $candidates += "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe" }
  if ($env:ANDROID_HOME) { $candidates += "$env:ANDROID_HOME\platform-tools\adb.exe" }
  $candidates += "C:\Android\platform-tools\adb.exe"
  $candidates += "E:\Android\platform-tools\adb.exe"

  $candidates = $candidates | Where-Object { $_ -and (Test-Path $_) }

  if ($candidates -and @($candidates).Count -gt 0) { return @($candidates)[0] }

  try {
    $where = (where.exe adb 2>$null | Select-Object -First 1)
    if ($where -and (Test-Path $where)) { return $where }
  } catch {}

  return $null
}

function Get-FirstDeviceId([string]$adb) {
  $lines = & $adb devices
  foreach ($line in $lines) {
    if ($line -match "^(?<id>\S+)\s+device$") { return $Matches['id'] }
  }
  return ""
}

function Test-DeviceOnline([string]$adb, [string]$id) {
  if (-not $id -or $id.Trim().Length -eq 0) { return $false }
  try {
    $state = (& $adb -s $id get-state 2>$null)
    return ($LASTEXITCODE -eq 0) -and ($state -match "device")
  } catch {
    return $false
  }
}

# Ensure we run from Flutter project root (pubspec.yaml exists)
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

if (-not (Test-Path (Join-Path $projectRoot "pubspec.yaml"))) {
  throw "pubspec.yaml not found at $projectRoot (script expects to live in frontend/user/scripts)."
}

$adb = Get-AdbPath
if (-not $adb) {
  throw "adb.exe not found. Install Android platform-tools or set ANDROID_SDK_ROOT, or add platform-tools to PATH."
}

Write-Host "Using adb: $adb"

$deviceProvided = ($PSBoundParameters.ContainsKey('DeviceId') -and $DeviceId -and $DeviceId.Trim().Length -gt 0)

if (-not $deviceProvided) {
  $DeviceId = Get-FirstDeviceId $adb
}

if (-not (Test-DeviceOnline $adb $DeviceId)) {
  if ($deviceProvided) {
    Write-Host "Device '$DeviceId' not found/online. Falling back to first connected device..."
    $DeviceId = Get-FirstDeviceId $adb
  }
}

if (-not (Test-DeviceOnline $adb $DeviceId)) {
  & $adb devices -l | Out-String | Write-Host
  throw "No authorized Android device detected. Plug in the phone, enable USB debugging, and accept the RSA prompt."
}

Write-Host "Target device: $DeviceId"

# Always set up reverse port forwarding for backend
& $adb -s $DeviceId reverse "tcp:$Port" "tcp:$Port" | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "adb reverse failed for device $DeviceId"
}

$rules = & $adb -s $DeviceId reverse --list
if ($LASTEXITCODE -ne 0) {
  throw "adb reverse --list failed for device $DeviceId"
}

$expected = "tcp:$Port tcp:$Port"
if (-not ($rules | Where-Object { $_ -match [regex]::Escape($expected) })) {
  Write-Host "adb reverse --list output:" 
  $rules | ForEach-Object { Write-Host "  $_" }
  throw "adb reverse rule '$expected' is missing"
}

Write-Host "adb reverse rules:"
$rules | ForEach-Object { Write-Host "  $_" }

# Quick backend check (non-fatal)
try {
  $status = (Invoke-WebRequest -UseBasicParsing "$ApiBaseUrl/api/health" -TimeoutSec 3).StatusCode
  Write-Host "Backend health: $status"
} catch {
  Write-Host "Backend health check failed at $ApiBaseUrl/api/health (backend might be down)"
}

flutter pub get
flutter run -d $DeviceId --dart-define=API_BASE_URL=$ApiBaseUrl
