### Entrada (user)

Analiza y explica que hace el siguiente script:

```
# Patch-Verify_Project_Modularize.ps1
# Reorganiza el macroscript en módulos con marcadores claros y lo renombra a Verify_Project.ps1.
# Crea stub de compatibilidad para Invoke-RepoReorg.ps1, conserva backups y actualiza CHANGELOG.
#requires -Version 5.1
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# --- Rutas del proyecto (Windows) ---
$RepoRootWin  = 'C:\Users\VictorFabianVeraVill\Desktop\Repo_AR'
$ScriptsDir   = Join-Path $RepoRootWin 'SCRIPTS'
$OldPath      = Join-Path $ScriptsDir  'Invoke-RepoReorg.ps1'
$NewPath      = Join-Path $ScriptsDir  'Verify_Project.ps1'
$BackupsDir   = Join-Path $ScriptsDir  'BACKUPS'
$ChangelogWin = Join-Path $RepoRootWin 'CHANGELOG.md'
# --- Ruta espejo opcional para asistente ---
$ChangelogBot = '/mnt/data/Repo_AR/CHANGELOG.md'

# --- Utilidades locales del parche ---
function New-TS { [DateTime]::UtcNow.ToString('yyyyMMdd_HHmmssfff') }
function Ensure-Dir([string]$Path){
  if (-not (Test-Path -LiteralPath $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
  (Resolve-Path -LiteralPath $Path).Path
}
function Write-Utf8NoBom {
  param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$Content,[switch]$Append)
  $dir = Split-Path -Parent $Path
  if ($dir) { Ensure-Dir $dir | Out-Null }
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  if ($Append){ [IO.File]::AppendAllText($Path,$Content,$utf8) } else { [IO.File]::WriteAllText($Path,$Content,$utf8) }
}

# --- Validaciones previas ---
Ensure-Dir $ScriptsDir | Out-Null
Ensure-Dir $BackupsDir | Out-Null
if (-not (Test-Path -LiteralPath $OldPath)) { throw "No existe $OldPath; se requiere para versionar y dejar stub." }

# --- Respaldo del archivo actual ---
$BackupPath = Join-Path $BackupsDir ("Invoke-RepoReorg_{0}.bak" -f (New-TS))
Copy-Item -LiteralPath $OldPath -Destination $BackupPath -Force

# --- Contenido del NUEVO macroscript modular: Verify_Project.ps1 ---
$VerifyProjectContent = @'
# Verify_Project.ps1 — Auditoría y verificación de proyecto (PAVC-Compat 2025-09)
# Uso:
#   .\Verify_Project.ps1 [-RepoRoot <ruta>] [-RunPSSA] [-RunInlineTests]
# Notas:
#   - Compatible PS 5.1 y 7.x
#   - No modifica contenido de PI/SOP; valida estructura, normaliza BACKUPS, registra PAVC
#   - Marcadores de módulos para parches granulares (ReplaceBetweenMarkers)

# [BEGIN MODULE: Parameters]
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param(
  [string]$RepoRoot,
  [switch]$RunInlineTests,
  [switch]$RunPSSA
)
# [END MODULE: Parameters]

# [BEGIN MODULE: Globals]
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$Script:Version             = '3.0.0-PAVC'
$Script:DefaultRepoRoot     = 'C:\Users\VictorFabianVeraVill\Desktop\Repo_AR'
$Script:GlobalChangeLogPath = $null
$Script:PAVC_Tag            = 'PAVC-Compat (2025-09)'
# [END MODULE: Globals]

# [BEGIN MODULE: IO.Utils]
function Write-Utf8NoBom {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$Content,[switch]$Append)
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  if ($Append){ [IO.File]::AppendAllText($Path,$Content,$utf8) } else { [IO.File]::WriteAllText($Path,$Content,$utf8) }
}
function New-Timestamp { [DateTime]::UtcNow.ToString('yyyyMMdd_HHmmssfff') }
function Resolve-RepoRoot {
  [CmdletBinding()]
  param([string]$RepoRoot)
  if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    if ($env:ANASTASIS_REPO_ROOT) { $RepoRoot = $env:ANASTASIS_REPO_ROOT } else { $RepoRoot = $Script:DefaultRepoRoot }
  }
  if (-not (Test-Path -LiteralPath $RepoRoot)) { throw [IO.DirectoryNotFoundException]::new("RepoRoot no encontrado: $RepoRoot") }
  (Resolve-Path -LiteralPath $RepoRoot).Path
}
function Ensure-Directory {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
  (Resolve-Path -LiteralPath $Path).Path
}
# [END MODULE: IO.Utils]

# [BEGIN MODULE: Logging]
function Append-GlobalChangeLog {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Message,[string]$Extra = $null)
  if (-not $Script:GlobalChangeLogPath) { return }
  $hr   = ('-'*80)
  $hdr  = ("{0} — Verify_Project v{1} — {2}" -f ([DateTime]::UtcNow.ToString('u')),$Script:Version,$Script:PAVC_Tag)
  $body = if ($Extra) { "$Message`r`n$Extra" } else { $Message }
  $entry = "$hr`r`n$hdr`r`n$body`r`n$hr`r`n"
  Write-Utf8NoBom -Path $Script:GlobalChangeLogPath -Content $entry -Append

  $mirrorDir = '/mnt/data/Repo_AR'
  if (Test-Path -LiteralPath $mirrorDir) {
    $mirror = Join-Path $mirrorDir 'CHANGELOG.md'
    Write-Utf8NoBom -Path $mirror -Content $entry -Append
  }
}
function Write-ChangeLog {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$TargetPath,
    [Parameter(Mandatory)]
    [ValidateSet('Add','Append','ReplaceFile','Move','CreateStub','ReplaceBetweenMarkers','Other')]
    [string]$Mode,
    [ValidateLength(1,4096)][string]$Summary='[No summary]'
  )
  $full = Resolve-Path -LiteralPath $TargetPath -ErrorAction Stop
  $f = Get-Item -LiteralPath $full
  $dir = Ensure-Directory -Path (Join-Path $f.DirectoryName 'Changelogs')
  $ts  = [DateTime]::UtcNow
  $safe = ($f.Name -replace '[^A-Za-z0-9\.\-_]','_')
  $name = ('{0:yyyyMMdd_HHmmssfff}_{1}_{2}.md' -f $ts,$safe,$Mode)
  $path = Join-Path $dir $name
  $doc = @"
# Changelog Entry
- UTC: $($ts.ToString('u'))
- File: $($f.FullName)
- Mode: $Mode
- Summary: $Summary
"@
  Write-Utf8NoBom -Path $path -Content $doc
  Append-GlobalChangeLog -Message ("{0:u} | {1} | {2} | {3}" -f $ts,$f.FullName,$Mode,$Summary)
  $path
}
# [END MODULE: Logging]

# [BEGIN MODULE: Safety.FenceCheck]
function Test-FenceSafety {
  [CmdletBinding()]
  param([Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)][string[]]$Path)
  process {
    foreach ($p in $Path) {
      if (-not (Test-Path -LiteralPath $p)) { continue }
      $text = Get-Content -LiteralPath $p -Raw -Encoding UTF8
      $issues = @()
      $grave = [char]0x60
      if ($text -match "$grave{5}") { $issues += 'Uso de 5 backticks detectado; preferir 5 tildes ~~~~~ para artefactos.' }
      if ($text -match "^\s+['""]@") { $issues += 'Cierre de here-string con indentación: el delimitador debe iniciar en columna 1.' }
      if ($text -match '-f\s+.*\{.*\}') { $issues += 'Uso de -f con llaves {}; duplicar llaves o evitar -f.' }
      [PSCustomObject]@{ Path=$p; Issues= if ($issues){$issues -join '; '} else {'<OK>'} }
    }
  }
}
# [END MODULE: Safety.FenceCheck]

# [BEGIN MODULE: Reporting.PAVC]
function Add-PAVCReport {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$RepoRoot)
  $utc = [DateTime]::UtcNow
  $report = @"
## Contexto verificado — $($utc.ToString('yyyy-MM-dd'))
- Campos CI (~1500): [Pendiente] — confirmar en UI. **[UI del usuario]**
- Project Instructions (límite/ubicación UI): [Pendiente]. **[UI del usuario]**
- Memoria (global vs project-only): [Pendiente]. **[UI del usuario]**
- Diferencias por plan: [Pendiente; requiere fuentes]. **[Oficial]**
- Notas: verificación con fuentes mediante web.run; este script registra trazabilidad. **[$Script:PAVC_Tag]**
"@
  $ch = Join-Path $RepoRoot 'CHANGELOG.md'
  Write-Utf8NoBom -Path $ch -Content "`r`n$report`r`n" -Append

  $mirrorDir = '/mnt/data/Repo_AR'
  if (Test-Path -LiteralPath $mirrorDir) {
    $mirror = Join-Path $mirrorDir 'CHANGELOG.md'
    Write-Utf8NoBom -Path $mirror -Content "`r`n$report`r`n" -Append
  }
  Append-GlobalChangeLog -Message 'Registro PAVC añadido al CHANGELOG.'
}
# [END MODULE: Reporting.PAVC]

# [BEGIN MODULE: Project.Checks]
function Invoke-ProjectChecks {
  [CmdletBinding(SupportsShouldProcess)]
  param([Parameter(Mandatory)][string]$RepoRoot)

  $root = Resolve-RepoRoot -RepoRoot $RepoRoot
  Write-Output ("RepoRoot: {0}" -f $root)

  # Estructura esperada (rutas reales)
  $scriptsDir   = Ensure-Directory -Path (Join-Path $root 'SCRIPTS')
  $backupsUpper = Join-Path $scriptsDir 'BACKUPS'
  $backupsLower = Join-Path $scriptsDir 'Backups'

  if ((Test-Path -LiteralPath $backupsLower) -and -not (Test-Path -LiteralPath $backupsUpper)) {
    if ($PSCmdlet.ShouldProcess($backupsLower,'Renombrar a BACKUPS')) {
      Move-Item -LiteralPath $backupsLower -Destination $backupsUpper -Force
      Write-ChangeLog -TargetPath $backupsUpper -Mode 'Move' -Summary 'Normalización: SCRIPTS\BACKUPS (mayúsculas)' | Out-Null
    }
  }
  Ensure-Directory -Path $backupsUpper | Out-Null

  $piPath  = Join-Path $root 'Project_Instructions.md'
  $sopDir  = Join-Path $root 'SOP'
  $sopList = @('SOP_Auditoria_Proyecto.md','SOP_CB_Blindado.md','SOP_Herestrings.md','SOP_AVC.md') | ForEach-Object { Join-Path $sopDir $_ }

  if (-not (Test-Path -LiteralPath $piPath)) { throw [IO.FileNotFoundException]::new("Falta Project_Instructions.md en $root") }
  if (-not (Test-Path -LiteralPath $sopDir))  { throw [IO.DirectoryNotFoundException]::new("Falta carpeta SOP en $root") }

  $missing = $sopList | Where-Object { -not (Test-Path -LiteralPath $_) }
  if ($missing) { throw ("Faltan SOP: " + ($missing -join ', ')) }

  # Fence/Here-strings sanity check (reporte)
  $checkPaths = @($piPath) + $sopList
  $report = $checkPaths | Test-FenceSafety | Format-Table -AutoSize | Out-String
  Append-GlobalChangeLog -Message 'Resultados Test-FenceSafety' -Extra $report

  Add-PAVCReport -RepoRoot $root
  Write-Output "Verificación aplicada (sin mutaciones de contenido)."
}
# [END MODULE: Project.Checks]

# [BEGIN MODULE: QualityGate]
function Get-PesterMajor {
  $m = Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1
  if ($m) { $m.Version.Major } else { 0 }
}
function Get-ThisScriptPath {
  if ($PSCommandPath) { return $PSCommandPath }
  if ($MyInvocation.MyCommand.Path) { return $MyInvocation.MyCommand.Path }
  if ($PSScriptRoot) { return (Join-Path $PSScriptRoot 'Verify_Project.ps1') }
  return $null
}
function Invoke-SerintraQualityGate {
  [CmdletBinding()]
  param([switch]$RunPSSA = $false,[switch]$RunPesterInline = $false)

  $hadFailure = $false
  $scriptPath = Get-ThisScriptPath

  if ($RunPSSA) {
    $pssa = Get-Module -ListAvailable -Name PSScriptAnalyzer
    if ($pssa) {
      try {
        Write-Output ">> PSSA: Analizando $scriptPath ..."
        $results = Invoke-ScriptAnalyzer -Path $scriptPath -Recurse -Severity @('Error','Warning')
        if ($results) {
          $hadFailure = $true
          $results | Select-Object RuleName,Severity,ScriptName,Line,Message | Format-Table -AutoSize | Out-String | Write-Output
          Append-GlobalChangeLog -Message "PSSA halló hallazgos en $scriptPath"
        } else {
          Write-Output ">> PSSA: Sin hallazgos."
        }
      } catch {
        $hadFailure = $true
        Write-Output ">> PSSA: Error — $($_.Exception.Message)"
        Append-GlobalChangeLog -Message "PSSA error: $($_.Exception.Message)"
      }
    } else {
      Write-Output ">> PSScriptAnalyzer no está instalado. Sugerido: Install-Module PSScriptAnalyzer -Scope CurrentUser -Force"
    }
  }

  if ($RunPesterInline) {
    $pv = Get-PesterMajor
    if ($pv -ge 5) {
      Write-Output ">> Pester v$pv: ejecutando pruebas inline..."
      $TempFile = Join-Path $env:TEMP ("temp_protocol_test_{0}.md" -f (New-Timestamp))
@"
A
# [BEGIN SECTION: test]
old
# [END SECTION: test]
Z
"@ | Set-Content -LiteralPath $TempFile -Encoding UTF8

      $ScriptBlock = {
        Describe 'HereStrings Utilities (Inline)' {
          It 'crea backup en append' {
            $r = Set-FileContentAppend -Path $using:TempFile -Content "`nappend" -Summary 'test append'
            ($r.Backup | Test-Path) | Should -BeTrue
          }
          It 'reemplaza entre marcadores' {
            $r = Set-FileContentReplaceBetweenMarkers -Path $using:TempFile -StartMarker '# [BEGIN SECTION: test]' -EndMarker '# [END SECTION: test]' -NewContent "new" -IncludeMarkers
            ($r.Backup | Test-Path) | Should -BeTrue
            (Get-Content -LiteralPath $using:TempFile -Raw) | Should -Match 'new'
          }
        }
      }
      try {
        $res = Invoke-Pester -Script @{ ScriptBlock = $ScriptBlock } -PassThru
        if ($res.FailedCount -gt 0) { $hadFailure = $true; Append-GlobalChangeLog -Message "Pester inline: pruebas fallidas." }
        else { Write-Output ">> Pester: OK." }
      } finally { Remove-Item -LiteralPath $TempFile -Force -ErrorAction SilentlyContinue }
    }
    elseif ($pv -gt 0) {
      Write-Output ">> Pester v$pv (legacy): sin pruebas inline; actualiza a v5 para ejecutar este gate."
    }
    else {
      Write-Output ">> Pester no está instalado. Sugerido: Install-Module Pester -Scope CurrentUser -Force"
    }
  }

  if ($hadFailure) { throw [Exception]::new('Quality Gate falló (PSSA o Pester).') }
}
# [END MODULE: QualityGate]

