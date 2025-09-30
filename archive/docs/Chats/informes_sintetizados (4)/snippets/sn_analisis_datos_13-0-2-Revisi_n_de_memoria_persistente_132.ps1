  # --- Extracción de recursos a .rc (opcional, si está RH) ---
  $rcStd = Join-Path $Work 'YSD300AN.rc'
  $rcPro = Join-Path $Work 'YSD300AN-P2406.rc'
  if($DoExtractRC){
    if(Test-Path -LiteralPath $RH -PathType Leaf){
      & $RH -open $dstStd -save $rcStd -action extract -mask *
      & $RH -open $dstPro -save $rcPro -action extract -mask *
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