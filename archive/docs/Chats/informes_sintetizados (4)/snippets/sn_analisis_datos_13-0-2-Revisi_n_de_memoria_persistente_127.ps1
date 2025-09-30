#requires -Version 7
# === Run in TBEA with temporary Defender exclusions (scoped & reverted) ===
Set-StrictMode -Version Latest; $ErrorActionPreference = 'Stop'

# Check admin
$me = [Security.Principal.WindowsIdentity]::GetCurrent()
$adm = (New-Object Security.Principal.WindowsPrincipal $me).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if(-not $adm){ throw "Ejecuta PowerShell como Administrador para modificar exclusiones de Defender." }

$root  = "$env:USERPROFILE\Desktop\TBEA"
$work  = Join-Path $root 'i18n_work'
$tools = Join-Path $root 'tools'
$rh    = Join-Path $tools 'ResourceHacker.exe'

# Targets for temporary exclusions (only inside TBEA)
$pathExcl   = @($root, $work, $tools | Where-Object { $_ }) | Select-Object -Unique
$procExcl   = @()
if(Test-Path -LiteralPath $rh -PathType Leaf){ $procExcl += $rh }

# Helpers to diff current prefs vs desired
function Get-CurrentExclusions {
  try { Get-MpPreference } catch { $null }
}
function Add-TmpExclusions {
  param([string[]]$Paths,[string[]]$Procs)
  $added = [ordered]@{Paths=@(); Procs=@()}
  $prefs = Get-CurrentExclusions
  if(-not $prefs){ throw "No se pudo leer preferencias de Defender (¿política de la organización / Tamper Protection?)." }

  $missingPaths = @()
  foreach($p in $Paths){
    if([string]::IsNullOrWhiteSpace($p)){ continue }
    if(-not ($prefs.ExclusionPath -contains $p)){ $missingPaths += $p }
  }
  if($missingPaths.Count){
    Add-MpPreference -ExclusionPath $missingPaths
    $added.Paths += $missingPaths
  }

  $missingProcs = @()
  foreach($pr in $Procs){
    if([string]::IsNullOrWhiteSpace($pr)){ continue }
    if(-not ($prefs.ExclusionProcess -contains $pr)){ $missingProcs += $pr }
  }
  if($missingProcs.Count){
    Add-MpPreference -ExclusionProcess $missingProcs
    $added.Procs += $missingProcs
  }
  return $added
}
function Remove-TmpExclusions {
  param([hashtable]$Added)
  if($Added -and $Added.Paths){
    foreach($p in $Added.Paths){ try { Remove-MpPreference -ExclusionPath $p } catch {} }
  }
  if($Added -and $Added.Procs){
    foreach($pr in $Added.Procs){ try { Remove-MpPreference -ExclusionProcess $pr } catch {} }
  }
}

# === MAIN ===
$added = $null
try{
  Write-Host "Creando exclusiones temporales (acotadas a TBEA)..." -ForegroundColor Cyan
  $added = Add-TmpExclusions -Paths $pathExcl -Procs $procExcl
  Write-Host ("[OK] Paths añadidos: {0}" -f (($added.Paths -join '; '))) -ForegroundColor Green
  Write-Host ("[OK] Procesos añadidos: {0}" -f (($added.Procs -join '; '))) -ForegroundColor Green

  # ---------- TU OPERACIÓN VA AQUÍ ----------
  # Ejemplo mínimo seguro: preparar copias .orig y hashes
  if(-not (Test-Path -LiteralPath $work)){ New-Item -ItemType Directory -Force -Path $work | Out-Null }
  Copy-Item (Join-Path $root '01_Software\YSD_300AN\YSD300AN.exe')           (Join-Path $work 'YSD300AN.orig.exe') -Force
  Copy-Item (Join-Path $root '01_Software\300AN\YSD300AN-P2406.exe')         (Join-Path $work 'YSD300AN-P2406.orig.exe') -Force
  Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $work 'YSD300AN.orig.exe'),(Join-Path $work 'YSD300AN-P2406.orig.exe') |
    Sort-Object Path | Format-Table Hash, Path -Auto
  # Si colocas ResourceHacker.exe en TBEA\tools, descomenta estas dos líneas para extraer .rc:
  # & $rh -open (Join-Path $work 'YSD300AN.orig.exe')         -save (Join-Path $work 'YSD300AN.rc')         -action extract -mask ,,,
  # & $rh -open (Join-Path $work 'YSD300AN-P2406.orig.exe')   -save (Join-Path $work 'YSD300AN-P2406.rc')   -action extract -mask ,,,
  # ---------- FIN DE TU OPERACIÓN ----------
}
catch{
  Write-Host ("[ERROR] {0}" -f $_.Exception.Message) -ForegroundColor Red
  if($_.InvocationInfo){ Write-Host $_.InvocationInfo.PositionMessage }
}
finally{
  Write-Host "Revirtiendo exclusiones temporales..." -ForegroundColor Yellow
  Remove-TmpExclusions -Added $added
  Write-Host "[OK] Exclusiones revertidas." -ForegroundColor Green
}