# [BEGIN MODULE: Edit.Utils]
function New-IncrementalBackup {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Path)
  $full = Resolve-Path -LiteralPath $Path -ErrorAction Stop
  $f = Get-Item -LiteralPath $full
  $dir = Ensure-Directory -Path (Join-Path $f.DirectoryName 'BACKUPS')
  $bak = Join-Path $dir ("{0}_{1}.bak" -f $f.BaseName,(New-Timestamp))
  Copy-Item -LiteralPath $f.FullName -Destination $bak -Force
  $bak
}
function Set-FileContentAppend {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$Content,[string]$Summary='Append content')
  $backup = New-IncrementalBackup -Path $Path
  Write-Utf8NoBom -Path $Path -Content $Content -Append
  $cl = Write-ChangeLog -TargetPath $Path -Mode 'Append' -Summary $Summary
  [pscustomobject]@{ Backup=$backup; Changelog=$cl; Path=(Resolve-Path $Path).Path }
}
function Set-FileContentReplaceBetweenMarkers {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$StartMarker,
    [Parameter(Mandatory)][string]$EndMarker,
    [Parameter(Mandatory)][string]$NewContent,
    [switch]$IncludeMarkers,
    [switch]$All,
    [string]$Summary='Replace between markers'
  )
  $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  $sm = [Regex]::Escape($StartMarker); $em = [Regex]::Escape($EndMarker)
  $pattern = if ($IncludeMarkers) { "(?s)$sm.*?$em" } else { "(?s)(?<=$sm).*?(?=$em)" }
  if (-not ([Regex]::IsMatch($text,$pattern))) { throw [ArgumentException]::new("Marcadores no encontrados en $Path") }

  $backup = New-IncrementalBackup -Path $Path
  $replacement = if ($IncludeMarkers) { "$StartMarker`r`n$NewContent`r`n$EndMarker" } else { $NewContent }
  $evaluator = [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $replacement }
  $newText = if ($All) { [Regex]::Replace($text,$pattern,$evaluator) } else { [Regex]::Replace($text,$pattern,$evaluator,1) }

  Write-Utf8NoBom -Path $Path -Content $newText
  $cl = Write-ChangeLog -TargetPath $Path -Mode 'ReplaceBetweenMarkers' -Summary $Summary
  [pscustomobject]@{ Backup=$backup; Changelog=$cl; Path=(Resolve-Path $Path).Path }
}
# [END MODULE: Edit.Utils]

