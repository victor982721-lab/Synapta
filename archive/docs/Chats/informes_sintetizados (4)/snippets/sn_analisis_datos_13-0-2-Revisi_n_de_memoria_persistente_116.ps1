# === Verificación TBEA (solo lectura) ===
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'

# Raíz de trabajo
$Root  = "$env:USERPROFILE\Desktop\TBEA"
$Tools = Join-Path $Root 'tools'
$Work  = Join-Path $Root 'i18n_work'

# Helpers
function Check($name, $path, $type='Leaf'){
  $ok = Test-Path -LiteralPath $path -PathType $type
  $state = if($ok){'OK'} else {'MISSING'}
  '{0,-9}  {1}  -> {2}' -f "[$state]", $name, $path
  [pscustomobject]@{Item=$name; Path=$path; Exists=$ok}
}

$results = @()

# 1) Estructura básica y ejecutables originales
$results += Check 'TBEA root'   $Root 'Container'
$results += Check 'YSD300AN'     (Join-Path $Root '01_Software\YSD_300AN\YSD300AN.exe')
$results += Check 'YSD300AN+P2406' (Join-Path $Root '01_Software\300AN\YSD300AN-P2406.exe')
$results += Check 'HL-340 driver pkg' (Join-Path $Root '01_Software\01_Drives_(Hl-340).exe')

# 2) Herramientas en TBEA\tools (opcionales pero deseables)
$ghBat = Get-ChildItem -LiteralPath $Tools -Recurse -Filter 'ghidraRun.bat' -ErrorAction SilentlyContinue | Select-Object -First 1
if($ghBat){ $results += Check 'Ghidra distro' $ghBat.FullName } else { '[WARN]   Ghidra distro no encontrada bajo TBEA\tools' }
$results += Check 'ResourceHacker' (Join-Path $Tools 'ResourceHacker.exe')

# 3) Área de trabajo i18n (copias, .rc, .es.exe)
$results += Check 'i18n_work' $Work 'Container'
$results += Check 'copy: YSD300AN.orig'       (Join-Path $Work 'YSD300AN.orig.exe')
$results += Check 'copy: YSD300AN-P2406.orig' (Join-Path $Work 'YSD300AN-P2406.orig.exe')
$results += Check 'rc: YSD300AN.rc'           (Join-Path $Work 'YSD300AN.rc')
$results += Check 'rc: YSD300AN-P2406.rc'     (Join-Path $Work 'YSD300AN-P2406.rc')
$results += Check 'build: YSD300AN.es'        (Join-Path $Work 'YSD300AN.es.exe')
$results += Check 'build: YSD300AN-P2406.es'  (Join-Path $Work 'YSD300AN-P2406.es.exe')

# 4) Hashes (si existen) para huella antes/después
$toHash = @(
  Join-Path $Root '01_Software\YSD_300AN\YSD300AN.exe'),
  (Join-Path $Root '01_Software\300AN\YSD300AN-P2406.exe'),
  (Join-Path $Work 'YSD300AN.orig.exe'),
  (Join-Path $Work 'YSD300AN-P2406.orig.exe'),
  (Join-Path $Work 'YSD300AN.es.exe'),
  (Join-Path $Work 'YSD300AN-P2406.es.exe')
) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }

if($toHash.Count){
  "`n== SHA256 =="
  Get-FileHash -Algorithm SHA256 -LiteralPath $toHash | Sort-Object Path |
    Format-Table Hash, Path -Auto
}

"`n== RESUMEN =="
$results | Sort-Object Item | Format-Table -Auto