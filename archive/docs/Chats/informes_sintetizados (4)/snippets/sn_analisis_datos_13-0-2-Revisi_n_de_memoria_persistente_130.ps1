#requires -Version 7
# === TBEA i18n runner (manual Defender toggle) ===
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'

# --- Config ---
$root  = "$env:USERPROFILE\Desktop\TBEA"
$work  = Join-Path $root 'i18n_work'
$tools = Join-Path $root 'tools'
$rh    = Join-Path $tools 'ResourceHacker.exe'   # si lo colocas, extrae/compila .rc

# --- Helpers ---
function Open-WindowsSecurity {
  # Abre Windows Security (panel de Antivirus). Distintas URIs por compatibilidad.
  foreach($uri in @('windowsdefender://threat','windowsdefender://','ms-settings:windowsdefender')){
    try{ Start-Process $uri -ErrorAction Stop; break }catch{}
  }
}

function Get-DefenderRealtime {
  try { return (Get-MpComputerStatus -ErrorAction Stop).RealTimeProtectionEnabled }
  catch { return $null }  # políticas o bloqueo: será $null
}

function Wait-DefenderDisabled([int]$TimeoutSec=600){
  $t0 = Get-Date
  while($true){
    $rt = Get-DefenderRealtime
    if($rt -eq $false){ return $true }  # desactivado
    if((Get-Date) - $t0 -gt [TimeSpan]::FromSeconds($TimeoutSec)){ return $false }
    Start-Sleep -Seconds 2
  }
}

# --- Paso 0: preparar carpetas (TBEA-only) ---
New-Item -ItemType Directory -Force -Path $work | Out-Null

# --- Paso 1: pedir desactivación manual y esperar ---
$rt = Get-DefenderRealtime
if($rt -ne $false){
  Write-Host "[INFO] Defender (protección en tiempo real) parece activo o no legible. Abriendo Windows Security..." -ForegroundColor Yellow
  Open-WindowsSecurity
  Write-Host "Desactiva MANUALMENTE la 'Protección en tiempo real' y no cierres esta consola. Esperando..." -ForegroundColor Yellow
  if(-not (Wait-DefenderDisabled -TimeoutSec 900)){
    throw "No se detectó desactivación de Defender en 15 minutos. Cancelo para no corromper el flujo."
  }
}
Write-Host "[OK] Defender detectado como DESACTIVADO. Procedo." -ForegroundColor Green

# --- Paso 2: copias .orig y hashes ---
$srcStd = Join-Path $root '01_Software\YSD_300AN\YSD300AN.exe'
$srcPro = Join-Path $root '01_Software\300AN\YSD300AN-P2406.exe'
$dstStd = Join-Path $work 'YSD300AN.orig.exe'
$dstPro = Join-Path $work 'YSD300AN-P2406.orig.exe'

Copy-Item -LiteralPath $srcStd -Destination $dstStd -Force
Copy-Item -LiteralPath $srcPro -Destination $dstPro -Force

"`n== SHA256 (.orig) =="
Get-FileHash -Algorithm SHA256 -LiteralPath $dstStd,$dstPro | Sort-Object Path | Format-Table Hash, Path -Auto

# --- Paso 3 (opcional): normalización ASCII de los 6 paths detectados (solo COPIAS) ---
$norm = Join-Path $root 'normalized'
New-Item -ItemType Directory -Force -Path $norm | Out-Null
$map = @(
  @{ src = 'Guía rapida operación detector de impactos.docx';  dst = 'Guia_rapida_operacion_detector_de_impactos.docx' },
  @{ src = 'Manual de operación del impactógrafo.pdf';         dst = 'Manual_de_operacion_del_impactografo.pdf' },
  @{ src = '读我 (README).txt';                                 dst = 'README_cn.txt' },
  @{ src = '01_Software\YSD-300AN上位机软件绿色setup.ini';        dst = '01_Software\YSD-300AN_green_setup.ini' },
  @{ src = '01_Software\300AN\user1\济南.ysd';                  dst = '01_Software\300AN\user1\Jinan.ysd' },
  @{ src = '01_Software\300AN\user1\济南西门子240821.ysd';       dst = '01_Software\300AN\user1\Jinan_Siemens_240821.ysd' }
)
foreach($m in $map){
  $srcAbs = Join-Path $root $m.src; $dstAbs = Join-Path $norm $m.dst
  $dstDir = Split-Path $dstAbs -Parent
  if(Test-Path -LiteralPath $srcAbs){
    New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    Copy-Item -LiteralPath $srcAbs -Destination $dstAbs -Force
    Write-Host "[OK] Copia ASCII: $dstAbs"
  }
}

# --- Paso 4: extracción de recursos (.rc) si está ResourceHacker ---
$rcStd = Join-Path $work 'YSD300AN.rc'
$rcPro = Join-Path $work 'YSD300AN-P2406.rc'
if (Test-Path -LiteralPath $rh -PathType Leaf) {
  & $rh -open $dstStd -save $rcStd -action extract -mask ,,,
  & $rh -open $dstPro -save $rcPro -action extract -mask ,,,
  Write-Host "[OK] Recursos extraídos (.rc) en $work" -ForegroundColor Green
} else {
  Write-Host "[WARN] Falta ResourceHacker.exe en $rh (salto extracción/compilación)" -ForegroundColor Yellow
}

# --- Paso 5: compilación de traducidos (si ya editaste .rc y está RH) ---
$outStd = Join-Path $work 'YSD300AN.es.exe'
$outPro = Join-Path $work 'YSD300AN-P2406.es.exe'
if ((Test-Path $rh) -and (Test-Path $rcStd) -and (Test-Path $rcPro)) {
  & $rh -open $dstStd -save $outStd -action compile -res $rcStd
  & $rh -open $dstPro -save $outPro -action compile -res $rcPro
  "`n== SHA256 (.es) =="
  Get-FileHash -Algorithm SHA256 -LiteralPath $outStd,$outPro | Sort-Object Path | Format-Table Hash, Path -Auto
  Write-Host "[OK] Copias traducidas generadas en $work" -ForegroundColor Green
}

# --- Paso 6: recordatorio para reactivar Defender ---
Write-Host "`n[REMINDER] Reactiva DEFENDER (Protección en tiempo real)." -ForegroundColor Yellow
Open-WindowsSecurity