# [BEGIN MODULE: Orchestration]
function Invoke-ProjectVerification {
  [CmdletBinding(SupportsShouldProcess)]
  param([string]$RepoRoot)

  $root = Resolve-RepoRoot -RepoRoot $RepoRoot
  $Script:GlobalChangeLogPath = Join-Path $root 'CHANGELOG.md'

  Invoke-ProjectChecks -RepoRoot $root -WhatIf:$false
  Write-Output "OK — Verify_Project v$Script:Version finalizado. $Script:PAVC_Tag"
}
# [END MODULE: Orchestration]

# [BEGIN MODULE: Entrypoint]
try {
  $resolvedRoot = Resolve-RepoRoot -RepoRoot $RepoRoot
  Invoke-ProjectVerification -RepoRoot $resolvedRoot -WhatIf:$false
  Invoke-SerintraQualityGate -RunPSSA:$RunPSSA -RunPesterInline:$RunInlineTests
}
catch {
  $msg = "ERROR — $($_.Exception.Message)"
  Write-Output $msg
  if ($resolvedRoot) {
    $Script:GlobalChangeLogPath = Join-Path $resolvedRoot 'CHANGELOG.md'
    Append-GlobalChangeLog -Message $msg
  }
  exit 1
}
# [END MODULE: Entrypoint]
'@

