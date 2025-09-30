# Crea el archivo EXACTO solicitado con el script completo en una here-string.
# Ruta pedida: C:\Users\VictorFabianVeraVill\Dekstop\mirror_phone.ps1
$path = 'C:\Users\VictorFabianVeraVill\Dekstop\mirror_phone.ps1'
$dir  = Split-Path -Parent $path
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

@'
# mirror_phone.ps1
# Purpose: Mirror Android screen to Windows using scrcpy in READ-ONLY mode (no control).
# Safe by design: does NOT send taps/keys, does NOT close apps on the phone.
# Requires: Windows 10, PowerShell 7+.
# Usage (USB):  Right-click > Run with PowerShell
#        (WiFi optional):  .\mirror_phone.ps1 -Wifi
# Optional args: -MaxSize 1280 -Bitrate "8M" -AlwaysOnTop -Verbose
# Unblock once if needed: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

[CmdletBinding()]
param(
  [switch]$Wifi,
  [int]$MaxSize = 1280,
  [string]$Bitrate = "8M",
  [switch]$AlwaysOnTop
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$toolsDir = Join-Path $env:USERPROFILE "android-tools"
$adbDir   = Join-Path $toolsDir "platform-tools"
$scrDir   = Join-Path $toolsDir "scrcpy"

function New-Dir([string]$path) {
  if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path | Out-Null }
}

function Download-File([string]$uri, [string]$dest) {
  Write-Verbose "Downloading: $uri -> $dest"
  Invoke-WebRequest -Uri $uri -OutFile $dest -UseBasicParsing
  if (-not (Test-Path $dest) -or (Get-Item $dest).Length -le 0) { throw "Download failed: $uri" }
}

function Install-PlatformTools {
  if (Test-Path $adbDir) { return }
  New-Dir $toolsDir
  $zip = Join-Path $toolsDir "platform-tools.zip"
  Write-Host "Downloading platform-tools (ADB) from Google..."
  Download-File "https://dl.google.com/android/repository/platform-tools-latest-windows.zip" $zip
  Expand-Archive $zip -DestinationPath $toolsDir -Force
  Remove-Item $zip -Force
  if (-not (Test-Path $adbDir)) { throw "ADB not found after extraction." }
}

function Get-LatestScrcpyAsset {
  try {
    $headers = @{ "User-Agent" = "mirror_phone.ps1" }
    $release = Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/repos/Genymobile/scrcpy/releases/latest"
    $asset = $release.assets | Where-Object { $_.name -match "scrcpy-win64-.*\.zip$" } | Select-Object -First 1
    if ($null -ne $asset) { return $asset.browser_download_url }
  } catch {
    Write-Verbose "GitHub API failed, will use pinned version."
  }
  return "https://github.com/Genymobile/scrcpy/releases/download/v2.6.1/scrcpy-win64-v2.6.1.zip"
}

function Install-Scrcpy {
  if (Test-Path $scrDir) { return }
  New-Dir $toolsDir
  $zip = Join-Path $toolsDir "scrcpy.zip"
  $uri = Get-LatestScrcpyAsset
  Write-Host "Downloading scrcpy... ($uri)"
  Download-File $uri $zip
  Expand-Archive $zip -DestinationPath $toolsDir -Force
  Remove-Item $zip -Force
  $extracted = Get-ChildItem $toolsDir -Directory | Where-Object { $_.Name -match "^scrcpy-win64-" } | Select-Object -First 1
  if ($null -ne $extracted) {
    if (Test-Path $scrDir) { Remove-Item $scrDir -Recurse -Force }
    Rename-Item -Path $extracted.FullName -NewName "scrcpy"
  }
  if (-not (Test-Path $scrDir)) { throw "scrcpy not found after extraction." }
}

function Ensure-Tools {
  Install-PlatformTools
  Install-Scrcpy
  $env:PATH = "$adbDir;$scrDir;$env:PATH"
}

function Get-AdbDevicesRaw { & adb devices 2>&1 }

function Require-USB-Device {
  Write-Host "Checking for USB device (ADB)..."
  $raw = Get-AdbDevicesRaw
  $hasUnauthorized = $raw | Select-String "`tunauthorized$" -Quiet
  if ($hasUnauthorized) {
    Write-Warning "Device is 'unauthorized'. Unlock the phone and accept the ADB authorization dialog, then run again."
    exit 1
  }
  $hasDevice = $raw | Select-String "`tdevice$" -Quiet
  if (-not $hasDevice) {
    Write-Warning "No USB device detected. Connect via USB and enable 'USB debugging'."
    Write-Host $raw
    exit 1
  }
}

function Get-DeviceIp {
  $ip = (& adb shell ip route 2>$null) | Select-String -Pattern "\bsrc\s+(\d{1,3}(?:\.\d{1,3}){3})\b" | ForEach-Object { $_.Matches[0].Groups[1].Value } | Select-Object -First 1
  if (-not $ip) {
    $ip = (& adb shell ip -f inet addr show wlan0 2>$null) | Select-String -Pattern "inet\s+(\d{1,3}(?:\.\d{1,3}){3})" | ForEach-Object { $_.Matches[0].Groups[1].Value } | Select-Object -First 1
  }
  return $ip
}

function Connect-Wifi {
  Require-USB-Device
  $ip = Get-DeviceIp
  if (-not $ip) { throw "Could not detect phone WiFi IP. Ensure phone and PC are on the same network." }
  Write-Host "Enabling ADB over TCP/IP on $ip:5555 (requires one-time USB)..."
  & adb tcpip 5555 | Out-Null
  Start-Sleep -Seconds 2
  Write-Host "Connecting to $ip:5555 ..."
  & adb connect "$ip`:5555"
  Start-Sleep -Seconds 1
  $raw = Get-AdbDevicesRaw
  $ok = $raw | Select-String "$ip`:5555`tdevice$" -Quiet
  if (-not $ok) { throw "WiFi connect failed. Output:`n$raw" }
  Write-Host "WiFi connection established."
}

function Start-Mirror {
  $opts = @("--no-control", "--max-size", $MaxSize, "--bit-rate", $Bitrate, "--window-title", "Android Mirror (read-only)")
  if ($AlwaysOnTop) { $opts += "--always-on-top" }
  Write-Host "Launching scrcpy in READ-ONLY mode (no input will be sent to the phone)..."
  & scrcpy @opts
}

Ensure-Tools
if ($Wifi) { Connect-Wifi } else { Require-USB-Device }
Start-Mirror
'@ | Set-Content -Path $path -Encoding UTF8

Write-Host "Saved script to: $path"