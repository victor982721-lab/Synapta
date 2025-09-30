### Entrada (user)

Instrucciones:

1. Parcea la totalidad del contenido de `prompt_archivos.md` y usalo como prompt para esta iteración.

2. Ejecuta el `orquestador.py` para procesar el siguiente contenido:

```
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

### Salida (assistant)

# Orquestación iterativa en un solo turno, usando /mnt/data/orquestador.py
# - Carga del módulo
# - Ejecución run_iterative() con checkpoints.jsonl
# - Recolección de enlaces y métricas resumen
import json, os, importlib.util, hashlib
from pathlib import Path
from datetime import datetime

BASE_DIR = Path("/mnt/data")
ORQ_PATH = BASE_DIR / "orquestador.py"

# Cargar módulo orquestador dinámicamente
spec = importlib.util.spec_from_file_location("orquestador", str(ORQ_PATH))
orq = importlib.util.module_from_spec(spec)
spec.loader.exec_module(orq)

# Contenido proporcionado por el usuario (PowerShell Workspace Wizard)
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

stem = "workspace-wizard-ps5-7"
checkpoints_path = BASE_DIR / "checkpoints.jsonl"
# Truncar checkpoints previos
checkpoints_path.write_text("", encoding="utf-8")

def file_sha256(p: Path) -> str | None:
    try:
        return hashlib.sha256(p.read_bytes()).hexdigest()
    except Exception:
        return None

def mini_info(d: dict) -> dict:
    out = {k: d.get(k) for k in ("path","status","link") if k in d}
    # Intentar bytes/sha256 si hay path
    p = Path(out["path"]) if "path" in out and out["path"] else None
    if p and p.exists():
        out["bytes"] = p.stat().st_size
        sh = file_sha256(p)
        if sh: out["sha256"] = sh
    return out

# Ejecutar iterativamente y registrar checkpoints
summary_rows = []
for step, res in orq.run_iterative(user_content, stem=stem, base_dir=str(BASE_DIR)):
    # empaquetar salida
    record = {"step": step}
    if isinstance(res, dict):
        record.update(mini_info(res))
    else:
        record["result"] = str(res)
    summary_rows.append(record)
    with checkpoints_path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")

# Colectar enlaces y métricas
links = orq.collect_links(stem=stem, base_dir=str(BASE_DIR))
# Contar estados por step
status_counts = {}
have_png = False
have_zip = False
release_zip_path = None
for r in summary_rows:
    st = r.get("status","unknown")
    status_counts[st] = status_counts.get(st, 0) + 1
    p = r.get("path","")
    if p.endswith("_chart.png") and Path(p).exists():
        have_png = True
    if "/_releases/" in p and p.endswith(".zip"):
        have_zip = True
        release_zip_path = p

# Leer verify scripts para incluir en la respuesta
verify_sh = (BASE_DIR / "verify.sh").read_text(encoding="utf-8") if (BASE_DIR / "verify.sh").exists() else ""
verify_ps1 = (BASE_DIR / "verify.ps1").read_text(encoding="utf-8") if (BASE_DIR / "verify.ps1").exists() else ""

# Resultado final visible para el usuario
result = {
    "stem": stem,
    "base_dir": str(BASE_DIR),
    "links": links,
    "checkpoints_file": f"sandbox:{checkpoints_path.as_posix()}",
    "status_counts": status_counts,
    "have_chart_png": have_png,
    "have_release_zip": have_zip,
    "release_zip_path": f"sandbox:{Path(release_zip_path).as_posix()}" if release_zip_path else None,
    "first_10_checkpoints": summary_rows[:10]
}

result, verify_sh[:4000], verify_ps1[:4000]