# --- Stub de compatibilidad para el nombre antiguo ---
$StubContent = @'
# Invoke-RepoReorg.ps1 (stub de compatibilidad)
# Redirige a Verify_Project.ps1 conservando parámetros/argumentos.
param([Parameter(ValueFromRemainingArguments=$true)][object[]]$Args)
$target = Join-Path $PSScriptRoot 'Verify_Project.ps1'
if (-not (Test-Path -LiteralPath $target)) { throw "Verify_Project.ps1 no encontrado en $PSScriptRoot" }
& $target @Args
'@

# --- Escribir nuevo archivo y stub ---
Write-Utf8NoBom -Path $NewPath -Content $VerifyProjectContent
Write-Utf8NoBom -Path $OldPath -Content $StubContent

# --- Registrar en CHANGELOG (Windows y espejo opcional) ---
$logEntry = @"
--------------------------------------------------------------------------------
$([DateTime]::UtcNow.ToString('u')) — Reorganización modular y renombrado
Backup original: $BackupPath
Archivo nuevo  : $NewPath
Stub creado    : $OldPath (redirige a Verify_Project.ps1)
Cambios: módulos con marcadores [BEGIN/END MODULE], normalización BACKUPS, reporte PAVC,
         utilidades de edición y logging, Quality Gate opcional (PSSA/Pester), compatibilidad PS5/PS7.
