```powershell
<# 
  Mueve entornos locales de Python a una carpeta de cuarentena en el Escritorio.
  - Busca carpetas llamadas: .venv, venv, env, .env (por defecto).
  - Puede incluir también node_modules y .git si lo pides.
  - Toma ownership/ACLs opcionalmente (-TakeOwnership) para evitar Access Denied.
  - Hace DRY-RUN por defecto; usa -Execute para mover de verdad.
  Requisitos: PowerShell 7+, ejecutar como Administrador recomendado.
#>

[CmdletBinding()]
param(
  [string[]] $Roots = @("C:\Users"),
  [string[]] $Names = @(".venv","venv","env",".env"),
  [string[]] $AlsoInclude = @(),           # ej.: @("node_modules",".git")
  [string]   $Desktop   = [Environment]::GetFolderPath('Desktop'),
  [string]   $FolderName = "",
  [switch]   $TakeOwnership,               # toma ownership y concede permisos
  [switch]   $Execute,                     # si no se pasa, hace DRY-RUN
  [int]      $MaxDepth = 10                # límite razonable de profundidad
)

function Write-Info($m){ Write-Host "[INFO]  $m" -ForegroundColor Cyan }
function Write-Warn($m){ Write-Host "[WARN]  $m" -ForegroundColor Yellow }
function Write-Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

# Destino
if ([string]::IsNullOrWhiteSpace($FolderName)) {
  $FolderName = "Quarantine_Venvs_{0:yyyyMMdd_HHmmss}" -f (Get-Date)
}
$DestRoot = Join-Path $Desktop $FolderName
if (-not $Execute) { Write-Warn "DRY-RUN activo. No se moverá nada. Usa -Execute para ejecutar." }

# Construye lista de nombres a buscar
$targets = @($Names + $AlsoInclude) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique

# Enumeración segura (evita el propio destino)
$matches = New-Object System.Collections.Generic.List[object]
foreach ($root in $Roots) {
  if (-not (Test-Path -LiteralPath $root)) { Write-Warn "No existe: $root"; continue }
  Write-Info "Escaneando: $root"
  try {
    $items = Get-ChildItem -LiteralPath $root -Directory -Recurse -Force -ErrorAction SilentlyContinue -Depth $MaxDepth
  } catch {
    $items = Get-ChildItem -LiteralPath $root -Directory -Recurse -Force -ErrorAction SilentlyContinue
  }
  foreach ($d in $items) {
    try {
      # saltar el propio destino
      if ($d.FullName -like "$DestRoot*") { continue }
      $leaf = $d.Name
      if ($targets -contains $leaf) {
        $matches.Add($d)
      }
    } catch { }
  }
}

if ($matches.Count -eq 0) { Write-Info "No se encontraron carpetas objetivo."; return }

# Funciones de tamaño y permisos
function Get-DirSizeBytes([string]$p) {
  try {
    (Get-ChildItem -LiteralPath $p -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object -Sum Length).Sum
  } catch { 0 }
}

function Ensure-Access([string]$p) {
  if (-not $TakeOwnership) { return }
  Write-Info "Tomando ownership/ACL: $p"
  try { & takeown.exe /F "$p" /R /D Y | Out-Null } catch { }
  try { & icacls.exe "$p" /grant Administrators:(OI)(CI)F /T /C | Out-Null } catch { }
}

# Destino único por carpeta (evita colisiones)
function Make-Dest([string]$src) {
  $safe = ($src -replace "[:\\\/]", "_")
  $dst  = Join-Path $DestRoot $safe
  if (-not (Test-Path -LiteralPath $dst)) { New-Item -ItemType Directory -Path $dst | Out-Null }
  return $dst
}

# Robocopy mover (más robusto que Move-Item para árboles grandes)
function Move-Tree([string]$src, [string]$dst) {
  if (-not (Test-Path -LiteralPath $dst)) { New-Item -ItemType Directory -Path $dst | Out-Null }
  $args = @("$src", "$dst", "*", "/MOVE", "/E", "/COPY:DAT", "/R:1", "/W:1", "/NFL", "/NDL", "/NP", "/XJ")
  $null = & robocopy @args
  $code = $LASTEXITCODE
  return $code
}

# Prepara destino (en DRY-RUN igual lo creamos para mostrar ruta)
if (-not (Test-Path -LiteralPath $DestRoot)) { New-Item -ItemType Directory -Path $DestRoot | Out-Null }

# Manifiesto
$manifest = New-Object System.Collections.Generic.List[object]
$totalSize = 0
foreach ($m in $matches) {
  $src = $m.FullName
  $size = Get-DirSizeBytes $src
  $totalSize += [int64]($size)
  $dst = Make-Dest $src

  if ($Execute) {
    try {
      Ensure-Access $src
      $rc = Move-Tree -src $src -dst $dst
      Write-Host "[MOVIDO] $src  =>  $dst  (rc=$rc)"
      $manifest.Add([pscustomobject]@{
        moved_from = $src
        moved_to   = $dst
        bytes      = $size
        moved_at   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
      }) | Out-Null
    } catch {
      Write-Err "No se pudo mover: $src  -> $dst  ($($_.Exception.Message))"
    }
  } else {
    Write-Host "[DRY-RUN] mover: $src  =>  $dst  (size=$([math]::Round($size/1MB,2)) MB)"
  }
}

# Guardar manifiesto si se ejecutó
if ($Execute) {
  $csv = Join-Path $DestRoot "manifest_venv_moves.csv"
  $manifest | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding utf8
  Write-Info "Manifiesto: $csv"
}
Write-Info ("Total aproximado: {0:N2} GB" -f ($totalSize/1GB))
Write-Info ("Destino: $DestRoot")
if (-not $Execute) { Write-Warn "Fue simulación. Para ejecutar, añade -Execute." }
```