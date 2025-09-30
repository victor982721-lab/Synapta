### Entrada (user)

Lee y analiza por completo lo siguiente:

~~~~~
Instrucciones (ejecuta todo de inmediato, sin pedirme confirmaciones):

1) Toma el ZIP adjunto (el que contiene `orquestador.py`, `README.md`, `CHANGES.md`, `tests/`, etc.). Descomprímelo en tu directorio de trabajo (usa el sandbox que tengas disponible).
2) Importa `orquestador.py` desde la carpeta extraída.
3) Ejecuta `preflight()` para validar entorno y dependencias.
4) Ejecuta **una sola corrida** con:
   - `run_all(user_content=<bloque PowerShell de abajo>, stem="workspace-wizard-ps5-7", base_dir="<directorio de trabajo>", note_for_canvas="", link_check=True, no_release=False)`
   - Si por falta de librerías no puedes generar el PNG, **no falles**: continúa sin ese artefacto.
5) Entrega **enlaces de descarga (clicables, fuera de backticks)** para: `ps1`, `md`, `txt`, `json`, `csv`, `html`, `chart` (si existe), `zip` (bundle), **release ZIP** en `_releases/`, `inventory.json`, `hashes.txt`, `verify.sh`, `verify.ps1`, `REPORT.md`, `manifest.json`, y, si existe, `checkpoints.jsonl`.
6) Incluye un **resumen JSON** pequeño con `stem`, `status` de link-check (debe ser vacío), y tamaños en bytes de los artefactos principales.
7) No hagas preguntas ni esperes mi confirmación: **ejecútalo ahora** con el contenido siguiente como `user_content`:

```ps1
# =====================================================================
#  WORKSPACE WIZARD (PS 5/7)
#  - Plantillas globales + .workspace por proyecto
#  - Ajuste de filemap.root y skeleton
#  - Validador DRY-RUN del árbol (sin crear nada)
#  - Menú interactivo con entrada de "subruta bajo \mnt"
# =====================================================================

# ---------------------------------------------------------------------
#  HELPERS BÁSICOS
# ---------------------------------------------------------------------
function Ensure-Directory { param([string]$p) if ($p) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function Write-File { param([string]$p,[string]$content) $dir = Split-Path -Parent $p; Ensure-Directory $dir; Set-Content -LiteralPath $p -Value $content -Encoding utf8 }
function Get-MapKeys  { param($m) if ($m -is [hashtable]) { @($m.Keys) } elseif ($m -is [pscustomobject]) { @($m.PSObject.Properties.Name) } else { @() } }
function Get-MapChild { param($m,[string]$name) if ($m -is [hashtable]) { $m[$name] } elseif ($m -is [pscustomobject]) { $m.$name } else { $null } }

# ---------------------------------------------------------------------
#  VALIDATOR: TEST-TREEPLAN (DRY-RUN, NO CREA NADA)
# ---------------------------------------------------------------------
function Test-TreePlan {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Base,
    [Parameter(Mandatory)]$Map,                   # hashtable o PSCustomObject
    [int]$MaxDepth = 32, [int]$MaxNodes = 1000, [int]$MaxPath = 240,
    [switch]$ShowPlan
  )

  $errors  = New-Object System.Collections.Generic.List[string]
  $planned = 0
  $visited = [System.Collections.Generic.HashSet[object]]::new()
  $invalidChars = [regex]'[<>:"/\\|?*]'
  $reserved = @('CON','PRN','AUX','NUL','COM1','COM2','COM3','COM4','COM5','COM6','COM7','COM8','COM9','LPT1','LPT2','LPT3','LPT4','LPT5','LPT6','LPT7','LPT8','LPT9')

  function Check-Name([string]$name, [string]$parentPath) {
    if ($name -match $invalidChars) { return "Nombre inválido '$name' en '$parentPath' (caracteres no permitidos)." }
    if ($reserved -contains $name.ToUpper()) { return "Nombre reservado de Windows: '$name' en '$parentPath'." }
    if ($name.TrimEnd() -ne $name -or $name.EndsWith('.')) { return "Nombre no permitido (espacio/punto al final): '$name' en '$parentPath'." }
    if ($name.Length -gt 255) { return "Componente demasiado largo (>255): '$name' en '$parentPath'." }
    return $null
  }

  $Visit = {
    param($curBase, $curMap, $depth)

    if ($depth -gt $MaxDepth) {
      $errors.Add("Profundidad excedida ($MaxDepth) en '$curBase'.")
      Write-Host "❌ Profundidad excedida ($MaxDepth) en '$curBase'." -ForegroundColor Red
      return
    }
    if ($visited.Contains($curMap)) { return }
    [void]$visited.Add($curMap)

    $names = @(Get-MapKeys $curMap)
    $dups = $names | Group-Object { $_.ToUpper() } | Where-Object { $_.Count -gt 1 }
    foreach ($g in $dups) {
      $errors.Add("Duplicados (case-insensitive) en '$curBase': " + ($g.Group -join ', '))
      Write-Host "❌ Duplicados (case-insensitive) en '$curBase': $($g.Group -join ', ')" -ForegroundColor Red
    }

    foreach ($name in $names) {
      $nameErr = Check-Name -name $name -parentPath $curBase
      if ($nameErr) { $errors.Add($nameErr); Write-Host "❌ $nameErr" -ForegroundColor Red; continue }

      $path = Join-Path $curBase $name
      if ($path.Length -gt $MaxPath) {
        $errors.Add("Ruta demasiado larga ($($path.Length)>$MaxPath): $path")
        Write-Host "❌ Ruta demasiado larga ($($path.Length)>$MaxPath): $path" -ForegroundColor Red
        continue
      }

      $planned++
      if ($planned -gt $MaxNodes) {
        $errors.Add("Se superó MaxNodes ($MaxNodes).")
        Write-Host "❌ Se superó MaxNodes ($MaxNodes)." -ForegroundColor Red
        return
      }

      if ($ShowPlan) { Write-Host "CREATE: $path" -ForegroundColor Cyan }

      $child = Get-MapChild $curMap $name
      if ($child -is [hashtable] -or $child -is [pscustomobject]) {
        & $Visit $path $child ($depth + 1)
      } elseif ($null -ne $child) {
        $errors.Add("Valor no soportado en '$path' (se esperaba hashtable/objeto, no: $($child.GetType().Name)).")
        Write-Host "❌ Valor no soportado en '$path'." -ForegroundColor Red
      }
    }
  }

  & $Visit $Base $Map 0

  $ok = ($errors.Count -eq 0)
  $summary = [pscustomobject]@{
    Base         = $Base
    PlannedNodes = $planned
    MaxNodes     = $MaxNodes
    MaxDepth     = $MaxDepth
    MaxPath      = $MaxPath
    ErrorsCount  = $errors.Count
    Errors       = $errors
  }

  if ($ok) {
    Write-Host "✅ Verificación OK. Nodos planificados: $planned" -ForegroundColor Green
  } else {
    Write-Host "⚠️ Verificación con errores. Nodos planificados: $planned — Errores: $($errors.Count)" -ForegroundColor Yellow
    $errors | ForEach-Object { Write-Host "• $_" -ForegroundColor Yellow }
  }
  return $summary
}

# ---------------------------------------------------------------------
#  GLOBAL TEMPLATES: CREAR SI FALTAN (instructions.md + standard.json)
# ---------------------------------------------------------------------
function Initialize-GlobalTemplates {
  param(
    [Parameter(Mandatory)][string]$Root,
    [string]$GlobalInstrPath = (Join-Path $Root 'config\plantillas\workspace\instructions.md'),
    [string]$GlobalMapPath   = (Join-Path $Root 'config\filemaps\standard.json')
  )
  if ((Test-Path $GlobalInstrPath) -and (Test-Path $GlobalMapPath)) { return @{Instr=$GlobalInstrPath; Map=$GlobalMapPath} }

  $GlobalInstrDir = Split-Path -Parent $GlobalInstrPath
  $GlobalMapDir   = Split-Path -Parent $GlobalMapPath
  Ensure-Directory $GlobalInstrDir
  Ensure-Directory $GlobalMapDir

  $Instructions = @"
Contexto de workspace
- root = $Root
- Abreviaturas: "docs/chatgpt" = <root>\docs\chatgpt
- Nuevo proyecto "X": crear en <root>\data\proyectos\X con subcarpetas {docs, src, config, results}
- No escribes en disco: solo dame comandos/archivos listos para copiar/pegar

Preferencias de salida
- Sistema: Windows 10/11, PowerShell 7 preferido (acepto PS5 si aplica)
- Formato: SOLO bloques de código con los comandos, sin prosa
- Encoding: UTF-8
- Evita rutas relativas fuera de <root>

Límites de seguridad (duros)
- Máx. profundidad: 8 niveles
- Máx. nodos a crear por operación: 200
- No proponer cambios fuera de <root>
- Validar nombres Windows (sin <>:"/\|?*, sin punto/espacio final; sin nombres reservados)

Convenciones
- Nombres proyecto: kebab-case (ej. proyecto-ejemplo)
- Fechas en archivos: YYYY-MM-DD
- Logs en <root>\logs cuando aplique

Plantilla por defecto (si no digo lo contrario)
- Para “nuevo proyecto X”: crear {docs/, src/, config/, results/} y README.md con título y fecha
"@

  $FilemapJson = @"
{
  "schema": "filemap@1",
  "root": "$($Root.Replace('\','\\'))",
  "tree": {
    "data": { "proyectos": {}, "datasets": {} },
    "docs": { "manuales": {}, "notas": {}, "chatgpt": {} },
    "config": { "sistemas": {}, "proyectos": {}, "plantillas": {} },
    "archive": { "proyectos": {}, "docs": {} },
    "tmp": {}
  },
  "defaults": {
    "projectSkeleton": ["docs", "src", "config", "results"]
  }
}
"@

  Write-File $GlobalInstrPath $Instructions
  Write-File $GlobalMapPath   $FilemapJson
  Write-Host "✔ Plantillas globales inicializadas." -ForegroundColor Green
  return @{Instr=$GlobalInstrPath; Map=$GlobalMapPath}
}

# ---------------------------------------------------------------------
#  INSTALAR EN PROYECTO: COPIAR PLANTILLAS + AJUSTAR JSON LOCAL
# ---------------------------------------------------------------------
function Install-Workspace {
  param(
    [Parameter(Mandatory)][string]$ProjectPath,
    [Parameter(Mandatory)][string]$Root,
    [string]$GlobalInstrPath,
    [string]$GlobalMapPath,
    [switch]$Overwrite,
    [string[]]$Skeleton
  )

  $ProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path
  $WorkspaceDir = Join-Path $ProjectPath '.workspace'
  Ensure-Directory $WorkspaceDir

  $ProjInstrPath = Join-Path $WorkspaceDir 'instructions.md'
  $ProjMapPath   = Join-Path $WorkspaceDir 'filemap.json'

  if ((-not (Test-Path $ProjInstrPath)) -or $Overwrite) {
    Copy-Item -LiteralPath $GlobalInstrPath -Destination $ProjInstrPath -Force
    Write-Host "✔ Copiado: $ProjInstrPath" -ForegroundColor Green
  } else {
    Write-Host "↷ Saltado (existe): $ProjInstrPath (usa -Overwrite para reemplazar)" -ForegroundColor Yellow
  }

  if ((-not (Test-Path $ProjMapPath)) -or $Overwrite) {
    Copy-Item -LiteralPath $GlobalMapPath -Destination $ProjMapPath -Force
    Write-Host "✔ Copiado: $ProjMapPath" -ForegroundColor Green
  } else {
    Write-Host "↷ Saltado (existe): $ProjMapPath (usa -Overwrite para reemplazar)" -ForegroundColor Yellow
  }

  # Ajustar JSON local (root y skeleton)
  $json = Get-Content -LiteralPath $ProjMapPath -Raw | ConvertFrom-Json
  if (-not $json.PSObject.Properties.Match('root'))     { $json | Add-Member -NotePropertyName root -NotePropertyValue $Root }
  if (-not $json.PSObject.Properties.Match('defaults')) { $json | Add-Member -NotePropertyName defaults -NotePropertyValue ([ordered]@{}) }
  if (-not $json.defaults.PSObject.Properties.Match('projectSkeleton')) { $json.defaults | Add-Member -NotePropertyName projectSkeleton -NotePropertyValue @() }
  $json.root = $Root
  if ($Skeleton) { $json.defaults.projectSkeleton = $Skeleton }
  ($json | ConvertTo-Json -Depth 64) | Set-Content -LiteralPath $ProjMapPath -Encoding utf8
  Write-Host "✔ Actualizado JSON local: root = $Root" -ForegroundColor Green
  if ($Skeleton) { Write-Host "✔ defaults.projectSkeleton = $($Skeleton -join ', ')" -ForegroundColor Green }

  # .gitignore
  $GitIgnore = Join-Path $ProjectPath '.gitignore'
  if (-not (Test-Path $GitIgnore)) { New-Item -ItemType File -Path $GitIgnore | Out-Null }
  if (-not (Select-String -Path $GitIgnore -Pattern '^\s*\.workspace/\s*$' -Quiet)) {
    Add-Content -Path $GitIgnore -Value ".workspace/"
    Write-Host "✔ .gitignore actualizado: .workspace/" -ForegroundColor Green
  } else {
    Write-Host "↷ .gitignore ya contiene .workspace/" -ForegroundColor Yellow
  }

  return @{ WorkspaceDir=$WorkspaceDir; ProjMap=$ProjMapPath }
}

# ---------------------------------------------------------------------
#  RESOLVE-UNDER-ROOT: ACEPTA SUBRUTA ("\data\..."/"data\...") O ABSOLUTA
#  GARANTIZA QUE LA RUTA FINAL QUEDE DENTRO DE $Root
# ---------------------------------------------------------------------
function Resolve-UnderRoot {
  param(
    [Parameter(Mandatory)][string]$Root,
    [Parameter(Mandatory)][string]$Input
  )
  $s = $Input.Trim()

  if ($s -match '^[A-Za-z]:\\') {
    $p = $s                        # absoluta con unidad
  } else {
    if ($s.StartsWith('\')) { $s = $s.Substring(1) }
    $p = Join-Path $Root $s       # subruta bajo root
  }

  $full     = [System.IO.Path]::GetFullPath($p)
  $rootFull = [System.IO.Path]::GetFullPath($Root + [System.IO.Path]::DirectorySeparatorChar)
  if (-not $full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "La ruta '$full' queda fuera del root '$Root'."
  }
  return $full
}

# ---------------------------------------------------------------------
#  START-WORKSPACEWIZARD: MENÚ INTERACTIVO (1/A, 2/B, 3/C)
# ---------------------------------------------------------------------
function Start-WorkspaceWizard {
  $defaultRoot = Join-Path $HOME 'mnt'
  $root = Read-Host "Root del workspace (ENTER para '$defaultRoot')"
  if ([string]::IsNullOrWhiteSpace($root)) { $root = $defaultRoot }

  $defaultSub = 'data\proyectos\mi-proyecto'
  $sub = Read-Host "Subruta bajo root (ENTER=$defaultSub). Acepto '\data\...' o ruta absoluta"
  if ([string]::IsNullOrWhiteSpace($sub)) { $sub = $defaultSub }

  try {
    $project = Resolve-UnderRoot -Root $root -Input $sub
    Write-Host "→ Usando ruta del proyecto: $project" -ForegroundColor Cyan
  } catch {
    Write-Host "❌ $($_.Exception.Message)" -ForegroundColor Red
    return
  }

  if (-not (Test-Path $project)) {
    $create = Read-Host "La ruta no existe. ¿Crear? (y/N)"
    if ($create -match '^(y|s|si|sí)$') {
      New-Item -ItemType Directory -Force -Path $project | Out-Null
    } else {
      Write-Host "Operación cancelada." -ForegroundColor Yellow
      return
    }
  }

  $global = Initialize-GlobalTemplates -Root $root

  Write-Host "`n=== Menú ===" -ForegroundColor Cyan
  Write-Host "[1] / [A]  Instalar plantillas (no sobrescribir)" -ForegroundColor Gray
  Write-Host "[2] / [B]  Instalar + sobrescribir + validar (ShowPlan)" -ForegroundColor Gray
  Write-Host "[3] / [C]  Instalar con skeleton personalizado + validar" -ForegroundColor Gray

  $choice = Read-Host "Elige opción (1/2/3 o A/B/C)"
  switch -regex ($choice.ToUpper()) {
    '^(1|A)$' {
      $res = Install-Workspace -ProjectPath $project -Root $root -GlobalInstrPath $global.Instr -GlobalMapPath $global.Map
      Write-Host "`n✅ Listo. .workspace en: $($res.WorkspaceDir)" -ForegroundColor Green
    }
    '^(2|B)$' {
      $res = Install-Workspace -ProjectPath $project -Root $root -GlobalInstrPath $global.Instr -GlobalMapPath $global.Map -Overwrite
      Write-Host "`n— Validando árbol (dry-run, ShowPlan) —" -ForegroundColor Cyan
      try {
        $json = Get-Content -LiteralPath $res.ProjMap -Raw | ConvertFrom-Json
        if ($json.tree) {
          Test-TreePlan -Base $json.root -Map $json.tree -MaxNodes 200 -MaxDepth 32 -MaxPath 240 -ShowPlan
        } else {
          Write-Host "⚠️ filemap.json no contiene 'tree' para validar." -ForegroundColor Yellow
        }
      } catch { Write-Host "❌ Error al validar: $($_.Exception.Message)" -ForegroundColor Red }
      Write-Host "`n✅ Listo. .workspace en: $($res.WorkspaceDir)" -ForegroundColor Green
    }
    '^(3|C)$' {
      $sk = Read-Host "Skeleton (lista separada por comas, ej: docs,src,config,results,tests)"
      $skeleton = @()
      if (-not [string]::IsNullOrWhiteSpace($sk)) {
        $skeleton = $sk.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
      }
      $res = Install-Workspace -ProjectPath $project -Root $root -GlobalInstrPath $global.Instr -GlobalMapPath $global.Map -Overwrite -Skeleton $skeleton
      Write-Host "`n— Validando árbol (dry-run, ShowPlan) —" -ForegroundColor Cyan
      try {
        $json = Get-Content -LiteralPath $res.ProjMap -Raw | ConvertFrom-Json
        if ($json.tree) {
          Test-TreePlan -Base $json.root -Map $json.tree -MaxNodes 200 -MaxDepth 32 -MaxPath 240 -ShowPlan
        } else {
          Write-Host "⚠️ filemap.json no contiene 'tree' para validar." -ForegroundColor Yellow
        }
      } catch { Write-Host "❌ Error al validar: $($_.Exception.Message)" -ForegroundColor Red }
      Write-Host "`n✅ Listo. .workspace en: $($res.WorkspaceDir)" -ForegroundColor Green
    }
    default {
      Write-Host "Opción no válida. Cancelo." -ForegroundColor Yellow
    }
  }
}