--------------------------------------------------------------------------------
"@
Write-Utf8NoBom -Path $ChangelogWin -Content $logEntry -Append
if (Test-Path -LiteralPath (Split-Path -Parent $ChangelogBot)) {
  Write-Utf8NoBom -Path $ChangelogBot -Content $logEntry -Append
}

Write-Host "OK — Verify_Project.ps1 creado y macroscript modularizado."
Write-Host "  Nuevo: $NewPath"
Write-Host "  Stub : $OldPath"
Write-Host "  Backup: $BackupPath"
```

### Salida (assistant)

Aquí va una lectura técnica y práctica del script **Patch-Verify_Project_Modularize.ps1**.

# ¿Qué hace en una frase?
Reemplaza el macroscript original **SCRIPTS\Invoke-RepoReorg.ps1** por un nuevo script modular **SCRIPTS\Verify_Project.ps1**, dejando un **stub** con el nombre viejo para compatibilidad, **respalda** el archivo original, y **documenta** los cambios en `CHANGELOG.md` (en el repo y, si existe, en el espejo `/mnt/data/Repo_AR`).

---

# Requisitos clave
- PowerShell **5.1** mínimo (`#requires -Version 5.1`).
- Debe existir `C:\Users\VictorFabianVeraVill\Desktop\Repo_AR\SCRIPTS\Invoke-RepoReorg.ps1`.
- Permisos de escritura en `Repo_AR` y subcarpetas.

