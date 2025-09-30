#requires -Version 7
# === TBEA i18n runner (solo dentro de TBEA, con precheck de Defender) ===
Set-StrictMode -Version Latest; $ErrorActionPreference = 'Stop'

# --- Config ---
$root  = "$env:USERPROFILE\Desktop\TBEA"
$work  = Join-Path $root 'i18n_work'
$tools = Join-Path $root 'tools'
$rh    = Join-Path $tools 'ResourceHacker.exe'  # opcional (para extraer/compilar recursos)

# --- Pre-flight: Defender realtime (solo lectura) ---
try {
  $rt = (Get-MpComputerStatus -ErrorAction Stop).RealTimeProtectionEnabled
} catch {
  # En algunas políticas corporativas este cmdlet está bloqueado; no abortes, solo avisa
  $rt = $null
  Write-Host "[WARN] No se pudo leer estado de Defender (política/Tamper). Continuo bajo tu responsabilidad."
}
if ($rt -eq $true) {
  Write-Host "[ERROR] Protección en tiempo real de Defender está ACTIVA." -ForegroundColor Red
  Write-Host "Desactívala MANUALMENTE (Seguridad de Windows → Protección antivirus y contra amenazas → Configuración de antivirus de Microsoft Defender → Protección en tiempo real) y vuelve a ejecutar este bloque." -ForegroundColor Yellow
  throw "Defender en tiempo real activo"
}

# --- Operación principal (TBEA-only) ---
# 1) Área de trabajo
if (-not (Test-Path -LiteralPath $work)) { New-Item -ItemType Directory -Force -Path $work | Out-Null }

# 2) Copias .orig (no tocamos originales)
$srcStd = Join-Path $root '01_Software\YSD_300AN\YSD300AN.exe'
$srcPro = Join-Path $root '01_Software\300AN\YSD300AN-P2406.exe'
$dstStd = Join-Path $work 'YSD300AN.orig.exe'
$dstPro = Join-Path $work 'YSD300AN-P2406.orig.exe'

Copy-Item -LiteralPath $srcStd -Destination $dstStd -Force
Copy-Item -LiteralPath $srcPro -Destination $dstPro -Force

"`n== SHA256 (copias .orig) =="
Get-FileHash -Algorithm SHA256 -LiteralPath $dstStd,$dstPro | Sort-Object Path | Format-Table Hash, Path -Auto

# 3) Extracción de recursos a .rc (si está ResourceHacker.exe en TBEA\tools)
if (Test-Path -LiteralPath $rh -PathType Leaf) {
  & $rh -open $dstStd -save (Join-Path $work 'YSD300AN.rc')         -action extract -mask ,,,
  & $rh -open $dstPro -save (Join-Path $work 'YSD300AN-P2406.rc')   -action extract -mask ,,,
  Write-Host "[OK] Recursos extraídos a .rc en: $work" -ForegroundColor Green
} else {
  Write-Host "[WARN] Falta ResourceHacker.exe en $rh — me salto extracción/compilación" -ForegroundColor Yellow
}

# 4) Compilación de traducidos (si ya editaste .rc y está RH)
$rcStd = Join-Path $work 'YSD300AN.rc'
$rcPro = Join-Path $work 'YSD300AN-P2406.rc'
if (Test-Path $rh -PathType Leaf -and (Test-Path $rcStd) -and (Test-Path $rcPro)) {
  & $rh -open $dstStd -save (Join-Path $work 'YSD300AN.es.exe')         -action compile -res $rcStd
  & $rh -open $dstPro -save (Join-Path $work 'YSD300AN-P2406.es.exe')   -action compile -res $rcPro
  "`n== SHA256 (traducidos) =="
  Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $work 'YSD300AN.es.exe'),(Join-Path $work 'YSD300AN-P2406.es.exe') |
    Sort-Object Path | Format-Table Hash, Path -Auto
  Write-Host "[OK] Copias traducidas generadas en $work" -ForegroundColor Green
} else {
  Write-Host "[INFO] Traduce primero los .rc y/o coloca ResourceHacker.exe en TBEA\tools para compilar .es.exe" -ForegroundColor Cyan
}

Write-Host "`n[READY] Flujo i18n completado (sin tocar fuera de TBEA)." -ForegroundColor Green