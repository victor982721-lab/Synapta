# &lt;WsW_Script&gt;

https://chat.openai.com/c/68da6a8b-7970-8325-b404-c8a585538fe8

## USER
Analiza y explica que hace el siguiente script:

```
# --- Helper: resuelve una entrada (absoluta o relativa) asegurando que quede BAJO $root ---
function Resolve-UnderRoot {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$Input
    )
    $s = $Input.Trim()

    # ¿ruta absoluta con unidad? (C:\..., D:\...)
    if ($s -match '^[A-Za-z]:\\') {
        $p = $s
    } else {
        # permitir que el usuario ponga "\data\..." o "data\..."
        if ($s.StartsWith('\')) { $s = $s.Substring(1) }
        $p = Join-Path $Root $s
    }

    # normalizar y validar que esté dentro de $Root
    $full    = [System.IO.Path]::GetFullPath($p)
    $rootFull = [System.IO.Path]::GetFullPath($Root + [System.IO.Path]::DirectorySeparatorChar)
    if (-not $full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "La ruta '$full' queda fuera del root '$Root'."
    }
    return $full
}

# --- MENÚ (reemplaza tu Start-WorkspaceWizard) ---
function Start-WorkspaceWizard {
  $defaultRoot = Join-Path $HOME 'mnt'
  $root = Read-Host "Root del workspace (ENTER para '$defaultRoot')"
  if ([string]::IsNullOrWhiteSpace($root)) { $root = $defaultRoot }

  # Aquí pides SOLO la subruta (o una absoluta si quieres)
  $defaultSub = 'data\proyectos\mi-proyecto'
  $sub = Read-Host "Subruta bajo root (ENTER=$defaultSub). También acepto '\data\...' o ruta absoluta"
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

# ===============================================
# Workspace Wizard (interactivo) — PS 5/7
# - Menú 1/2/3 o A/B/C
# - Instala plantillas .workspace/, ajusta filemap.root
# - Validación opcional (dry-run) sin crear árbol real
# ===============================================

# ---------- Helpers ----------
function Ensure-Directory($p) { if ($p) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function Write-File($p, $content) { $dir = Split-Path -Parent $p; Ensure-Directory $dir; Set-Content -LiteralPath $p -Value $content -Encoding utf8 }

function Get-MapKeys($m) {
  if ($m -is [hashtable]) { return @($m.Keys) }
  elseif ($m -is [pscustomobject]) { return @($m.PSObject.Properties.Name) }
  else { return @() }
}
function Get-MapChild($m, $name) {
  if ($m -is [hashtable]) { return $m[$name] }
  elseif ($m -is [pscustomobject]) { return $m.$name }
  else { return $null }
}

# ---------- Validador DRY-RUN ----------
function Test-TreePlan {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Base,
    [Parameter(Mandatory)]$Map,           # hashtable o PSCustomObject
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

# ---------- Inicializar plantillas globales si faltan ----------
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

# ---------- Instalar en proyecto ----------
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

# ---------- Menú interactivo ----------
function Start-WorkspaceWizard {
  # Entradas básicas
  $defaultRoot = Join-Path $HOME 'mnt'
  $root = Read-Host "Root del workspace (ENTER para '$defaultRoot')"
  if ([string]::IsNullOrWhiteSpace($root)) { $root = $defaultRoot }

  $project = Read-Host "Ruta del proyecto (ej. $root\data\proyectos\mi-proyecto)"
  if (-not (Test-Path $project)) {
    $create = Read-Host "La ruta no existe. ¿Crear? (y/N)"
    if ($create -match '^(y|s|si|sí)$') {
      Ensure-Directory $project
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

# ---------- Lanzar asistente ----------
Start-WorkspaceWizard
```

## Thoughts
El script definido por el usuario incluye una función llamada Start-WorkspaceWizard, que se declara dos veces. La primera definición es completa, con Resolve-UnderRoot para asegurar la ruta adecuada. La segunda definición es más simple, sobrescribiendo la primera. Al final, se llama la versión más reciente de Start-WorkspaceWizard. Este patrón de duplicación puede crear confusión y debe ser aclarado.
La segunda definición de Start-WorkspaceWizard sobrescribe a la primera, haciendo que Resolve-UnderRoot no se use más, a menos que sea referenciado en la versión anterior, que ya está reemplazada. También hay funciones como Test-TreePlan para validar la estructura, y Initialize-GlobalTemplates que asegura archivos estándar como "instructions.md".
Install-Workspace crea el directorio .workspace, copia archivos como instructions.md y filemap.json, actualiza el JSON y .gitignore, y devuelve rutas. La primera versión del asistente solicita la ruta raíz y subruta bajo seguridad (Resolve-UnderRoot) y verifica la estructura. La segunda versión omite esas validaciones pero mantiene funciones similares con opciones de entrada de esqueleto.
Es importante destacar que Resolve-UnderRoot previene la escritura fuera de la raíz, pero la segunda versión del asistente no tiene esa validación. También se consideran las restricciones específicas de Windows, como caracteres no válidos y la longitud máxima de las rutas (240 caracteres). Además, se evitó la recursión infinita y se validan nombres con Check-Name.
Este script PowerShell crea un espacio de trabajo estructurado para proyectos, definiendo plantillas y validando mapas de archivos (con pruebas "en seco"). Ofrece tres opciones: solo instalar, instalar y validar o agregar un esqueleto personalizado. Se recomienda unificar versiones del asistente, usar validaciones más robustas y mejorar la portabilidad. Además, la ejecución es limitada a Windows, y se requiere tener en cuenta la seguridad al manejar rutas.

## ASSISTANT
Aquí va un desglose claro de lo que hace el script (PowerShell) y algunos detalles importantes a notar.