---

# Flujo del patch (lo que hace al ejecutarse)
1. **Configura rutas** (Windows) y una **ruta espejo opcional** del CHANGELOG en `/mnt/data/Repo_AR/CHANGELOG.md`.
2. Define utilidades:
   - `New-TS()` (timestamp UTC).
   - `Ensure-Dir()` (asegura existencia de carpeta).
   - `Write-Utf8NoBom()` (escritura UTF-8 **sin BOM**, con/ sin append).
3. **Valida** que exista el script viejo `SCRIPTS\Invoke-RepoReorg.ps1`; si no, **lanza error** y termina.
4. **Respalda** el script viejo a `SCRIPTS\BACKUPS\Invoke-RepoReorg_<UTC>.bak`.
5. **Escribe** el nuevo **SCRIPTS\Verify_Project.ps1** (contenido largo, modular, ver abajo).
6. **Sobrescribe** `SCRIPTS\Invoke-RepoReorg.ps1` con un **stub** que reenvía todos los argumentos al nuevo `Verify_Project.ps1`.
7. **Asienta bitácora**: agrega un bloque con fecha UTC a `CHANGELOG.md` (Windows y espejo si está presente).
8. Muestra un **resumen en consola** con rutas del nuevo archivo, stub y backup.

> Idempotencia razonable: cada ejecución vuelve a crear backup con timestamp único, reescribe el nuevo script y el stub y **añade** una nueva entrada al changelog.

