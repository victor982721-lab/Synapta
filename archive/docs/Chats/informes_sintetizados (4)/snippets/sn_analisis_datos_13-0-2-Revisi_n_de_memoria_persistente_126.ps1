Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'
$root = "$env:USERPROFILE\Desktop\TBEA"
$work = Join-Path $root 'i18n_work'
$tools = Join-Path $root 'tools'
$rh   = Join-Path $tools 'ResourceHacker.exe'
if(-not (Test-Path -LiteralPath $rh)){ throw "Falta ResourceHacker.exe en $rh" }

& $rh -open (Join-Path $work 'YSD300AN.orig.exe')         -save (Join-Path $work 'YSD300AN.es.exe')         -action compile -res (Join-Path $work 'YSD300AN.rc')
& $rh -open (Join-Path $work 'YSD300AN-P2406.orig.exe')   -save (Join-Path $work 'YSD300AN-P2406.es.exe')   -action compile -res (Join-Path $work 'YSD300AN-P2406.rc')

"`n== SHA256 (traducidos) =="
Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $work 'YSD300AN.es.exe'),(Join-Path $work 'YSD300AN-P2406.es.exe') |
  Sort-Object Path | Format-Table Hash, Path -Auto
"[OK] Copias traducidas creadas en: $work"