# Qué es y para qué sirve
Es un **“Workspace Wizard” interactivo** para proyectos en Windows. Su meta es:
- Crear (o inicializar) una carpeta de proyecto.
- Generar una carpeta **`.workspace/`** dentro del proyecto con dos archivos:
  - `instructions.md` (guía de trabajo)
  - `filemap.json` (mapa de árbol planeado)
- **Opcionalmente validar en “dry-run”** (sin crear nada) el árbol descrito en `filemap.json`.
- Mantener **`.workspace/` en .gitignore**.

# Flujo general (lo que verás al ejecutarlo)
1) Te pide un **root** (por defecto: `$HOME\mnt`).
2) Te pide la **ruta del proyecto** (o subruta bajo el root, según la versión de asistente que quede activa; ver “ojo” abajo).
3) Si no existe, te pregunta si la crea.
4) Inicializa plantillas globales bajo `<root>\config\...` si faltan.
5) Muestra un menú:
   - **[1]/[A]** Instalar plantillas **sin sobrescribir**.
   - **[2]/[B]** Instalar **sobrescribiendo** + **validar** (dry-run, “ShowPlan”).
   - **[3]/[C]** Igual que (2) pero además permite **definir un “skeleton”** (p. ej. `docs,src,config,results`) que se guarda en `filemap.json` (no crea directorios reales; sólo metadata).

# Piezas clave (funciones)
- **`Resolve-UnderRoot`**  
  Normaliza una ruta de entrada (absoluta o relativa) y **verifica que quede dentro de `$Root`**. Si apunta fuera, lanza excepción. Es una defensa contra rutas fuera del área de trabajo.

- **Helpers**  
  - `Ensure-Directory`, `Write-File`: crear carpetas/archivos.
  - `Get-MapKeys`, `Get-MapChild`: permiten tratar el “mapa” tanto si viene como hashtable como si es `PSCustomObject`.

- **`Test-TreePlan` (validador “dry-run”)**  
  Recorre el **mapa de árbol** (`$Map`) y **no crea nada**, sólo valida y opcionalmente imprime líneas `CREATE: <ruta>` si usas `-ShowPlan`.  
  Comprueba:
  - **Profundidad** (`MaxDepth`, por defecto 32).
  - **Nº de nodos** (`MaxNodes`, por defecto 1000; el asistente pasa 200).
  - **Longitud de ruta** (`MaxPath`, por defecto 240).
  - **Nombres inválidos** (caracteres prohibidos en Windows, espacios/puntos al final).
  - **Nombres reservados** (CON, PRN, AUX, COM1…).
  - **Duplicados case-insensitive** en el mismo nivel.  
  Devuelve un objeto resumen con conteo de errores.

- **`Initialize-GlobalTemplates`**  
  Asegura que existan:
  - `<root>\config\plantillas\workspace\instructions.md` (con una guía por defecto).
  - `<root>\config\filemaps\standard.json` (con un árbol base y `defaults.projectSkeleton`).  
  Si no existen, los **crea**.

- **`Install-Workspace`**  
  - Crea **`<Project>\.workspace\`**.
  - Copia `instructions.md` y `filemap.json` desde las plantillas globales (con `-Overwrite` si se pidió).
  - **Actualiza `filemap.json` local**: ajusta `root = <root>` y, si diste `-Skeleton`, lo guarda en `defaults.projectSkeleton`.
  - Asegura que `.gitignore` contenga la línea **`.workspace/`**.
  - Devuelve rutas útiles (`WorkspaceDir`, `ProjMap`).

# Ojo importante: hay **dos** versiones del asistente
El script **define `Start-WorkspaceWizard` dos veces**. En PowerShell, **la segunda definición reemplaza a la primera**.  
- La **primera versión** (arriba) usa `Resolve-UnderRoot` para que la “subruta” quede **obligatoriamente bajo `$root`** (más seguro).  
- La **segunda versión** (abajo, la que finalmente se ejecuta) **no restringe** la ruta del proyecto al `root`; te deja poner cualquier ruta absoluta que exista o crearla.

**Consecuencia:** al final, cuando el script llama `Start-WorkspaceWizard`, se usa **la segunda** (menos restrictiva). Si tu intención era **encapsular todo bajo `$root`**, esto es un **bug funcional/seguridad**: se pierde la protección “bajo root”.

# Qué **no** hace
- **No crea** realmente el árbol descrito en el `filemap.json`; la validación con `Test-TreePlan` es **solo dry-run** (planeación).  
- El “skeleton” que capturas en la opción 3 **no crea carpetas**; sólo guarda esa preferencia en `filemap.json`.

# Portabilidad y supuestos
- Está orientado a **Windows** (usa separadores `\`, valida nombres reservados, comprueba longitud de ruta tipo Windows).
- Por defecto usa `$HOME\mnt` como raíz.

# Recomendaciones de mejora
1) **Eliminar la duplicidad** de `Start-WorkspaceWizard` y **mantener la versión segura** que usa `Resolve-UnderRoot`.  
2) Si necesitas flexibilidad, añade un switch (p. ej. `-AllowOutsideRoot`) y por defecto **restringe** al root.  
3) (Opcional) Añadir un comando para **materializar** (crear) el árbol del `filemap.json` cuando lo desees (separado de la validación).  
4) Devolver objetos (no sólo `Write-Host`) para poder **scriptar** el proceso en pipelines.  
5) Validar que `filemap.json` tenga `tree` antes de intentar ShowPlan (ya lo hace), y considerar **esquema**/versión.

# Resumen en una línea
Un asistente interactivo que inicializa `.workspace/` en tu proyecto, mantiene plantillas y `.gitignore`, y te permite **validar** (sin crear) el árbol planificado; pero actualmente, por una redefinición, **no** fuerza que la ruta del proyecto quede bajo el **root**.