---

# ¿Qué contiene el nuevo Verify_Project.ps1?
Es un script **modular** con marcadores `# [BEGIN MODULE: ...]` / `# [END MODULE: ...]` pensado para parches granulares “replace between markers”. Principales piezas:

### 1) Parameters / Globals
- Parámetros: `-RepoRoot`, `-RunInlineTests`, `-RunPSSA`.
- Compatibilidad PS 5.1 y 7.x.
- Defaults (por ejemplo `DefaultRepoRoot` al escritorio del autor).
- Tag de compatibilidad: `PAVC-Compat (2025-09)`.

### 2) IO.Utils
- `Write-Utf8NoBom`, `New-Timestamp`.
- `Resolve-RepoRoot`: toma `-RepoRoot`, variable `ANASTASIS_REPO_ROOT` o default; valida existencia.
- `Ensure-Directory`: crea carpetas y devuelve ruta normalizada.

### 3) Logging
- `Append-GlobalChangeLog`: agrega entradas formateadas a `CHANGELOG.md` **global** del repo y (si existe) espejo `/mnt/data/Repo_AR/CHANGELOG.md`.
- `Write-ChangeLog`: crea un **changelog por archivo** en `<dir>\Changelogs\yyyyMMdd_HHmmssfff_<file>_<Mode>.md` y también anota en el global.

### 4) Safety.FenceCheck
- `Test-FenceSafety`: inspección de texto para “code fences” y here-strings:
  - Detecta **5 backticks** (sugiere usar 5 tildes `~~~~~`).
  - Here-strings cerrados con indentación (pide cierre en columna 1).
  - Uso de `-f` con `{}` (advierte duplicar llaves o evitar).
- Devuelve objetos con `Path` e `Issues`.

### 5) Reporting.PAVC
- `Add-PAVCReport`: inyecta en `CHANGELOG.md` un bloque “Contexto verificado” con puntos pendientes (PAVC), tanto en repo como espejo, y registra en global.

