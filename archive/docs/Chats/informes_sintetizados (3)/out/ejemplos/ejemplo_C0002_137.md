```powershell
<# 
Reorganiza 01_Software:
- Crea: Binarios, Config, Datos/{Exportes,Temporales,DB}, Recursos/{Icons,Images}, Docs
- Mapea por extensión:
  exe → Binarios
  ini → Config
  ysd → Datos/Exportes
  dcy → Datos/Temporales
  edb → Datos/DB
  ico → Recursos/Icons
  bmp → Recursos/Images
  dll, ocx → Binarios/Libs
  cfg, config → Config
  log → Datos/Temporales/Logs
  txt → Docs
- Otros → Docs/Misc (si -IncludeUnknown)
- Borra directorios antiguos que queden vacíos (no toca la nueva estructura).
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
  [Parameter(Position=0)]
  [string]$Root = (Get-Location).Path,

  # Mover extensiones desconocidas a Docs\Misc para poder vaciar y borrar directorios viejos
  [switch]$IncludeUnknown = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Normaliza ruta
$Root = (Resolve-Path -LiteralPath $Root).Path

# Destinos
$Dest = @{
  'exe'    = Join-Path $Root 'Binarios'
  'dll'    = Join-Path $Root 'Binarios\Libs'
  'ocx'    = Join-Path $Root 'Binarios\Libs'
  'ini'    = Join-Path $Root 'Config'
  'cfg'    = Join-Path $Root 'Config'
  'config' = Join-Path $Root 'Config'
  'ysd'    = Join-Path $Root 'Datos\Exportes'
  'dcy'    = Join-Path $Root 'Datos\Temporales'
  'log'    = Join-Path $Root 'Datos\Temporales\Logs'
  'edb'    = Join-Path $Root 'Datos\DB'
  'ico'    = Join-Path $Root 'Recursos\Icons'
  'bmp'    = Join-Path $Root 'Recursos\Images'
  'txt'    = Join-Path $Root 'Docs'
}

$KeepTop = @(
  (Join-Path $Root 'Binarios'),
  (Join-Path $Root 'Config'),
  (Join-Path $Root 'Datos'),
  (Join-Path $Root 'Datos\Exportes'),
  (Join-Path $Root 'Datos\Temporales'),
  (Join-Path $Root 'Datos\DB'),
  (Join-Path $Root 'Datos\Temporales\Logs'),
  (Join-Path $Root 'Recursos'),
  (Join-Path $Root 'Recursos\Icons'),
  (Join-Path $Root 'Recursos\Images'),
  (Join-Path $Root 'Docs')
)

if ($IncludeUnknown) {
  $UnknownDest = Join-Path $Root 'Docs\Misc'
  $KeepTop += $UnknownDest
}

# Crea estructura
$KeepTop | ForEach-Object {
  if ($PSCmdlet.ShouldProcess($_, 'Crear carpeta')) {
    New-Item -ItemType Directory -Path $_ -Force | Out-Null
  }
}

function Get-UniquePath {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return $Path }
  $dir = Split-Path -Parent $Path
  $base = [System.IO.Path]::GetFileNameWithoutExtension($Path)
  $ext = [System.IO.Path]::GetExtension($Path)
  for ($i=1; $i -lt 1000; $i++) {
    $candidate = Join-Path $dir ("{0} ({1}){2}" -f $base, $i, $ext)
    if (-not (Test-Path -LiteralPath $candidate)) { return $candidate }
  }
  throw "No se pudo generar un nombre único para: $Path"
}

# Determina si una ruta está dentro de la nueva estructura
function In-NewStructure {
  param([string]$FullPath)
  foreach ($k in $KeepTop) {
    if ($FullPath.TrimEnd('\') -like ($k.TrimEnd('\') + '*')) { return $true }
  }
  return $false
}

# Mueve archivos
$files = Get-ChildItem -LiteralPath $Root -File -Recurse
$movidos = @()
foreach ($f in $files) {
  # omite los ya dentro de la nueva estructura
  if (In-NewStructure -FullPath $f.FullName) { continue }

  $ext = ($f.Extension.TrimStart('.')).ToLowerInvariant()
  $targetDir = $null
  if ($Dest.ContainsKey($ext)) {
    $targetDir = $Dest[$ext]
  } elseif ($IncludeUnknown) {
    $targetDir = $UnknownDest
  } else {
    continue
  }

  $targetPath = Join-Path $targetDir $f.Name
  $targetPath = Get-UniquePath -Path $targetPath

  if ($PSCmdlet.ShouldProcess($f.FullName, "Mover a '$targetPath'")) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Move-Item -LiteralPath $f.FullName -Destination $targetPath -Force
    $movidos += [pscustomobject]@{
      Source      = $f.FullName
      Destination = $targetPath
      Ext         = $ext
    }
  }
}

# Borra directorios viejos que quedaron vacíos
# Recorre de hojas a raíz para poder vaciar progresivamente
$allDirs = Get-ChildItem -LiteralPath $Root -Directory -Recurse |
  Sort-Object { $_.FullName.Length } -Descending

foreach ($d in $allDirs) {
  # Mantén la nueva estructura
  if (In-NewStructure -FullPath $d.FullName) { continue }

  # borra solo si ya está vacío (sin archivos)
  $hasFiles = (Get-ChildItem -LiteralPath $d.FullName -File -Recurse -Force -ErrorAction SilentlyContinue | Select-Object -First 1)
  if ($null -eq $hasFiles) {
    if ($PSCmdlet.ShouldProcess($d.FullName, 'Eliminar directorio vacío')) {
      Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
}

# Resumen
$summary = $movidos | Group-Object Ext | Sort-Object Count -Descending | ForEach-Object {
  '{0}: {1} archivo(s)' -f $_.Name, $_.Count
}
"Movidos: $($movidos.Count)`n$($summary -join [Environment]::NewLine)"
```