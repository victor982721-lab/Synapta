#requires -Version 7
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'

$RH   = "C:\Users\VictorFabianVeraVill\Desktop\TBEA\tools\ResourceHacker.exe"
$dst  = "C:\Users\VictorFabianVeraVill\Desktop\TBEA\i18n_work"

$src1 = "C:\YSD300A\YSD300AN.exe"
$src2 = "C:\YSD300A\YSD300AN-P2406.exe"
$rc1  = Join-Path $dst "YSD300AN.rc"
$rc2  = Join-Path $dst "YSD300AN-P2406.rc"
$res1 = Join-Path $dst "YSD300AN.res"
$res2 = Join-Path $dst "YSD300AN-P2406.res"
$out1 = Join-Path $dst "YSD300AN.es.exe"
$out2 = Join-Path $dst "YSD300AN-P2406.es.exe"

# 1) Compilar los .rc a .res
& $RH -open $rc1 -save $res1 -action compile
& $RH -open $rc2 -save $res2 -action compile

# 2) Reinyectar .res a nuevas copias .es.exe
& $RH -open $src1 -save $out1 -action addoverwrite -res $res1
& $RH -open $src2 -save $out2 -action addoverwrite -res $res2

"`n== SHA256 (build .es) =="
Get-FileHash -Algorithm SHA256 -LiteralPath $out1,$out2 | Sort-Object Path | Format-Table Hash,Path -Auto

"[OK] Copias traducidas generadas en: $dst"