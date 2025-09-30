# ---------------------------------------
# Instalación y prueba YSD-300AN
# (con OCX + ResourceHacker opcional)
# ---------------------------------------

$ErrorActionPreference = 'Stop'
$TargetRoot = 'C:\YSD300A'
$NeedOCX    = @('COMDLG32.OCX','MSCOMCTL.OCX','MSCOMM32.OCX','MSFLXGRD.OCX','MSWINSCK.OCX','RICHTX32.OCX','TABCTL32.OCX')
$SysWOW64   = Join-Path $env:WINDIR 'SysWOW64'
$Regsvr32   = Join-Path $SysWOW64  'regsvr32.exe'
$Work       = 'C:\Users\VictorFabianVeraVill\Desktop\TBEA\i18n_work'
$RH         = 'C:\Users\VictorFabianVeraVill\Desktop\TBEA\tools\ResourceHacker.exe'
$DoExtractRC = $true
$DoCompileES = $false   # pon $true si ya editaste los .rc

function Assert-Admin {
  $id=[Security.Principal.WindowsIdentity]::GetCurrent()
  $p=[Security.Principal.WindowsPrincipal]::new($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    throw "Ejecuta PowerShell como Administrador."
  }
}

function Find-AppFolder {
  $hits = Get-ChildItem -Path 'C:\' -Recurse -File -Filter 'YSD300AN.exe' -ErrorAction SilentlyContinue
  if (-not $hits) { throw 'No se encontró YSD300AN.exe en C:\' }
  $scored = foreach($h in $hits){
    $score=0
    if ($h.FullName -match 'YSD-300AN'){ $score+=5 }
    if ($h.FullName -match '上位机|300AN|YSD'){ $score+=3 }
    if ($h.DirectoryName -match 'Desktop|Escritorio|Software'){ $score+=2 }
    [pscustomobject]@{ Path=$h.DirectoryName; Score=$score; Date=$h.LastWriteTimeUtc }
  }
  $scored | Sort-Object Score,Date -Descending | Select-Object -First 1 -ExpandProperty Path
}

function Detect-ComPort {
  try {
    $sp=Get-CimInstance Win32_SerialPort -ErrorAction Stop
    $usb=$sp | Where-Object { $_.PNPDeviceID -match 'USB' -or $_.Name -match '(USB|CH340|CH341|Prolific|PL2303|HL-340|Silicon Labs)' }
    $cand=if($usb){$usb[0]} else {($sp|Sort-Object DeviceID)[0]}
    if($cand){ return [int](($cand.DeviceID -replace '[^\d]','')) }
  } catch {}
  return 6
}

function Write-Ini {
  param([string]$Path,[int]$Port)
@"
[comset]
port=$Port
btr=9600
sbit=1
jyw=N
bytnum=8
"@ | Set-Content -LiteralPath $Path -Encoding ASCII
}

function Search-OcxInC {
  param([string]$Name)
  $roots=@(
    (Join-Path $env:WINDIR 'SysWOW64'),
    (Join-Path $env:WINDIR 'System32'),
    (Join-Path $env:WINDIR 'WinSxS'),
    'C:\Program Files (x86)',
    'C:\Program Files',
    'C:\Users'
  ) | Where-Object { Test-Path $_ }
  foreach($r in $roots){
    $hit=Get-ChildItem -Path $r -Recurse -File -Filter $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if($hit){ return $hit.FullName }
  }
  return $null
}

function Register-Ocx {
  param([string]$Name,[string]$FoundPath)
  $dst=Join-Path $SysWOW64 $Name
  if($FoundPath){
    if($FoundPath -ne $dst){ try{ Copy-Item $FoundPath $dst -Force }catch{} }
  } elseif(-not(Test-Path $dst)){
    return [pscustomobject]@{ Componente=$Name; Estado='FALTA'; Origen=''; Destino='' }
  }
  & $Regsvr32 /s $dst
  [pscustomobject]@{ Componente=$Name; Estado='REGISTRADO'; Origen=($FoundPath ?? $dst); Destino=$dst }
}

function Unblock-Tree($Root){
  Get-ChildItem -LiteralPath $Root -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    Unblock-File -LiteralPath $_.FullName -ErrorAction SilentlyContinue
  }
}

# -------- MAIN --------
Assert-Admin

# 1) Copiar carpeta origen
$src=Find-AppFolder
New-Item -ItemType Directory -Force -Path $TargetRoot | Out-Null
$null=robocopy $src $TargetRoot /MIR /NFL /NDL /NJH /NJS /NP
$dstStd=Join-Path $TargetRoot 'YSD300AN.exe'
$dstPro=Join-Path $TargetRoot 'YSD300AN-P2406.exe'

# 2) Crear dccsys.ini
$com=Detect-ComPort
Write-Ini -Path (Join-Path $TargetRoot 'dccsys.ini') -Port $com

# 3) Registrar OCX
$ocxReport=@()
foreach($n in $NeedOCX){
  $found=Search-OcxInC -Name $n
  $ocxReport+=Register-Ocx -Name $n -FoundPath $found
}
Unblock-Tree $TargetRoot

# 4) Extracción RC opcional
$rcStd=Join-Path $Work 'YSD300AN.rc'
$rcPro=Join-Path $Work 'YSD300AN-P2406.rc'
if($DoExtractRC){
  if(Test-Path $RH){
    & $RH -open $dstStd -save $rcStd -action extract -mask *
    & $RH -open $dstPro -save $rcPro -action extract -mask *
    Write-Host "[OK] Recursos extraídos a $Work" -ForegroundColor Green
  } else {
    Write-Host "[WARN] Falta ResourceHacker.exe — no se extrajeron .rc" -ForegroundColor Yellow
  }
}

# 5) Compilación opcional
if($DoCompileES -and (Test-Path $RH) -and (Test-Path $rcStd) -and (Test-Path $rcPro)){
  $outStd=Join-Path $Work 'YSD300AN.es.exe'
  $outPro=Join-Path $Work 'YSD300AN-P2406.es.exe'
  & $RH -open $dstStd -save $outStd -action compile -res $rcStd
  & $RH -open $dstPro -save $outPro -action compile -res $rcPro
  Get-FileHash -Algorithm SHA256 $outStd,$outPro | Format-Table Hash,Path -Auto
}

# 6) Reporte final
"`nDestino : $TargetRoot"
"COM      : $com"
"OCX:"
$ocxReport | ForEach-Object { "{0,-12} {1,-12} {2}" -f $_.Componente,$_.Estado,$_.Destino }