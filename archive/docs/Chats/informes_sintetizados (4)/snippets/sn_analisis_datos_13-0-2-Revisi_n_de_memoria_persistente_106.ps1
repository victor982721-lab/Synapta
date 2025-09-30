# Baseline local (TBEA-only)
$root = "$env:USERPROFILE\Desktop\TBEA"
$work = Join-Path $root 'i18n_work'
$null = New-Item -ItemType Directory -Force -Path $work

Copy-Item "$root\01_Software\YSD_300AN\YSD300AN.exe"           "$work\YSD300AN.orig.exe" -Force
Copy-Item "$root\01_Software\300AN\YSD300AN-P2406.exe"         "$work\YSD300AN-P2406.orig.exe" -Force

Get-FileHash "$work\YSD300AN.orig.exe","$work\YSD300AN-P2406.orig.exe" -Algorithm SHA256 |
  Format-Table -Auto