# ---------------------------------------------------------------------
#  EJECUCIÓN
# ---------------------------------------------------------------------
Start-WorkspaceWizard
```
~~~~~ 

### Salida (assistant)

# -*- coding: utf-8 -*-
import os, sys, json, zipfile, textwrap, importlib.util, traceback, io, re, shutil, hashlib
from pathlib import Path

BASE_DIR = Path("/mnt/data").resolve()
work_root = BASE_DIR / "workspace_wizard_artifacts"
extract_root = BASE_DIR / "zip_extract"
work_root.mkdir(parents=True, exist_ok=True)
extract_root.mkdir(parents=True, exist_ok=True)

# 1) Locate the uploaded ZIP. Prefer explicit name if present; else use any .zip in /mnt/data
zip_candidates = []
for p in BASE_DIR.glob("*.zip"):
    zip_candidates.append(p)
# Use the largest zip (likely the main one) if multiple
zip_path = None
if zip_candidates:
    zip_path = max(zip_candidates, key=lambda p: p.stat().st_size)
else:
    raise FileNotFoundError("No .zip found in /mnt/data. Expected a ZIP with orquestador.py and others.")

# 2) Extract the ZIP cleanly
# Clear previous extraction folder
if any(extract_root.iterdir()):
    shutil.rmtree(extract_root)
extract_root.mkdir(parents=True, exist_ok=True)

with zipfile.ZipFile(zip_path, "r") as zf:
    zf.extractall(extract_root)

# 3) Try to locate the orchestrator module: prefer `orquestador.py`, then `orchestrator_modular.py`
def find_file(root: Path, names):
    for name in names:
        for p in root.rglob(name):
            return p
    return None

module_file = find_file(extract_root, ["orquestador.py", "orchestrator_modular.py", "orchestrator.py", "orquestador_modular.py"])
module_name = None
if module_file is None:
    module_info = f"No orchestrator module found inside {zip_path.name}. Contents:\n" + "\n".join(str(p.relative_to(extract_root)) for p in extract_root.rglob("*") if p.is_file())
    print(module_info)
    raise FileNotFoundError("Could not locate orquestador.py / orchestrator_modular.py in the provided ZIP.")

module_name = module_file.stem

# 4) Import the module dynamically
spec = importlib.util.spec_from_file_location(module_name, str(module_file))
mod = importlib.util.module_from_spec(spec)
sys.path.insert(0, str(module_file.parent))
try:
    spec.loader.exec_module(mod)  # type: ignore
except Exception as e:
    traceback.print_exc()
    raise

# 5) Prepare user_content (PowerShell block) exactly as provided by the user
user_content = r"""# =====================================================================
#  WORKSPACE WIZARD (PS 5/7)
#  - Plantillas globales + .workspace por proyecto
#  - Ajuste de filemap.root y skeleton
#  - Validador DRY-RUN del árbol (sin crear nada)
#  - Menú interactivo con entrada de "subruta bajo \mnt"
# =====================================================================

# ---------------------------------------------------------------------
#  HELPERS BÁSICOS
# ---------------------------------------------------------------------
function Ensure-Directory { param([string]$p) if ($p) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function Write-File { param([string]$p,[string]$content) $dir = Split-Path -Parent $p; Ensure-Directory $dir; Set-Content -LiteralPath $p -Value $content -Encoding utf8 }
function Get-MapKeys  { param($m) if ($m -is [hashtable]) { @($m.Keys) } elseif ($m -is [pscustomobject]) { @($m.PSObject.Properties.Name) } else { @() } }
function Get-MapChild { param($m,[string]$name) if ($m -is [hashtable]) { $m[$name] } elseif ($m -is [pscustomobject]) { $m.$name } else { $null } }

# ---------------------------------------------------------------------
#  VALIDATOR: TEST-TREEPLAN (DRY-RUN, NO CREA NADA)
# ---------------------------------------------------------------------
function Test-TreePlan {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Base,
    [Parameter(Mandatory)]$Map,                   # hashtable o PSCustomObject
    [int]$MaxDepth = 32, [int]$MaxNodes = 1000, [int]$MaxPath = 240,
    [switch]$ShowPlan
  )

  $errors  = New-Object System.Collections.Generic.List[string]
  $planned = 0
  $visited = [System.Collections.Generic.HashSet[object]]::new()
  $invalidChars = [regex]'[<>:"/\\|?*]'
  $reserved = @('CON','PRN','AUX','NUL','COM1','COM2','COM3','COM4','COM5','COM6','COM7','COM8','COM9','LPT1','LPT2','LPT3','LPT4','LPT5','LPT6','LPT7','LPT8','LPT9')

  function Check-Name([string]$name, [string]$parentPath) {
    if ($name -match $invalidChars) { return "Nombre inválido '$name' en '$parentPath' (caracteres no permitidos)." }
    if ($reserved -contains $name.ToUpper()) { return "Nombre reservado de Windows: '$name' en '$parentPath'." }
    if ($name.TrimEnd() -ne $name -or $name.EndsWith('.')) { return "Nombre no permitido (espacio/punto al final): '$name' en '$parentPath'." }
    if ($name.Length -gt 255) { return "Componente demasiado largo (>255): '$name' en '$parentPath'." }
    return $null
  }

  $Visit = {
    param($curBase, $curMap, $depth)

    if ($depth -gt $MaxDepth) {
      $errors.Add("Profundidad excedida ($MaxDepth) en '$curBase'.")
      Write-Host "❌ Profundidad excedida ($MaxDepth) en '$curBase'." -ForegroundColor Red
      return
    }
    if ($visited.Contains($curMap)) { return }
    [void]$visited.Add($curMap)

    $names = @(Get-MapKeys $curMap)
    $dups = $names | Group-Object { $_.ToUpper() } | Where-Object { $_.Count -gt 1 }
    foreach ($g in $dups) {
      $errors.Add("Duplicados (case-insensitive) en '$curBase': " + ($g.Group -join ', '))
      Write-Host "❌ Duplicados (case-insensitive) en '$curBase': $($g.Group -join ', ')" -ForegroundColor Red
    }

    foreach ($name in $names) {
      $nameErr = Check-Name -name $name -parentPath $curBase
      if ($nameErr) { $errors.Add($nameErr); Write-Host "❌ $nameErr" -ForegroundColor Red; continue }

      $path = Join-Path $curBase $name
      if ($path.Length -gt $MaxPath) {
        $errors.Add("Ruta demasiado larga ($($path.Length)>$MaxPath): $path")
        Write-Host "❌ Ruta demasiado larga ($($path.Length)>$MaxPath): $path" -ForegroundColor Red
        continue
      }

      $planned++
      if ($planned -gt $MaxNodes) {
        $errors.Add("Se superó MaxNodes ($MaxNodes).")
        Write-Host "❌ Se superó MaxNodes ($MaxNodes)." -ForegroundColor Red
        return
      }

      if ($ShowPlan) { Write-Host "CREATE: $path" -ForegroundColor Cyan }

      $child = Get-MapChild $curMap $name
      if ($child -is [hashtable] -or $child -is [pscustomobject]) {
        & $Visit $path $child ($depth + 1)
      } elseif ($null -ne $child) {
        $errors.Add("Valor no soportado en '$path' (se esperaba hashtable/objeto, no: $($child.GetType().Name)).")
        Write-Host "❌ Valor no soportado en '$path'." -ForegroundColor Red
      }
    }
  }

  & $Visit $Base $Map 0

  $ok = ($errors.Count -eq 0)
  $summary = [pscustomobject]@{
    Base         = $Base
    PlannedNodes = $planned
    MaxNodes     = $MaxNodes
    MaxDepth     = $MaxDepth
    MaxPath      = $MaxPath
    ErrorsCount  = $errors.Count
    Errors       = $errors
  }

  if ($ok) {
    Write-Host "✅ Verificación OK. Nodos planificados: $planned" -ForegroundColor Green
  } else {
    Write-Host "⚠️ Verificación con errores. Nodos planificados: $planned — Errores: $($errors.Count)" -ForegroundColor Yellow
    $errors | ForEach-Object { Write-Host "• $_" -ForegroundColor Yellow }
  }
  return $summary
}

# ---------------------------------------------------------------------
#  GLOBAL TEMPLATES: CREAR SI FALTAN (instructions.md + standard.json)
# ---------------------------------------------------------------------
function Initialize-GlobalTemplates {
  param(
    [Parameter(Mandatory)][string]$Root,
    [string]$GlobalInstrPath = (Join-Path $Root 'config\plantillas\workspace\instructions.md'),
    [string]$GlobalMapPath   = (Join-Path $Root 'config\filemaps\standard.json')
  )
  if ((Test-Path $GlobalInstrPath) -and (Test-Path $GlobalMapPath)) { return @{Instr=$GlobalInstrPath; Map=$GlobalMapPath} }

  $GlobalInstrDir = Split-Path -Parent $GlobalInstrPath
  $GlobalMapDir   = Split-Path -Parent $GlobalMapPath
  Ensure-Directory $GlobalInstrDir
  Ensure-Directory $GlobalMapDir

  $Instructions = @"
Contexto de workspace
- root = $Root
- Abreviaturas: "docs/chatgpt" = <root>\docs\chatgpt
- Nuevo proyecto "X": crear en <root>\data\proyectos\X con subcarpetas {docs, src, config, results}
- No escribes en disco: solo dame comandos/archivos listos para copiar/pegar

Preferencias de salida
- Sistema: Windows 10/11, PowerShell 7 preferido (acepto PS5 si aplica)
- Formato: SOLO bloques de código con los comandos, sin prosa
- Encoding: UTF-8
- Evita rutas relativas fuera de <root>

Límites de seguridad (duros)
- Máx. profundidad: 8 niveles
- Máx. nodos a crear por operación: 200
- No proponer cambios fuera de <root>
- Validar nombres Windows (sin <>:"/\|?*, sin punto/espacio final; sin nombres reservados)

Convenciones
- Nombres proyecto: kebab-case (ej. proyecto-ejemplo)
- Fechas en archivos: YYYY-MM-DD
- Logs en <root>\logs cuando aplique

Plantilla por defecto (si no digo lo contrario)
- Para “nuevo proyecto X”: crear {docs/, src/, config/, results/} y README.md con título y fecha
"@

  $FilemapJson = @"
{
  "schema": "filemap@1",
  "root": "$($Root.Replace('\','\\'))",
  "tree": {
    "data": { "proyectos": {}, "datasets": {} },
    "docs": { "manuales": {}, "notas": {}, "chatgpt": {} },
    "config": { "sistemas": {}, "proyectos": {}, "plantillas": {} },
    "archive": { "proyectos": {}, "docs": {} },
    "tmp": {}
  },
  "defaults": {
    "projectSkeleton": ["docs", "src", "config", "results"]
  }
}
"@

  Write-File $GlobalInstrPath $Instructions
  Write-File $GlobalMapPath   $FilemapJson
  Write-Host "✔ Plantillas globales inicializadas." -ForegroundColor Green
  return @{Instr=$GlobalInstrPath; Map=$GlobalMapPath}
}

# ---------------------------------------------------------------------
#  INSTALAR EN PROYECTO: COPIAR PLANTILLAS + AJUSTAR JSON LOCAL
# ---------------------------------------------------------------------
function Install-Workspace {
  param(
    [Parameter(Mandatory)][string]$ProjectPath,
    [Parameter(Mandatory)][string]$Root,
    [string]$GlobalInstrPath,
    [string]$GlobalMapPath,
    [switch]$Overwrite,
    [string[]]$Skeleton
  )

  $ProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path
  $WorkspaceDir = Join-Path $ProjectPath '.workspace'
  Ensure-Directory $WorkspaceDir

  $ProjInstrPath = Join-Path $WorkspaceDir 'instructions.md'
  $ProjMapPath   = Join-Path $WorkspaceDir 'filemap.json'

  if ((-not (Test-Path $ProjInstrPath)) -or $Overwrite) {
    Copy-Item -LiteralPath $GlobalInstrPath -Destination $ProjInstrPath -Force
    Write-Host "✔ Copiado: $ProjInstrPath" -ForegroundColor Green
  } else {
    Write-Host "↷ Saltado (existe): $ProjInstrPath (usa -Overwrite para reemplazar)" -ForegroundColor Yellow
  }

  if ((-not (Test-Path $ProjMapPath)) -or $Overwrite) {
    Copy-Item -LiteralPath $GlobalMapPath -Destination $ProjMapPath -Force
    Write-Host "✔ Copiado: $ProjMapPath" -ForegroundColor Green
  } else {
    Write-Host "↷ Saltado (existe): $ProjMapPath (usa -Overwrite para reemplazar)" -ForegroundColor Yellow
  }

  # Ajustar JSON local (root y skeleton)
  $json = Get-Content -LiteralPath $ProjMapPath -Raw | ConvertFrom-Json
  if (-not $json.PSObject.Properties.Match('root'))     { $json | Add-Member -NotePropertyName root -NotePropertyValue $Root }
  if (-not $json.PSObject.Properties.Match('defaults')) { $json | Add-Member -NotePropertyName defaults -NotePropertyValue ([ordered]@{}) }
  if (-not $json.defaults.PSObject.Properties.Match('projectSkeleton')) { $json.defaults | Add-Member -NotePropertyName projectSkeleton -NotePropertyValue @() }
  $json.root = $Root
  if ($Skeleton) { $json.defaults.projectSkeleton = $Skeleton }
  ($json | ConvertTo-Json -Depth 64) | Set-Content -LiteralPath $ProjMapPath -Encoding utf8
  Write-Host "✔ Actualizado JSON local: root = $Root" -ForegroundColor Green
  if ($Skeleton) { Write-Host "✔ defaults.projectSkeleton = $($Skeleton -join ', ')" -ForegroundColor Green }

  # .gitignore
  $GitIgnore = Join-Path $ProjectPath '.gitignore'
  if (-not (Test-Path $GitIgnore)) { New-Item -ItemType File -Path $GitIgnore | Out-Null }
  if (-not (Select-String -Path $GitIgnore -Pattern '^\s*\.workspace/\s*$' -Quiet)) {
    Add-Content -Path $GitIgnore -Value ".workspace/"
    Write-Host "✔ .gitignore actualizado: .workspace/" -ForegroundColor Green
  } else {
    Write-Host "↷ .gitignore ya contiene .workspace/" -ForegroundColor Yellow
  }

  return @{ WorkspaceDir=$WorkspaceDir; ProjMap=$ProjMapPath }
}

# ---------------------------------------------------------------------
#  RESOLVE-UNDER-ROOT: ACEPTA SUBRUTA ("\data\..."/"data\...") O ABSOLUTA
#  GARANTIZA QUE LA RUTA FINAL QUEDE DENTRO DE $Root
# ---------------------------------------------------------------------
function Resolve-UnderRoot {
  param(
    [Parameter(Mandatory)][string]$Root,
    [Parameter(Mandatory)][string]$Input
  )
  $s = $Input.Trim()

  if ($s -match '^[A-Za-z]:\\') {
    $p = $s                        # absoluta con unidad
  } else {
    if ($s.StartsWith('\')) { $s = $s.Substring(1) }
    $p = Join-Path $Root $s       # subruta bajo root
  }

  $full     = [System.IO.Path]::GetFullPath($p)
  $rootFull = [System.IO.Path]::GetFullPath($Root + [System.IO.Path]::DirectorySeparatorChar)
  if (-not $full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "La ruta '$full' queda fuera del root '$Root'."
  }
  return $full
}

# ---------------------------------------------------------------------
#  START-WORKSPACEWIZARD: MENÚ INTERACTIVO (1/A, 2/B, 3/C)
# ---------------------------------------------------------------------
function Start-WorkspaceWizard {
  $defaultRoot = Join-Path $HOME 'mnt'
  $root = Read-Host "Root del workspace (ENTER para '$defaultRoot')"
  if ([string]::IsNullOrWhiteSpace($root)) { $root = $defaultRoot }

  $defaultSub = 'data\proyectos\mi-proyecto'
  $sub = Read-Host "Subruta bajo root (ENTER=$defaultSub). Acepto '\data\...' o ruta absoluta"
  if ([string]::IsNullOrWhiteSpace($sub)) { $sub = $defaultSub }

  try {
    $project = Resolve-UnderRoot -Root $root -Input $sub
    Write-Host "→ Usando ruta del proyecto: $project" -ForegroundColor Cyan
  } catch {
    Write-Host "❌ $($_.Exception.Message)" -ForegroundColor Red
    return
  }

  if (-not (Test-Path $project)) {
    $create = Read-Host "La ruta no existe. ¿Crear? (y/N)"
    if ($create -match '^(y|s|si|sí)$') {
      New-Item -ItemType Directory -Force -Path $project | Out-Null
    } else {
      Write-Host "Operación cancelada." -ForegroundColor Yellow
      return
    }
  }

  $global = Initialize-GlobalTemplates -Root $root

  Write-Host "`n=== Menú ===" -ForegroundColor Cyan
  Write-Host "[1] / [A]  Instalar plantillas (no sobrescribir)" -ForegroundColor Gray
  Write-Host "[2] / [B]  Instalar + sobrescribir + validar (ShowPlan)" -ForegroundColor Gray
  Write-Host "[3] / [C]  Instalar con skeleton personalizado + validar" -ForegroundColor Gray

  $choice = Read-Host "Elige opción (1/2/3 o A/B/C)"
  switch -regex ($choice.ToUpper()) {
    '^(1|A)$' {
      $res = Install-Workspace -ProjectPath $project -Root $root -GlobalInstrPath $global.Instr -GlobalMapPath $global.Map
      Write-Host "`n✅ Listo. .workspace en: $($res.WorkspaceDir)" -ForegroundColor Green
    }
    '^(2|B)$' {
      $res = Install-Workspace -ProjectPath $project -Root $root -GlobalInstrPath $global.Instr -GlobalMapPath $global.Map -Overwrite
      Write-Host "`n— Validando árbol (dry-run, ShowPlan) —" -ForegroundColor Cyan
      try {
        $json = Get-Content -LiteralPath $res.ProjMap -Raw | ConvertFrom-Json
        if ($json.tree) {
          Test-TreePlan -Base $json.root -Map $json.tree -MaxNodes 200 -MaxDepth 32 -MaxPath 240 -ShowPlan
        } else {
          Write-Host "⚠️ filemap.json no contiene 'tree' para validar." -ForegroundColor Yellow
        }
      } catch { Write-Host "❌ Error al validar: $($_.Exception.Message)" -ForegroundColor Red }
      Write-Host "`n✅ Listo. .workspace en: $($res.WorkspaceDir)" -ForegroundColor Green
    }
    '^(3|C)$' {
      $sk = Read-Host "Skeleton (lista separada por comas, ej: docs,src,config,results,tests)"
      $skeleton = @()
      if (-not [string]::IsNullOrWhiteSpace($sk)) {
        $skeleton = $sk.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
      }
      $res = Install-Workspace -ProjectPath $project -Root $root -GlobalInstrPath $global.Instr -GlobalMapPath $global.Map -Overwrite -Skeleton $skeleton
      Write-Host "`n— Validando árbol (dry-run, ShowPlan) —" -ForegroundColor Cyan
      try {
        $json = Get-Content -LiteralPath $res.ProjMap -Raw | ConvertFrom-Json
        if ($json.tree) {
          Test-TreePlan -Base $json.root -Map $json.tree -MaxNodes 200 -MaxDepth 32 -MaxPath 240 -ShowPlan
        } else {
          Write-Host "⚠️ filemap.json no contiene 'tree' para validar." -ForegroundColor Yellow
        }
      } catch { Write-Host "❌ Error al validar: $($_.Exception.Message)" -ForegroundColor Red }
      Write-Host "`n✅ Listo. .workspace en: $($res.WorkspaceDir)" -ForegroundColor Green
    }
    default {
      Write-Host "Opción no válida. Cancelo." -ForegroundColor Yellow
    }
  }
}

