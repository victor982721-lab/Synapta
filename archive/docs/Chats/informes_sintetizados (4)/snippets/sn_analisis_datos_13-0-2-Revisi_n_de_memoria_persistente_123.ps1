Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'
$root = "$env:USERPROFILE\Desktop\TBEA"
$work = Join-Path $root 'i18n_work'
New-Item -ItemType Directory -Force -Path $work | Out-Null

Copy-Item (Join-Path $root '01_Software\YSD_300AN\YSD300AN.exe')         (Join-Path $work 'YSD300AN.orig.exe') -Force
Copy-Item (Join-Path $root '01_Software\300AN\YSD300AN-P2406.exe')       (Join-Path $work 'YSD300AN-P2406.orig.exe') -Force

"`n== SHA256 (copias) =="
Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $work 'YSD300AN.orig.exe'),(Join-Path $work 'YSD300AN-P2406.orig.exe') |
  Sort-Object Path | Format-Table Hash, Path -Auto