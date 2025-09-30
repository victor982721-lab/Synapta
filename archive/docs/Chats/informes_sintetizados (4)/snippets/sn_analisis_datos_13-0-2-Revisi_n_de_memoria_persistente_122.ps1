#requires -Version 7
# === Verificación TBEA (solo lectura) — v3 ===
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'

try {
  $Root  = "$env:USERPROFILE\Desktop\TBEA"
  $Tools = Join-Path $Root 'tools'
  $Work  = Join-Path $Root 'i18n_work'

  function Check($name, $path, $type='Leaf'){
    $ok    = Test-Path -LiteralPath $path -PathType $type
    $state = if($ok){'OK'} else {'MISSING'}
    Write-Host ("{0,-9}  {1}  -> {2}" -f "[$state]", $name, $path)
    [pscustomobject]@{ Item=$name; Path=$path; Exists=$ok }
  }

  function Test-Ascii([string]$text){
    foreach($ch in $text.ToCharArray()){ if([int][char]$ch -gt 127){ return $false } }
    return $true
  }

  $results = @()

  # 1) Estructura y artefactos base
  $results += Check 'TBEA root'                $Root 'Container'
  $results += Check 'YSD300AN'                  (Join-Path $Root '01_Software\YSD_300AN\YSD300AN.exe')
  $results += Check 'YSD300AN+P2406'            (Join-Path $Root '01_Software\300AN\YSD300AN-P2406.exe')
  $results += Check 'HL-340 driver pkg'         (Join-Path $Root '01_Software\01_Drives_(Hl-340).exe')

  # 2) Herramientas (Ghidra + Resource editor) dentro de TBEA\tools
  $ghBat = Get-ChildItem -LiteralPath $Tools -Recurse -Filter 'ghidraRun.bat' -ErrorAction SilentlyContinue | Select-Object -First 1
  if($ghBat){
    $results += Check 'Ghidra distro' $ghBat.FullName
    $headless = Get-ChildItem -LiteralPath (Split-Path $ghBat.FullName -Parent) -Recurse -ErrorAction SilentlyContinue `
                | Where-Object { $_.Name -in @('analyzeHeadless.bat','analyzeHeadless','analyzeHeadless.sh') } `
                | Select-Object -First 1
    if($headless){ $results += Check 'Ghidra headless' $headless.FullName } else { Write-Host '[WARN]   analyzeHeadless no encontrado en la distro' }
  } else {
    Write-Host '[WARN]   Ghidra distro no encontrada bajo TBEA\tools'
  }

  $results += Check 'ResourceHacker'            (Join-Path $Tools 'ResourceHacker.exe')

  # 3) Área de trabajo i18n (copias, .rc, .es.exe)
  $results += Check 'i18n_work'                 $Work 'Container'
  $results += Check 'copy: YSD300AN.orig'       (Join-Path $Work 'YSD300AN.orig.exe')
  $results += Check 'copy: YSD300AN-P2406.orig' (Join-Path $Work 'YSD300AN-P2406.orig.exe')
  $results += Check 'rc: YSD300AN.rc'           (Join-Path $Work 'YSD300AN.rc')
  $results += Check 'rc: YSD300AN-P2406.rc'     (Join-Path $Work 'YSD300AN-P2406.rc')
  $results += Check 'build: YSD300AN.es'        (Join-Path $Work 'YSD300AN.es.exe')
  $results += Check 'build: YSD300AN-P2406.es'  (Join-Path $Work 'YSD300AN-P2406.es.exe')

  # 4) Hashes disponibles (huella antes/después)
  $toHash = @(
    (Join-Path $Root '01_Software\YSD_300AN\YSD300AN.exe'),
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

  # 5) Auditoría ASCII (rutas bajo TBEA que contengan no-ASCII)
  "`n== ASCII AUDIT =="
  $nonAscii = Get-ChildItem -LiteralPath $Root -Recurse -Force -ErrorAction SilentlyContinue |
              ForEach-Object {
                $p = $_.FullName
                if(-not (Test-Ascii $p)){ $p }
              }
  if($nonAscii){
    Write-Host "[WARN]   Se detectaron rutas con caracteres no ASCII (revisa/normaliza):"
    $nonAscii | Select-Object -First 80
  } else {
    Write-Host "[OK]     Todos los nombres bajo TBEA son ASCII."
  }

  "`n== RESUMEN =="
  $results | Sort-Object Item | Format-Table -Auto

  $ok   = ($results | Where-Object { $_.Exists }).Count
  $miss = ($results | Where-Object { -not $_.Exists }).Count
  "`nOK: $ok   MISSING: $miss"
}
catch {
  "`n[ERROR] Verificación interrumpida: $($_.Exception.Message)"
  if($_.InvocationInfo){ "En: $($_.InvocationInfo.PositionMessage)" }
}