### 6) Project.Checks
- `Invoke-ProjectChecks`:
  - Resuelve RepoRoot y lo muestra.
  - **Normaliza** `SCRIPTS\Backups` → `SCRIPTS\BACKUPS` (si aplica) y registra en changelog (Mode: `Move`).
  - Valida estructura mínima:
    - `Project_Instructions.md`
    - `SOP\` y archivos: `SOP_Auditoria_Proyecto.md`, `SOP_CB_Blindado.md`, `SOP_Herestrings.md`, `SOP_AVC.md`.
    - Si faltan, **lanza error** detallando qué falta.
  - Corre `Test-FenceSafety` sobre PI y SOP; el reporte se adjunta al **global changelog**.
  - Llama a `Add-PAVCReport`.
  - Mensaje final: verificación aplicada **sin mutar contenido** (salvo la normalización de carpeta BACKUPS si era necesaria).

### 7) QualityGate
- Opcional según flags.
- `Invoke-SerintraQualityGate`:
  - **PSScriptAnalyzer** (`-RunPSSA`): analiza el propio script, muestra tabla de hallazgos y marca fallo del gate si hay errores/ warnings.
  - **Pester v5** (`-RunInlineTests`): crea un archivo temporal con marcadores y prueba utilidades de edición:
    - `Set-FileContentAppend` (debe crear backup).
    - `Set-FileContentReplaceBetweenMarkers` (reemplaza entre marcadores, con backup).
  - Si hay fallos/errores, **lanza excepción** “Quality Gate falló”.

### 8) Edit.Utils
- `New-IncrementalBackup`: crea backup con timestamp en **BACKUPS** al lado del archivo objetivo.
- `Set-FileContentAppend`: hace backup incremental, **append** de contenido y registro `Write-ChangeLog(Mode='Append')`.
- `Set-FileContentReplaceBetweenMarkers`: reemplazo por regex (incluyendo o no marcadores, con opción de reemplazar **primera** o **todas** las coincidencias), backup y `Write-ChangeLog(Mode='ReplaceBetweenMarkers')`.

### 9) Orchestration
- `Invoke-ProjectVerification`: fija `GlobalChangeLogPath`, llama a `Invoke-ProjectChecks` y anuncia versión/tag.

### 10) Entrypoint
- `try/catch`:
  - Resuelve RepoRoot, corre `Invoke-ProjectVerification`.
  - Corre **QualityGate** según flags.
  - En error: escribe `ERROR — …`, agrega entrada al **global changelog** y sale con código **1**.

---

# Archivos y carpetas tocadas
- **Lee/valida**:  
  - `RepoRoot\Project_Instructions.md`  
  - `RepoRoot\SOP\{SOP_Auditoria_Proyecto.md, SOP_CB_Blindado.md, SOP_Herestrings.md, SOP_AVC.md}`
- **Crea/normaliza**:  
  - `RepoRoot\SCRIPTS\Verify_Project.ps1` (nuevo)  
  - `RepoRoot\SCRIPTS\Invoke-RepoReorg.ps1` (**stub**)  
  - `RepoRoot\SCRIPTS\BACKUPS\Invoke-RepoReorg_<UTC>.bak` (backup del script viejo)  
  - `RepoRoot\SCRIPTS\BACKUPS\` (si no existe)  
  - `RepoRoot\SCRIPTS\Backups` → renombrado a `BACKUPS` (si existía)  
  - `RepoRoot\CHANGELOG.md` (**append** de entradas)  
  - `<carpeta de cada archivo editado>\Changelogs\*.md` (cuando usan utilidades de edición)  
  - **Espejo opcional**: `/mnt/data/Repo_AR/CHANGELOG.md` (append si existe la carpeta)

---

# Cómo se usa
1) Ejecutar el **patch** (una sola vez por migración):
```powershell
# En Windows PowerShell 5.1+
.\Patch-Verify_Project_Modularize.ps1
```

2) Usar el **nuevo verificador**:
```powershell
# Usando RepoRoot por defecto
.\SCRIPTS\Verify_Project.ps1

# O especificando ruta
.\SCRIPTS\Verify_Project.ps1 -RepoRoot 'C:\Users\...\Repo_AR'

# Con gates opcionales
.\SCRIPTS\Verify_Project.ps1 -RunPSSA -RunInlineTests
```

> El nombre viejo sigue funcionando:
```powershell
.\SCRIPTS\Invoke-RepoReorg.ps1 -RunPSSA
```
…porque ahora es un **stub** que reenvía a `Verify_Project.ps1`.

---

# Errores y casos borde
- Si **no existe** `SCRIPTS\Invoke-RepoReorg.ps1`, el patch **falla** (no intenta inventarlo; requiere versionar y dejar stub).
- Falta de permisos de escritura ⇒ errores al crear backup, escribir nuevos archivos o CHANGELOG.
- En `Verify_Project.ps1`:
  - Si faltan `Project_Instructions.md` o los SOP listados ⇒ **lanza error**.
  - Si no están instalados **PSScriptAnalyzer** o **Pester**, el gate lo informa y:
    - PSSA: sugiere `Install-Module PSScriptAnalyzer`.
    - Pester: sugiere `Install-Module Pester`.
    - Solo **falla** el gate si se pidió correrlos y hubo hallazgos/errores.

---

# Para qué te sirve
- **Estandariza** el verificador del repo en un script **modular** y parcheable por marcadores.
- **Conserva compatibilidad** con automatizaciones existentes (mantiene el nombre antiguo como stub).
- **Audita** estructura mínima del proyecto, **normaliza** `BACKUPS`, y deja **trazabilidad** en changelogs locales y espejo.
- Incluye un **Quality Gate** optativo para higiene del propio script y helpers de edición.

Si quieres, te preparo una **checklist de validación** para correr tras aplicar el patch y confirmar que todo quedó en orden.
