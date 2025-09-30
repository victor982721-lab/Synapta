#requires -Version 7
# === TBEA i18n runner — sin Defender, TBEA-only ===
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'

try {
  # --- Config ---
  $Root  = "$env:USERPROFILE\Desktop\TBEA"
  $Work  = Join-Path $Root 'i18n_work'
  $Tools = Join-Path $Root 'tools'
  $RH    = Join-Path $Tools 'ResourceHacker.exe'   # opcional (portable)

  # toggles (puedes poner $false si no los quieres):
  $DoAsciiCopies = $true     # Copias ASCII-safe bajo TBEA\normalized
  $DoExtractRC   = $true     # Extraer .rc si está ResourceHacker.exe
  $DoCompileES   = $true     # Compilar *.es.exe si existen .rc

  # --- Helpers ---
  function Test-Ascii([string]$s){
    foreach($ch in $s.ToCharArray()){ if([int][char]$ch -gt 127){ return $false } }
    $true
  }
  function Sanitize-Name([string]$name){
    $base = [IO.Path]::GetFileNameWithoutExtension($name)
    $ext  = [IO.Path]::GetExtension($name)
    if(-not $base){ $base = 'name' }
    $san = -join ($base.ToCharArray() | ForEach-Object { if([int][char]$_ -le 127){ $_ } else { '_' } })
    if(-not $san){ $san = 'name' }
    return "$san$ext"
  }
  function Convert-RelPath-ToAscii([string]$rel){
    $parts = $rel -split '[\\/]' | Where-Object { $_ -ne '' }
    $sanParts = @()
    for($i=0; $i -lt $parts.Count; $i++){
      $seg = $parts[$i]
      $sanParts += (Sanitize-Name $seg)
    }
    ($sanParts -join '\')
  }
  function Ensure-Unique([string]$fullPath){
    if(-not (Test-Path -LiteralPath $fullPath)){ return $fullPath }
    $dir = Split-Path $fullPath -Parent
    $n   = [IO.Path]::GetFileNameWithoutExtension($fullPath)
    $ext = [IO.Path]::GetExtension($fullPath)
    $i = 1
    while(Test-Path -LiteralPath (Join-Path $dir "$n`_$i$ext")){ $i++ }
    Join-Path $dir "$n`_$i$ext"
  }

  # --- Preparación área de trabajo ---
  New-Item -ItemType Directory -Force -Path $Work | Out-Null

  # --- Copias .orig y hashes ---
  $srcStd = Join-Path $Root '01_Software\YSD_300AN\YSD300AN.exe'
  $srcPro = Join-Path $Root '01_Software\300AN\YSD300AN-P2406.exe'
  $dstStd = Join-Path $Work 'YSD300AN.orig.exe'
  $dstPro = Join-Path $Work 'YSD300AN-P2406.orig.exe'

  Copy-Item -LiteralPath $srcStd -Destination $dstStd -Force
  Copy-Item -LiteralPath $srcPro -Destination $dstPro -Force

  "`n== SHA256 (.orig) =="
  Get-FileHash -Algorithm SHA256 -LiteralPath $dstStd,$dstPro |
    Sort-Object Path | Format-Table Hash, Path -Auto

  # --- Copias ASCII-safe (opcional) ---
  if($DoAsciiCopies){
    $Norm = Join-Path $Root 'normalized'
    New-Item -ItemType Directory -Force -Path $Norm | Out-Null

    $copied = 0
    Get-ChildItem -LiteralPath $Root -Recurse -File -Force -ErrorAction SilentlyContinue |
      ForEach-Object {
        $abs = $_.FullName
        $rel = $abs.Substring($Root.Length).TrimStart('\')
        if(-not (Test-Ascii $abs)){
          $relSan = Convert-RelPath-ToAscii $rel
          $dstAbs = Join-Path $Norm $relSan
          $dstAbs = Ensure-Unique $dstAbs
          New-Item -ItemType Directory -Force -Path (Split-Path $dstAbs -Parent) | Out-Null
          Copy-Item -LiteralPath $abs -Destination $dstAbs -Force
          $copied++
          Write-Host "[ASCII] $rel  ->  $relSan"
        }
      }
    Write-Host "[OK] Copias ASCII creadas: $copied  (en $Norm)" -ForegroundColor Green
  }

  # --- Extracción de recursos a .rc (opcional, si está RH) ---
  $rcStd = Join-Path $Work 'YSD300AN.rc'
  $rcPro = Join-Path $Work 'YSD300AN-P2406.rc'
  if($DoExtractRC){
    if(Test-Path -LiteralPath $RH -PathType Leaf){
      & $RH -open $dstStd -save $rcStd -action extract -mask ,,,
      & $RH -open $dstPro -save $rcPro -action extract -mask ,,,
      Write-Host "[OK] Recursos extraídos (.rc) en $Work" -ForegroundColor Green
    } else {
      Write-Host "[WARN] Falta ResourceHacker.exe en $RH — salto extracción" -ForegroundColor Yellow
    }
  }

  # --- Compilación de traducidos (opcional) ---
  if($DoCompileES -and (Test-Path $RH) -and (Test-Path $rcStd) -and (Test-Path $rcPro)){
    $outStd = Join-Path $Work 'YSD300AN.es.exe'
    $outPro = Join-Path $Work 'YSD300AN-P2406.es.exe'
    & $RH -open $dstStd -save $outStd -action compile -res $rcStd
    & $RH -open $dstPro -save $outPro -action compile -res $rcPro

    "`n== SHA256 (.es) =="
    Get-FileHash -Algorithm SHA256 -LiteralPath $outStd,$outPro |
      Sort-Object Path | Format-Table Hash, Path -Auto
    Write-Host "[OK] Copias traducidas generadas en $Work" -ForegroundColor Green
  } elseif($DoCompileES){
    Write-Host "[INFO] Para compilar *.es.exe necesitas ResourceHacker y los .rc editados." -ForegroundColor Cyan
  }

  Write-Host "`n[READY] Flujo i18n completado (TBEA-only, sin Defender)." -ForegroundColor Green
}
catch {
  Write-Host ("[ERROR] {0}" -f $_.Exception.Message) -ForegroundColor Red
  if($_.InvocationInfo){ Write-Host $_.InvocationInfo.PositionMessage }
}