# ---------------------------------------------------------------------
#  EJECUCIÓN
# ---------------------------------------------------------------------
Start-WorkspaceWizard
"""

# 6) Run preflight()
preflight_ok = None
preflight_err = None
if hasattr(mod, "preflight"):
    try:
        preflight_ok = mod.preflight()
    except Exception as e:
        preflight_err = traceback.format_exc()
else:
    preflight_err = "Module has no preflight()"

# 7) Run run_all() per the user's parameters
stem = "workspace-wizard-ps5-7"
base_dir = str(work_root)
note_for_canvas = ""
link_check = True
no_release = False

run_all_result = None
run_all_err = None
if hasattr(mod, "run_all"):
    try:
        run_all_result = mod.run_all(
            user_content=user_content,
            stem=stem,
            base_dir=base_dir,
            note_for_canvas=note_for_canvas,
            link_check=link_check,
            no_release=no_release,
        )
    except Exception as e:
        # If PNG chart generation fails due to missing libs, the orchestrator may raise;
        # we keep going and capture the error.
        run_all_err = traceback.format_exc()
else:
    run_all_err = "Module has no run_all()"

# 8) Collect artifacts with expected names
expected = {
    "ps1":      None,
    "md":       None,
    "txt":      None,
    "json":     None,
    "csv":      None,
    "html":     None,
    "chart":    None,  # png optional
    "zip":      None,  # bundle zip
    "release":  None,  # release zip inside _releases/
    "inventory.json": None,
    "hashes.txt": None,
    "verify.sh": None,
    "verify.ps1": None,
    "REPORT.md": None,
    "manifest.json": None,
    "checkpoints.jsonl": None,
}

def find_first(patterns):
    for pat in patterns:
        for p in work_root.rglob(pat):
            if p.is_file():
                return p
    return None

# Try to locate by stem where applicable
expected["ps1"] = find_first([f"{stem}.ps1", f"**/{stem}.ps1"])
expected["md"] = find_first([f"{stem}.md", f"**/{stem}.md"])
expected["txt"] = find_first([f"{stem}.txt", f"**/{stem}.txt"])
expected["json"] = find_first([f"{stem}.json", f"**/{stem}.json"])
expected["csv"] = find_first([f"{stem}.csv", f"**/{stem}.csv"])
expected["html"] = find_first([f"{stem}.html", f"**/{stem}.html"])
expected["chart"] = find_first([f"{stem}.png", f"**/{stem}.png", "chart.png", "**/chart.png"])
expected["zip"] = find_first([f"{stem}.zip", f"**/{stem}.zip", f"{stem}_bundle.zip", f"**/{stem}_bundle.zip"])
expected["inventory.json"] = find_first(["inventory.json", f"**/{stem}.inventory.json", "**/inventory.json"])
expected["hashes.txt"] = find_first(["hashes.txt", "**/hashes.txt", f"{stem}.hashes.txt", f"**/{stem}.hashes.txt"])
expected["verify.sh"] = find_first(["verify.sh", "**/verify.sh"])
expected["verify.ps1"] = find_first(["verify.ps1", "**/verify.ps1"])
expected["REPORT.md"] = find_first(["REPORT.md", "**/REPORT.md", f"{stem}.REPORT.md", f"**/{stem}.REPORT.md"])
expected["manifest.json"] = find_first(["manifest.json", "**/manifest.json", f"{stem}.manifest.json", f"**/{stem}.manifest.json"])
expected["checkpoints.jsonl"] = find_first(["checkpoints.jsonl", "**/checkpoints.jsonl", f"{stem}.checkpoints.jsonl", f"**/{stem}.checkpoints.jsonl"])

# Try to locate a release zip under _releases
releases_dir = work_root / "_releases"
if releases_dir.exists():
    zips = sorted(releases_dir.glob("*.zip"))
    expected["release"] = zips[-1] if zips else None

# 9) Build file sizes and link-check status (empty expected if OK)
def size_or_none(p):
    try:
        return p.stat().st_size if p else None
    except Exception:
        return None

sizes = {k: (size_or_none(v) or 0) for k, v in expected.items()}

# link_check status: prefer to read from run_all_result if it returns something structured
status_link_check = ""
if isinstance(run_all_result, dict):
    # try to extract link-check status
    status_link_check = run_all_result.get("link_check_status", "") or ""

summary = {
    "stem": stem,
    "status_link_check": status_link_check,
    "sizes_bytes": sizes,
    "preflight_ok": bool(preflight_ok) if preflight_ok is not None else False,
    "preflight_err": preflight_err if preflight_err else "",
    "run_all_err": run_all_err if run_all_err else "",
    "module_used": str(module_file.relative_to(extract_root)),
    "base_dir": str(work_root),
}

# Write summary to file
(work_root / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")

# Prepare a simple manifest of links (paths only; the assistant will render as clickable links)
links = {}
for k, p in expected.items():
    if p and p.exists():
        links[k] = f"sandbox:{p}"
(work_root / "links.json").write_text(json.dumps(links, indent=2), encoding="utf-8")

# Print human-friendly output for visibility
print("ZIP extracted to:", extract_root)
print("Module used:", module_file)
print("preflight_ok:", preflight_ok, "preflight_err:", preflight_err)
print("run_all_err:", run_all_err)
print("Artifacts found:")
for k, p in expected.items():
    print(f" - {k:16s}: {p if p else '— not found —'}")
print("\nSummary JSON:")
print(json.dumps(summary, indent=2, ensure_ascii=False))
