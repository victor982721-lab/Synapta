# Análisis y auditoría técnica

https://chat.openai.com/c/68da7d3b-a3c0-8333-a9c3-c6205402d5a1

## USER
Lee en su totalidad y analiza detalladamente lo siguiente:

~~~~~

# Protocolo de realización de parches a documentos y scripts.

---

# Primer Módulo – [INFO]

<Objetivo>
- Estandarizar el encabezado documental de cada script/SOP.
- Centralizar metadatos mínimos: Nombre, Sinopsis, Descripción, Compatibilidad, Autor, Versión, Fecha.
- Asegurar identidad, trazabilidad y control de cambios del artefacto.
- Habilitar consulta rápida vía Get-Help y uniformidad de auditoría.
</Objetivo>

<Resumen>
- No ejecuta lógica; funciona como cabecera formal del script.
- Comunica propósito, alcance y plataformas soportadas (Win10/11, PS 5.1/7.x).
- Identifica responsable y sincroniza versión/fecha con CHANGELOG.
- Favorece consistencia y lectura en todo el ciclo de vida.
</Resumen>

~~~~~
## [BEGIN MODULE: 1-INFO]

#requires -Version 5.1

<#
.NOMBRE
  - (Nombre del script o SOP)
.SINOPSIS
  - (Resumen corto en una sola línea)
.DESCRIPCION
  - (Explicación detallada, propósito del SOP o script)
.COMPATIBILIDAD
  - Windows 10/11
  - PowerShell 5.1 / 7.x
.AUTOR
  - (Nombre/alias del responsable)
.VERSION
  - 1.0.0
.FECHA
  - AAAA-MM-DD
#>

## [END MODULE: 1-INFO]
~~~~~

---

# Módulos 2A a 2E – Inicialización del Entorno

<Objetivo>
- Preparar un entorno controlado antes de cualquier lógica de negocio.
- Establecer política de ejecución (Real/Prueba), logging unificado y rutas estándar garantizadas.
- Dejar el contexto listo para verificación, parches y auditoría sin intervención manual.
</Objetivo>

<Resumen>
- Fase robusta y reproducible:
  - 2A: modo y preferencias globales (incl. dry-run).
  - 2B: logging central (consola/archivo).
  - 2C: validación de escritura.
  - 2D: estructura de rutas estándar.
  - 2E: consolidación en InitConfig.
- Resultado: inicialización auditable y lista para GUI.
</Resumen>

---

## 2A – [INIT-ENV]

<Objetivo>
- Determinar el modo de ejecución (Real/Prueba) por parámetro o auto-detección (REPO_AR_MODE/DEBUG/DRY_RUN).
- Exponer bandera global de simulación (RepoAR_IsDryRun).
- Aplicar StrictMode y preferencias globales para reducir ruido.
- Forzar I/O de consola en UTF-8 sin BOM.
- Publicar metadatos de inicialización (versión y modo).
</Objetivo>

<Resumen>
- Real: ErrorAction=Stop, DryRun=False.
- Prueba: ErrorAction=Continue, DryRun=True (advertido).
- Silencia Warning/Information/Verbose/Progress y normaliza codificación.
- Punto único de verdad del “modo” para el resto del flujo.
</Resumen>

~~~~~
## [BEGIN MODULE: 2A-INIT-ENV]
[CmdletBinding()]
param(
  [AllowNull()]
  [ValidateSet('Real','Prueba')]
  [string]$Modo
)

Set-StrictMode -Version 3.0

# --- Auto-detección de modo ---
if ([string]::IsNullOrWhiteSpace($Modo)) {
  if ($env:REPO_AR_MODE -ieq 'Prueba' -or $env:DEBUG -or $env:DRY_RUN) { $Modo = 'Prueba' } else { $Modo = 'Real' }
}
# Normalizar a las únicas opciones permitidas (case-insensitive)
$Modo = @('Real','Prueba') | Where-Object { $_ -ieq $Modo } | Select-Object -First 1
if (-not $Modo) { $Modo = 'Real' }

# --- Preferencias globales + DRY-RUN ---
switch ($Modo) {
  'Real' {
    $PSDefaultParameterValues['*:ErrorAction'] = 'Stop'
    $ErrorActionPreference = 'Stop'
    $Global:RepoAR_IsDryRun = $false
  }
  'Prueba' {
    $PSDefaultParameterValues['*:ErrorAction'] = 'Continue'
    $ErrorActionPreference = 'Continue'
    $Global:RepoAR_IsDryRun = $true
    Write-Warning "Modo PRUEBA activo → se simularán operaciones (dry-run)."
  }
}
$PSDefaultParameterValues['*:WarningAction']     = 'SilentlyContinue'
$PSDefaultParameterValues['*:InformationAction'] = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$VerbosePreference     = 'SilentlyContinue'
$ProgressPreference    = 'SilentlyContinue'

# --- Consola/IO UTF-8 sin BOM ---
try {
  [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
  [Console]::InputEncoding  = [System.Text.UTF8Encoding]::new($false)
  $OutputEncoding           = [System.Text.UTF8Encoding]::new($false)
} catch { }

# --- Versionado/diagnóstico ---
$Global:RepoAR_InitModuleVersion = '2.1.2'
$Global:RepoAR_InitModo          = $Modo
## [END MODULE: 2A-INIT-ENV]
~~~~~

---

# 2B – [INIT-LOG]

<Objetivo>
- Proveer logger unificado con niveles (Info/Warn/Error/DryRun/Debug).
- Integrarse con -Verbose/-Debug sin romper el output.
- Registrar opcionalmente a archivo en VERIFICATION (UTF-8 sin BOM).
- Operar en modo simulación sin escribir a disco.
</Objetivo>

<Resumen>
- Consola con prefijos y colores; Error corta ejecución de forma controlada.
- Archivo: init_<ExecTS>.log en VerifyDir cuando LogToFile=True.
- Crea (o simula) carpeta de logs; robusto ante fallas de I/O.
- Interface mínima y estable: Write-Log -Level ... -Message "…".
</Resumen>

~~~~~
## [BEGIN MODULE: 2B-INIT-LOG]
function Write-Log {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][ValidateSet('Info','Warn','Error','DryRun','Debug')]
    [string]$Level,
    [Parameter(Mandatory)][string]$Message,
    [switch]$NoFile
  )

  $prefix = switch ($Level) {
    'Info'   { '[INFO] ' }
    'Warn'   { '[WARN] ' }
    'Error'  { '[ERROR] ' }
    'DryRun' { '[DRY-RUN] ' }
    'Debug'  { '[DEBUG] ' }
  }
  $text = "$prefix$Message"

  switch ($Level) {
    'Info'   { Write-Host $text }
    'Warn'   { Write-Warning $Message }
    'Error'  { Write-Error $Message -ErrorAction Stop }
    'DryRun' { Write-Host $text -ForegroundColor Yellow }
    'Debug'  { Write-Host $text -ForegroundColor DarkGray; Write-Debug $Message }
  }
  if ($Level -eq 'Info') { Write-Verbose $Message }

  if (-not $NoFile -and $Global:RepoAR_InitConfig -and $Global:RepoAR_InitConfig.LogToFile -and -not $Global:RepoAR_IsDryRun) {
    try {
      $logFile = if ($Global:RepoAR_InitConfig.ContainsKey('LogFilePath') -and $Global:RepoAR_InitConfig.LogFilePath) {
        $Global:RepoAR_InitConfig.LogFilePath
      } else {
        Join-Path $Global:RepoAR_InitConfig.VerifyDir ("init_{0}.log" -f $Global:RepoAR_ExecTS)
      }
      $dir = Split-Path -Parent $logFile
      if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

      $enc = New-Object System.Text.UTF8Encoding($false)
      $sw  = New-Object System.IO.StreamWriter($logFile, $true, $enc)
      $sw.WriteLine("{0} {1}" -f (Get-Date -Format s), $text)
      $sw.Dispose()
    } catch {
      Write-Warning "No se pudo escribir en log de archivo. Detalle: $($_.Exception.Message)"
    }
  }
}
## [END MODULE: 2B-INIT-LOG]
~~~~~

---

# 2C – [INIT-CHECKS]

<Objetivo>
- Diagnosticar si una ruta es escribible de forma segura.
- Respetar el modo: prueba efectiva en Real, simulación en Prueba.
- Retornar booleano claro y registrar detalles vía Write-Log.
- No dejar residuos (archivo temporal autocontenido).
</Objetivo>

<Resumen>
- Ruta inexistente → False inmediato.
- Dry-run → omite prueba real, loguea y retorna True.
- Real → crea/escribe/borra .writetest_<GUID>.tmp (UTF-8 sin BOM).
- Excepción → Warn y False. No eleva privilegios ni corrige permisos.
</Resumen>

~~~~~
## [BEGIN MODULE: 2C-INIT-CHECKS]
function Test-PathWritable {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) { return $false }
  if ($Global:RepoAR_IsDryRun) {
    Write-Log -Level DryRun -Message "Omitida prueba de escritura en '$Path' (modo prueba)."
    return $true
  }
  try {
    $testFile = Join-Path $Path ('.writetest_{0}.tmp' -f ([guid]::NewGuid()))
    [IO.File]::WriteAllText($testFile,'x',[Text.UTF8Encoding]::new($false))
    Remove-Item -LiteralPath $testFile -Force -ErrorAction Stop
    return $true
  } catch {
    Write-Log -Level Warn -Message "Ruta no escribible: '$Path'. Detalle: $($_.Exception.Message)"
    return $false
  }
}
## [END MODULE: 2C-INIT-CHECKS]
~~~~~

---

# 2D – [INIT-PATHS]

<Objetivo>
- Resolver RepoRoot por parámetro o autodetección (PSScriptRoot/PSCommandPath/Location).
- Importar settings opcionales (.psd1) y aplicar overrides seguros.
- Garantizar estructura estándar: SCRIPTS, SCRIPTS\BACKUPS, VERIFICATION.
- Normalizar rutas y validar escritura en modo Real (fail-fast).
- Exponer rutas, settings, flags y ExecTS al resto del flujo.
</Objetivo>

<Resumen>
- Autonomía total: crea o simula carpetas según dry-run.
- Overrides declarativos desde RepoSettings.psd1 si no hubo parámetro.
- Verifica writability en Real; reporta omisión en Prueba.
- Publica _RepoRoot/_ScriptsDir/_BackupsDir/_VerifyDir/_Settings/_RunVerification + ExecTS.
</Resumen>

~~~~~
## [BEGIN MODULE: 2D-INIT-PATHS]
param(
  [string]$RepoRoot = $null,
  [switch]$RunVerification
)

# RepoRoot
if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  if ($PSScriptRoot) { $RepoRoot = $PSScriptRoot }
  elseif ($PSCommandPath) { $RepoRoot = Split-Path -Parent $PSCommandPath }
  else { $RepoRoot = (Get-Location).Path }
}

# Settings opcionales
$settings = $null
try {
  $candidates = @(
    (Join-Path $RepoRoot 'RepoSettings.psd1'),
    (Join-Path $RepoRoot 'Config\RepoSettings.psd1'),
    (Join-Path $RepoRoot '.repo\RepoSettings.psd1')
  )
  foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c) { $settings = Import-PowerShellDataFile -LiteralPath $c -ErrorAction Stop; break }
  }
} catch { Write-Log -Level Warn -Message "No se pudo importar settings: $($_.Exception.Message)" }

if ($settings -and $settings.RepoRoot -and -not $PSBoundParameters.ContainsKey('RepoRoot')) {
  $RepoRoot = $settings.RepoRoot
  Write-Log -Level Info -Message "RepoRoot sobreescrito por settings: $RepoRoot"
}

# Garantiza RepoRoot
if (-not (Test-Path -LiteralPath $RepoRoot)) {
  if ($Global:RepoAR_IsDryRun) { Write-Log -Level DryRun -Message "Crearía RepoRoot: $RepoRoot" }
  else { New-Item -ItemType Directory -Path $RepoRoot -Force | Out-Null }
}
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

# Rutas estándar
$ScriptsDir = Join-Path $RepoRoot 'SCRIPTS'
$BackupsDir = Join-Path $ScriptsDir 'BACKUPS'
$VerifyDir  = Join-Path $RepoRoot 'VERIFICATION'
foreach ($dir in @($ScriptsDir,$BackupsDir,$VerifyDir)) {
  if (-not (Test-Path -LiteralPath $dir)) {
    if ($Global:RepoAR_IsDryRun) { Write-Log -Level DryRun -Message "Crearía directorio: $dir" }
    else { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  }
}

# Fail-fast de escritura (solo Real)
if (-not $Global:RepoAR_IsDryRun) {
  foreach ($dir in @($RepoRoot,$ScriptsDir,$BackupsDir,$VerifyDir)) {
    if (-not (Test-PathWritable -Path $dir)) { throw "Ruta no escribible: $dir" }
  }
} else {
  Write-Log -Level DryRun -Message "Chequeos de escritura omitidos (modo prueba)."
}

# Timestamp
$Global:RepoAR_ExecTS = [DateTime]::UtcNow.ToString('yyyyMMdd_HHmmssfff')

# Exporta variables para 2E
$Global:RepoAR_RepoRoot        = $RepoRoot
$Global:RepoAR_ScriptsDir      = $ScriptsDir
$Global:RepoAR_BackupsDir      = $BackupsDir
$Global:RepoAR_VerifyDir       = $VerifyDir
$Global:RepoAR_Settings        = $settings
$Global:RepoAR_RunVerification = [bool]$RunVerification
## [END MODULE: 2D-INIT-PATHS]
~~~~~

---

# 2E – [INIT-CONFIG]

<Objetivo>
- Consolidar el estado de inicialización en RepoAR_InitConfig.
- Incluir campos clave: Version, Modo, IsDryRun, RepoRoot, ScriptsDir, BackupsDir, VerifyDir, ExecTS, RunVerification, Settings, LogToFile, LogFilePath, IsReadOnly.
- Proteger la variable en modo Real (ReadOnly) y registrar un resumen del estado.
</Objetivo>

<Resumen>
- Construye objeto de configuración único para consumo por GUI y módulos.
- Determina LogToFile/LogFilePath sin forzar escritura en Dry-run.
- En Real marca la variable global como ReadOnly (estructura estable).
- Emite log de estado: modo, dry-run, ruta raíz y readonly.
</Resumen>

~~~~~
## [BEGIN MODULE: 2E-INIT-CONFIG]
# Derivados de módulos previos (2A/2B/2D)
$logToFile   = ($Global:RepoAR_Settings -and $Global:RepoAR_Settings.ContainsKey('LogToFile')) `
               ? [bool]$Global:RepoAR_Settings.LogToFile : $false
$logFilePath = Join-Path $Global:RepoAR_VerifyDir ("init_{0}.log" -f $Global:RepoAR_ExecTS)

# Construir el objeto de config
$cfg = [ordered]@{
  Version         = $Global:RepoAR_InitModuleVersion
  Modo            = $Global:RepoAR_InitModo
  IsDryRun        = [bool]$Global:RepoAR_IsDryRun
  RepoRoot        = $Global:RepoAR_RepoRoot
  ScriptsDir      = $Global:RepoAR_ScriptsDir
  BackupsDir      = $Global:RepoAR_BackupsDir
  VerifyDir       = $Global:RepoAR_VerifyDir
  ExecTS          = $Global:RepoAR_ExecTS
  RunVerification = $Global:RepoAR_RunVerification
  Settings        = $Global:RepoAR_Settings
  LogToFile       = $logToFile
  LogFilePath     = $logFilePath
  IsReadOnly      = -not $Global:RepoAR_IsDryRun
}

$Global:RepoAR_InitConfig = $cfg

# Evita que se reemplace la variable completa en modo Real (la estructura interna sigue siendo mutable)
if (-not $Global:RepoAR_IsDryRun) {
  Set-Variable -Name RepoAR_InitConfig -Scope Global -Option ReadOnly -Force -Value $Global:RepoAR_InitConfig
}

Write-Log -Level Info `
  -Message ("INIT listo. Modo={0}; DryRun={1}; RepoRoot='{2}'; ReadOnly={3}." -f `
    $Global:RepoAR_InitConfig.Modo, `
    $Global:RepoAR_InitConfig.IsDryRun, `
    $Global:RepoAR_InitConfig.RepoRoot, `
    $Global:RepoAR_InitConfig.IsReadOnly) `
  -NoFile:$($Global:RepoAR_IsDryRun -or -not $Global:RepoAR_InitConfig.LogToFile)
## [END MODULE: 2E-INIT-CONFIG]
~~~~~


~~~~~
## [BEGIN MODULE: 3A-UTILS-CORE]
Set-StrictMode -Version 3.0
using namespace System
using namespace System.Globalization
using namespace System.IO

# Timestamp UTC/Local con cultura invariable
function RepoAR-NewTS {
  [CmdletBinding()]
  param(
    [Parameter()][ValidateNotNullOrEmpty()][string]$Format = 'yyyyMMdd_HHmmssfff',
    [ValidateSet('Utc','Local')][string]$Kind = 'Utc'
  )
  try {
    $dt = if ($Kind -eq 'Utc') { [DateTime]::UtcNow } else { [DateTime]::Now }
    return $dt.ToString($Format, [CultureInfo]::InvariantCulture)
  } catch {
    throw "RepoAR-NewTS: error al formatear timestamp. Detalle: $($_.Exception.Message)"
  }
}

# Crea carpeta si no existe y devuelve ruta resuelta; valida colisiones con archivos
function RepoAR-EnsureDir {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()][string]$Path,
    [ValidateSet('String','DirectoryInfo')][string]$As = 'String'
  )
  process {
    $p = $Path.Trim()
    if ([string]::IsNullOrWhiteSpace($p)) { throw "RepoAR-EnsureDir(Path): valor vacío." }
    if ($p.IndexOfAny([Path]::GetInvalidPathChars()) -ge 0) { throw "RepoAR-EnsureDir(Path): caracteres inválidos." }
    if (Test-Path -LiteralPath $p -PathType Leaf) { throw "RepoAR-EnsureDir(Path): ya existe un archivo en '$p'." }

    $exists = Test-Path -LiteralPath $p -PathType Container
    if (-not $exists) {
      if ($Global:RepoAR_IsDryRun) {
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) { Write-Log -Level DryRun -Message "Crearía directorio: $p" } else { Write-Host "[DRY-RUN] Crearía directorio: $p" }
      } elseif ($PSCmdlet.ShouldProcess($p, 'Crear directorio')) {
        New-Item -ItemType Directory -Path $p -Force -ErrorAction Stop | Out-Null
      }
    }

    $resolved = Resolve-Path -LiteralPath $p -ErrorAction SilentlyContinue
    $full = if ($resolved) { $resolved.ProviderPath } else {
      if ([Path]::IsPathRooted($p)) { [Path]::GetFullPath($p) } else { [Path]::GetFullPath((Join-Path (Get-Location).Path $p)) }
    }
    if ($As -eq 'DirectoryInfo') { return [DirectoryInfo]::new($full) } else { return $full }
  }
}
## [END MODULE: 3A-UTILS-CORE]
~~~~~


~~~~~
## [BEGIN MODULE: 3B-UTILS-IO]
Set-StrictMode -Version 3.0
using namespace System.Text
using namespace System.IO

# Escritura UTF-8 sin BOM con Append/NoClobber, respeta DRY-RUN y ShouldProcess
function RepoAR-WriteUtf8NoBom {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path,
    [Parameter(Mandatory)][string]$Content,
    [switch]$Append,
    [switch]$NoClobber
  )

  $dir = Split-Path -Parent $Path
  if ($dir) { RepoAR-EnsureDir -Path $dir | Out-Null }

  if ($NoClobber -and (Test-Path -LiteralPath $Path -PathType Leaf) -and -not $Append) {
    throw "RepoAR-WriteUtf8NoBom: '$Path' ya existe y -NoClobber está activo."
  }

  if ($Global:RepoAR_IsDryRun) {
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
      Write-Log -Level DryRun -Message ("{0} archivo (UTF-8 sin BOM): {1}" -f ($(if($Append){'Anexaría'}else{'Escribiría'}), $Path))
    } else { Write-Host ("[DRY-RUN] {0}: {1}" -f ($(if($Append){'Append'}else{'Write'}), $Path)) }
    return $Path
  }

  $enc = [UTF8Encoding]::new($false)
  if ($PSCmdlet.ShouldProcess($Path, $(if ($Append) { "Append UTF-8 (no BOM)" } else { "Write UTF-8 (no BOM)" }))) {
    if ($Append -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
      $sw = [StreamWriter]::new($Path, $true, $enc); try { $sw.Write($Content) } finally { $sw.Dispose() }
    } else {
      [File]::WriteAllText($Path, $Content, $enc)
    }
  }
  return $Path
}
## [END MODULE: 3B-UTILS-IO]
~~~~~


~~~~~
## [BEGIN MODULE: 3C-BACKUP-POLICY]
Set-StrictMode -Version 3.0
using namespace System
using namespace System.IO

# Política global por defecto (se crea si no existe). Ajusta una vez y aplica en todo el entorno.
if (-not $Global:RepoAR_BackupPolicy) {
  $Global:RepoAR_BackupPolicy = [ordered]@{
    MirrorEnabled      = $true
    MirrorDir          = $Global:RepoAR_BackupsDir
    AutoCompress       = $true
    CompressDirs       = $true
    CompressMinSizeKB  = 64
    CompressFileExts   = @('.txt','.log','.json','.csv','.xml','.yml','.yaml','.ps1','.psm1','.md','.ini','.cfg','.conf')
  }
}

function RepoAR-GetBackupPolicy {
  [CmdletBinding()] param() 
  return $Global:RepoAR_BackupPolicy
}

# Decide compresión automática según política, tipo y tamaño/extensión
function RepoAR-ShouldCompress {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$TargetPath,
    [Parameter()][hashtable]$Policy = (RepoAR-GetBackupPolicy)
  )
  if (-not $Policy.AutoCompress) { return $false }
  $isFile = Test-Path -LiteralPath $TargetPath -PathType Leaf
  $isDir  = Test-Path -LiteralPath $TargetPath -PathType Container
  if ($isDir) { return [bool]$Policy.CompressDirs }
  if (-not $isFile) { return $false }

  $ext = ([Path]::GetExtension($TargetPath) ?? '').ToLowerInvariant()
  if ($Policy.CompressFileExts -contains $ext) {
    try { $lenKB = [math]::Ceiling((Get-Item -LiteralPath $TargetPath -ErrorAction Stop).Length / 1KB) } catch { return $false }
    return ($lenKB -ge [int]$Policy.CompressMinSizeKB)
  }
  return $false
}
## [END MODULE: 3C-BACKUP-POLICY]
~~~~~


~~~~~
## [BEGIN MODULE: 3D-BACKUP]
Set-StrictMode -Version 3.0
using namespace System.IO
using namespace System.IO.Compression

# Backup automático (copia cruda o ZIP) con espejo opcional por política; respeta DRY-RUN y -WhatIf/-Confirm
function RepoAR-BackupIfExists {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
  param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$TargetPath,
    [string]$MirrorBackupDir,
    [ValidatePattern('^[\w.-]+$')][string]$Suffix = 'bak',
    [switch]$Compress,      # fuerza ZIP
    [switch]$NoCompress,    # fuerza copia cruda
    [string]$ZipFileName    # opcional: nombre de .zip (sin ruta)
  )
  if (-not (Test-Path -LiteralPath $TargetPath)) { return $null }

  $policy = RepoAR-GetBackupPolicy
  $isFile = Test-Path -LiteralPath $TargetPath -PathType Leaf
  $isDir  = Test-Path -LiteralPath $TargetPath -PathType Container
  if (-not ($isFile -or $isDir)) { throw "RepoAR-BackupIfExists: tipo de destino desconocido '$TargetPath'." }

  # Mirror automático si no se especifica
  if (-not $PSBoundParameters.ContainsKey('MirrorBackupDir')) {
    if ($policy.MirrorEnabled -and $policy.MirrorDir) { $MirrorBackupDir = $policy.MirrorDir }
  }

  # Compresión automática si no se fuerza
  if (-not ($PSBoundParameters.ContainsKey('Compress') -or $PSBoundParameters.ContainsKey('NoCompress'))) {
    $Compress = RepoAR-ShouldCompress -TargetPath $TargetPath -Policy $policy
  } elseif ($PSBoundParameters.ContainsKey('NoCompress')) {
    $Compress = $false
  }

  $ts   = RepoAR-NewTS
  $name = Split-Path -Path $TargetPath -Leaf

  if ($Compress) {
    $primaryBak = if ($ZipFileName) {
      Join-Path (Split-Path -Parent $TargetPath) $ZipFileName
    } else { "$TargetPath.$ts.zip" }
  } else {
    $primaryBak = "$TargetPath.$ts.$Suffix"
  }

  $mirrorBak = $null
  if ($MirrorBackupDir) {
    $mirrorDir = RepoAR-EnsureDir -Path $MirrorBackupDir
    $mirrorBak = if ($Compress) { Join-Path $mirrorDir ($(if ($ZipFileName) { $ZipFileName } else { "$name.$ts.zip" })) }
                 else            { Join-Path $mirrorDir "$name.$ts.$Suffix" }
  }

  $op1 = if ($Compress) { "ZIP → '$primaryBak'" } else { "Backup → '$primaryBak'" }
  $op2 = if ($mirrorBak) { if ($Compress) { "ZIP espejo → '$mirrorBak'" } else { "Backup espejo → '$mirrorBak'" } }

  if ($Global:RepoAR_IsDryRun) {
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) { Write-Log -Level DryRun -Message $op1; if ($op2){ Write-Log -Level DryRun -Message $op2 } }
    else { Write-Host "[DRY-RUN] $op1"; if ($op2){ Write-Host "[DRY-RUN] $op2" } }
  } else {
    if ($Compress) {
      try { Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop } catch {}
      if ($PSCmdlet.ShouldProcess($TargetPath, $op1)) {
        if (Test-Path -LiteralPath $primaryBak) { Remove-Item -LiteralPath $primaryBak -Force }
        if ($isDir) { [ZipFile]::CreateFromDirectory($TargetPath, $primaryBak) }
        else {
          $zip = [ZipFile]::Open($primaryBak, [ZipArchiveMode]::Create)
          try { [ZipFileExtensions]::CreateEntryFromFile($zip, $TargetPath, $name) } finally { $zip.Dispose() }
        }
      }
      if ($mirrorBak -and $PSCmdlet.ShouldProcess($TargetPath, $op2)) {
        if (Test-Path -LiteralPath $mirrorBak) { Remove-Item -LiteralPath $mirrorBak -Force }
        if ($isDir) { [ZipFile]::CreateFromDirectory($TargetPath, $mirrorBak) }
        else {
          $zip2 = [ZipFile]::Open($mirrorBak, [ZipArchiveMode]::Create)
          try { [ZipFileExtensions]::CreateEntryFromFile($zip2, $TargetPath, $name) } finally { $zip2.Dispose() }
        }
      }
    } else {
      if ($PSCmdlet.ShouldProcess($TargetPath, $op1)) {
        Copy-Item -LiteralPath $TargetPath -Destination $primaryBak -Recurse:($isDir) -Force -Container:($isDir) -ErrorAction Stop
      }
      if ($mirrorBak -and $PSCmdlet.ShouldProcess($TargetPath, $op2)) {
        Copy-Item -LiteralPath $TargetPath -Destination $mirrorBak -Recurse:($isDir) -Force -Container:($isDir) -ErrorAction Stop
      }
    }
  }

  [pscustomobject]@{
    TargetPath        = (Resolve-Path -LiteralPath $TargetPath).Path
    Type              = if ($isFile) { 'File' } else { 'Directory' }
    Compressed        = [bool]$Compress
    PrimaryBackupPath = $primaryBak
    MirrorBackupPath  = $mirrorBak
    TimestampUtc      = $ts
    PolicyUsed        = $policy
  }
}
## [END MODULE: 3D-BACKUP]
~~~~~

~~~~~
## [BEGIN MODULE: 3E-ALIASES]
Set-StrictMode -Version 3.0

# Aliases de compatibilidad para no romper scripts existentes
Set-Alias -Name New-TS           -Value RepoAR-NewTS           -Scope Local -Force
Set-Alias -Name Ensure-Dir       -Value RepoAR-EnsureDir       -Scope Local -Force
Set-Alias -Name Write-Utf8NoBom  -Value RepoAR-WriteUtf8NoBom  -Scope Local -Force
Set-Alias -Name Backup-IfExists  -Value RepoAR-BackupIfExists  -Scope Local -Force
## [END MODULE: 3E-ALIASES]
~~~~~

~~~~~
## [BEGIN MODULE: 4A-PATHS-DEFINE]
Set-StrictMode -Version 3.0
using namespace System.IO

# 1) Resolver RepoRoot desde el entorno (orden de prioridad)
$repoRoot = $Global:RepoAR_RepoRoot
if (-not $repoRoot -and (Get-Variable -Name RepoRoot -Scope Global -ErrorAction SilentlyContinue)) { $repoRoot = $Global:RepoRoot }
if (-not $repoRoot -and $env:REPO_AR_ROOT) { $repoRoot = $env:REPO_AR_ROOT }
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }

# Normalizar a ruta absoluta
try { $repoRoot = [Path]::GetFullPath($repoRoot) } catch { }

# 2) Construir tabla de rutas (sin barras embebidas; usamos Join-Path por segmentos)
$Global:RepoAR_Paths = [ordered]@{
  RepoRoot            = $repoRoot
  ProjectInstructions = Join-Path $repoRoot 'Project_Instructions.md'
  SOP                 = Join-Path $repoRoot 'SOP'
  SOP_Backups         = Join-Path (Join-Path $repoRoot 'SOP') 'BACKUPS'
  Manual              = Join-Path (Join-Path $repoRoot 'SOP') 'SOP_Manual_Operativo_Repo_AR.md'
  Verification        = Join-Path $repoRoot 'VERIFICATION'
  Scripts             = Join-Path $repoRoot 'SCRIPTS'
  Backups             = Join-Path (Join-Path $repoRoot 'SCRIPTS') 'BACKUPS'
  PSSA_Settings       = Join-Path $repoRoot 'PSScriptAnalyzerSettings.psd1'
  Changelog           = Join-Path $repoRoot 'CHANGELOG.md'
}
## [END MODULE: 4A-PATHS-DEFINE]
~~~~~

~~~~~
## [BEGIN MODULE: 4B-PATHS-ENSURE&EXPORT]
Set-StrictMode -Version 3.0

# 3) Asegurar carpetas base (respetando DRY-RUN y ShouldProcess del 3A-UTILS-CORE)
$null = RepoAR-EnsureDir -Path $Global:RepoAR_Paths.RepoRoot
$null = RepoAR-EnsureDir -Path $Global:RepoAR_Paths.SOP
$null = RepoAR-EnsureDir -Path $Global:RepoAR_Paths.SOP_Backups
$null = RepoAR-EnsureDir -Path $Global:RepoAR_Paths.Verification
$null = RepoAR-EnsureDir -Path $Global:RepoAR_Paths.Scripts
$null = RepoAR-EnsureDir -Path $Global:RepoAR_Paths.Backups

# 4) Exportar variables de compatibilidad (evita romper scripts existentes)
Set-Variable -Scope Global -Name Path_ProjectInstructions -Value $Global:RepoAR_Paths.ProjectInstructions -Force
Set-Variable -Scope Global -Name Path_SOP                 -Value $Global:RepoAR_Paths.SOP                 -Force
Set-Variable -Scope Global -Name Path_SOP_Backups         -Value $Global:RepoAR_Paths.SOP_Backups         -Force
Set-Variable -Scope Global -Name Path_Manual              -Value $Global:RepoAR_Paths.Manual              -Force
Set-Variable -Scope Global -Name Path_VERIFICATION        -Value $Global:RepoAR_Paths.Verification        -Force
Set-Variable -Scope Global -Name Path_BACKUPS             -Value $Global:RepoAR_Paths.Backups             -Force
Set-Variable -Scope Global -Name Path_PSSA_Settings       -Value $Global:RepoAR_Paths.PSSA_Settings       -Force
Set-Variable -Scope Global -Name Path_CHANGELOG           -Value $Global:RepoAR_Paths.Changelog           -Force

# 5) Endurecer en modo Real: impedir reemplazo accidental del objeto de paths
if (-not $Global:RepoAR_IsDryRun) {
  Set-Variable -Name RepoAR_Paths -Scope Global -Option ReadOnly -Force -Value $Global:RepoAR_Paths
}
## [END MODULE: 4B-PATHS-ENSURE&EXPORT]
~~~~~


~~~~~
## [BEGIN MODULE: 5A-DOCS-PI]  # Project Instructions (mejorado)
# Solo contenido (plantilla); sin lógica.
$Content_ProjectInstructions = @'
---
id: project_instructions
doc_type: "policy"
status: "active"
title: "Project Instructions — Repo_AR"
version: "{{DOC_VERSION}}"
owners: ["{{OWNER_NAME}}"]
last_update_utc: "{{UTC_ISO}}"
source_module: "DocContents/5A-DOCS-PI"
path_target: "{{PATH_ProjectInstructions}}"
checksum_sha256: "{{CHECKSUM_PLACEHOLDER}}"
tags: ["devops","sop","quality-gate","powershell"]
requires:
  - "Windows 10/11 + PowerShell 5/7"
  - "PSScriptAnalyzer"
  - "Pester v5"
links:
  sop_manual: "{{PATH_SOP}}/SOP_Manual_Operativo_Repo_AR.md"
  verification_dir: "{{PATH_Verification}}"
  backups_dir: "{{PATH_BACKUPS}}"
policy:
  backups:
    strategy: "pre-change .bak + mirror"
    mirror_dir: "{{PATH_BACKUPS}}"
    retention: { days: 30, max_gb: 1 }
  quality_gate:
    pssa_errors: 0
    pssa_warnings_max: 10
    pester_failures: 0
    manifest_valid: true
outputs:
  - "{{PATH_Verification}}/psscriptanalyzer.json"
  - "{{PATH_Verification}}/psscriptanalyzer.sarif"
  - "{{PATH_Verification}}/TestResult.xml"
---

# Project Instructions — Repo_AR ({{DOC_VERSION}})

> **Propósito:** establecer políticas, estructura y flujos para generar/parchear artefactos con **respaldo automático** y **verificación** reproducible.

## 1. Alcance y exclusiones
- **Alcance:** operación individual en Windows + PowerShell 5/7; scripts y documentos del repo.
- **Exclusiones:** CI/CD, distribución multi-equipo, secretos/credenciales.

## 2. Principios operativos
1. **Accionable:** todo artefacto debe poder ejecutarse/consumirse sin pasos manuales adicionales.
2. **Backup previo:** `.bak` local + espejo en `{{PATH_BACKUPS}}`.
3. **Verificado:** PSSA (JSON/SARIF), Pester (NUnit), manifiestos `.psd1`.
4. **Quality Gate:** umbrales definidos en este documento (ver front matter → `policy.quality_gate`).
5. **Trazable:** entradas inmutables en `CHANGELOG.md` con versión y UTC.
6. **Blindado:** here-strings en comillas simples; cierre en columna 1; UTF-8 sin BOM.
7. **Estandarizado:** rutas con `Join-Path`; sin hardcodeos.

## 3. Estructura del repo (funcional)
- `Project_Instructions.md` (esta guía)
- `CHANGELOG.md`
- `PSScriptAnalyzerSettings.psd1`
- `VERIFICATION\` (salidas PSSA/Pester)
- `SCRIPTS\BACKUPS\` (espejo de backups)
- `SOP\` (procedimientos operativos)

## 4. Flujo mínimo
1. Preparar parche (total o por módulos marcados).
2. **Hacer backup** (automático por macroscript).
3. Aplicar parche.
4. Ejecutar verificaciones (PSSA/Pester/Manifiestos).
5. Registrar `CHANGELOG.md` (versión + descripción).

## 5. Aceptación (Quality Gate)
- PSSA: **Errores = 0**, **Warnings ≤** `policy.quality_gate.pssa_warnings_max`.
- Pester: **Fail = 0**.
- Manifiestos `.psd1`: **válidos**.

## 6. Buenas prácticas
- Evitar rutas absolutas de usuario en ejemplos; usar las definidas por el repo.
- Mantener títulos y secciones consistentes (H1-H3).
- Un cambio = una entrada en `CHANGELOG.md`.

## 7. Anexos
- **Salidas esperadas:** ver `outputs` en front matter.
- **Retención de backups:** ver `policy.backups.retention`.
'@
## [END MODULE: 5A-DOCS-PI]
~~~~~

~~~~~
## [BEGIN MODULE: 5B-DOCS-MANUAL]  # SOP Manual (mejorado)
$Content_Manual = @'
---
id: sop_manual_operativo
doc_type: "sop"
status: "active"
title: "SOP — Manual Operativo Repo_AR"
version: "{{DOC_VERSION}}"
owners: ["{{OWNER_NAME}}"]
last_update_utc: "{{UTC_ISO}}"
source_module: "DocContents/5B-DOCS-MANUAL"
path_target: "{{PATH_SOP}}/SOP_Manual_Operativo_Repo_AR.md"
checksum_sha256: "{{CHECKSUM_PLACEHOLDER}}"
links:
  instructions: "{{PATH_ProjectInstructions}}"
  verification_dir: "{{PATH_Verification}}"
  backups_dir: "{{PATH_BACKUPS}}"
policy_ref: "see: Project Instructions → policy.*"
---

# SOP — Manual Operativo Repo_AR ({{DOC_VERSION}})

## 1. Objetivo
Guiar generación/parcheo verificado de artefactos y su trazabilidad.

## 2. Requisitos
- PowerShell 5/7, `PSScriptAnalyzer`, `Pester v5`.
- Estructura de carpetas existente (Paths del repo).

## 3. Roles y responsabilidades
- **Operador:** ejecuta el macroscript, prepara parches, revisa salidas.
- **Revisor:** valida resultados y actualiza `CHANGELOG.md`.

## 4. Procedimiento estándar
### 4.1 Preparación
- [ ] Actualizar/crear el here-string del parche (total o segmentado).
- [ ] Confirmar codificación UTF-8 **sin BOM**.
- [ ] Verificar rutas objetivo.

### 4.2 Aplicación (parche)
1. **Backup** automático (`.bak` + espejo).
2. Aplicar parche (total o por `[BEGIN/END MODULE: X]`).
3. Guardar cambios.

### 4.3 Verificación
- Ejecutar PSSA → genera `psscriptanalyzer.json`/`.sarif` en `{{PATH_Verification}}`.
- Ejecutar Pester v5 → `TestResult.xml` (NUnit) en `{{PATH_Verification}}`.
- Validar `.psd1` con `Test-ModuleManifest`.

### 4.4 Quality Gate
- Aceptar solo si PSSA **sin errores**, Pester **sin fallos**, manifiestos **válidos**.

### 4.5 Trazabilidad
- Añadir entrada a `CHANGELOG.md` con versión, UTC y descripción.

## 5. Checklists
- **Cambio**  
  - [ ] Parche listo y revisado  
  - [ ] Backup creado  
  - [ ] Verificaciones OK  
  - [ ] CHANGELOG actualizado
- **Post-operación**  
  - [ ] Verificar espejo de backups  
  - [ ] Limpiar temporales (si aplica)

## 6. Troubleshooting
- PSSA/Pester no instalados → instalar módulos.  
- Errores de codificación → confirmar UTF-8 sin BOM.  
- Links rotos → validar rutas relativas.
'@
## [END MODULE: 5B-DOCS-MANUAL]
~~~~~

~~~~~
## [BEGIN MODULE: 5C-DOCS-REGISTRY]  # Registro: añade 5G y 5H (sin tocar otros)
Set-StrictMode -Version 3.0
using namespace System.IO

$__add = {
  param($map, [string]$key, [string]$varName, [string]$targetPath, [string]$sourceMod)
  $var = Get-Variable -Name $varName -Scope Global,Script -ErrorAction SilentlyContinue
  if (-not $var) { return }
  if (-not $targetPath) { return }
  if (-not $map.Contains($key)) {
    $map[$key] = [ordered]@{
      Id         = $key
      VarName    = $varName
      TargetPath = $targetPath
      SourceMod  = $sourceMod
      RequiredTokens = @()  # verbatim
    }
  }
}

$docs = [ordered]@{}

# Mantener lo previo si existía
if ($Global:RepoAR_Docs) {
  foreach ($k in $Global:RepoAR_Docs.Keys) { $docs[$k] = $Global:RepoAR_Docs[$k] }
}

# Añadir estos dos
&$__add $docs 'sop_avcm'     'Content_SOP_AVCM'     (Join-Path $Global:RepoAR_Paths.SOP 'SOP_AVCM.md')       'DocContents/5G-DOC-SOP-AVCM'
&$__add $docs 'sop_auditoria' 'Content_SOP_Auditoria' (Join-Path $Global:RepoAR_Paths.SOP 'SOP_Auditoria.md') 'DocContents/5H-DOC-SOP-AUDITORIA'

$Global:RepoAR_Docs = $docs
if (-not $Global:RepoAR_IsDryRun) {
  Set-Variable -Name RepoAR_Docs -Scope Global -Option ReadOnly -Force -Value $Global:RepoAR_Docs
}
## [END MODULE: 5C-DOCS-REGISTRY]
~~~~~

~~~~~
## [BEGIN MODULE: 5D-DOC-SOP-VERIFY]  # SOP Verify Project (mejorado)
$Content_SOP_Verify_Project = @'
---
id: sop_verify_project
doc_type: "sop"
status: "active"
title: "SOP — Verify Project"
version: "{{DOC_VERSION}}"
last_update_utc: "{{UTC_ISO}}"
source_module: "DocContents/5D-DOC-SOP-VERIFY"
path_target: "{{PATH_SOP}}/SOP_Verify_Project.md"
links:
  verification_dir: "{{PATH_Verification}}"
  backups_dir: "{{PATH_BACKUPS}}"
quality_gate:
  pssa_errors: 0
  pssa_warnings_max: 10
  pester_failures: 0
  manifest_valid: true
outputs:
  - "{{PATH_Verification}}/psscriptanalyzer.json"
  - "{{PATH_Verification}}/psscriptanalyzer.sarif"
  - "{{PATH_Verification}}/TestResult.xml"
---

# SOP — Verify Project ({{DOC_VERSION}})

## 1. Objetivo
Estandarizar la verificación de calidad (PSSA/Pester/Manifiestos) y documentar criterios de aceptación.

## 2. Preparación
- [ ] Confirmar que `PSScriptAnalyzer` y `Pester v5` están instalados.
- [ ] Asegurar que `{{PATH_Verification}}` existe.

## 3. Pasos
1. **Análisis estático (PSSA)**  
   - Genera JSON y SARIF en `{{PATH_Verification}}`.
2. **Pruebas (Pester v5)**  
   - Genera NUnit `TestResult.xml` en `{{PATH_Verification}}`.
3. **Manifiestos**  
   - Ejecutar validación de `.psd1`.

## 4. Criterios de aceptación
- PSSA: **Errores = 0**; Warnings ≤ `quality_gate.pssa_warnings_max`.
- Pester: **Fallos = 0**.
- Manifiestos: **válidos**.

## 5. Resultados esperados
- `psscriptanalyzer.json` / `.sarif`
- `TestResult.xml`

## 6. Observaciones
- Integrar estos resultados en el **Quality Gate** del macroscript.
- Fijar codificación UTF-8 sin BOM para evitar falsos positivos.
'@
## [END MODULE: 5D-DOC-SOP-VERIFY]
~~~~~

~~~~~
## [BEGIN MODULE: 5E-DOC-SOP-PATCHENGINE]  # SOP Patch Engine (mejorado)
$Content_SOP_PatchEngine = @'
---
id: sop_patch_engine
doc_type: "sop"
status: "active"
title: "SOP — Patch Engine"
version: "{{DOC_VERSION}}"
last_update_utc: "{{UTC_ISO}}"
source_module: "DocContents/5E-DOC-SOP-PATCHENGINE"
path_target: "{{PATH_SOP}}/SOP_PatchEngine.md"
links:
  backups_dir: "{{PATH_BACKUPS}}"
---

# SOP — Patch Engine ({{DOC_VERSION}})

## 1. Convenciones
- **Fences externos**: cinco tildes `~~~~~`.
- **Here-strings**: comillas simples, cierre en **columna 1**.
- **Codificación**: UTF-8 **sin BOM**.
- **Marcadores**: `[BEGIN MODULE: X]` / `[END MODULE: X]`.

## 2. Proceso
1. **Preparar parche** (total o por módulos).
2. **Backup automático**: `.bak` local + espejo en `{{PATH_BACKUPS}}`.
3. **Aplicar reemplazo**:
   - Total → sustituye el documento completo.
   - Parcial → reemplaza solo bloques marcados.
4. **Verificar** (PSSA/Pester/Manifiestos).
5. **Registrar** en `CHANGELOG.md`.

## 3. Nomenclatura de parches
- `YYYYMMDD_HHMMSSfff__<area>__<breve-descripcion>.patch.md`

## 4. Rollback
- Restaurar desde `.bak` más reciente.
- Reaplicar verificación antes de cerrar.

## 5. Errores comunes
- **Cierres con indentación** → el here-string no termina.
- **Interpolación accidental** → usar comillas simples.
- **Backticks en fences** → mantener `~~~~~`.
'@
## [END MODULE: 5E-DOC-SOP-PATCHENGINE]
~~~~~

~~~~~
## [BEGIN MODULE: 5F-DOC-SOP-BLINDADO]
Set-StrictMode -Version 3.0

# Este documento NO contiene fences de tildes (~) dentro del contenido.
# Los fences de tildes se usan SOLO FUERA del documento cuando se envuelve
# el archivo completo (p. ej., para parches o respuestas que contienen docs anidados).

$Content_SOP_CB_Blindado = @'
---
id: sop_cb_blindado
doc_type: "sop"
status: "active"
title: "SOP — Código Blindado (Here-Strings/CBs)"
version: "{{DOC_VERSION}}"
last_update_utc: "{{UTC_ISO}}"
source_module: "DocContents/5F-DOC-SOP-BLINDADO"
path_target: "{{PATH_SOP}}/SOP_CB_Blindado.md"
policy:
  outer_wrapper: "~~~~~"   # fence externo cuando el doc se anida en otro CB
  inner_blocks:  "```"     # backticks para los bloques internos
  nesting_level: 1         # solo un nivel (exterior + interior)
---

# SOP — Código Blindado ({{DOC_VERSION}})

## 1. Reglas
- **CB sin anidados** → usa **3 backticks** (```), abrir/cerrar iguales.
- **CB con anidados** → el **envoltorio exterior** será **`~~~~~`** (5 tildes) y
  **los CB internos** usarán **3 backticks**.
- En este documento (contenido), **no** se escriben líneas de `~`; las tildes
  se reservan para el envoltorio externo del documento cuando sea necesario.
- **Prohibido**: anidar dentro de un CB ya anidado (nada de “segundo nivel”).
- Here-strings: **single-quoted** y cierre en **columna 1**.
- Codificación: **UTF-8 sin BOM**.

## 2. Ejemplos (permitidos, un solo nivel)

### 2.1 CB sin anidados (3 backticks)
```powershell
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
```

### 2.2 Fragmento para here-string correcto (cierre en col. 1)
```powershell
$Content = @'
Línea 1
Línea 2
'@
```

### 2.3 Fragmento incorrecto (cierre con indentación)
```powershell
$Content = @'
Línea 1
  '@   # ← incorrecto
```

## 3. Operativa
1) Si el documento va a viajar **dentro** de otro CB (p. ej., parche), envuélvelo
   por fuera con **`~~~~~`**; dentro del doc, usa solo **3 backticks**.
2) No introduzcas fences adicionales dentro de un CB ya anidado.
3) Ejecuta el linter de fences antes de publicar.
'@
## [END MODULE: 5F-DOC-SOP-BLINDADO]
~~~~~


~~~~~
## [BEGIN MODULE: 5G-DOC-SOP-AVCM]  # SOP_AVCM (verbatim)
Set-StrictMode -Version 3.0

$Content_SOP_AVCM = @'
# Protocolo de Actualización y Verificación de Configuración y Memoria.

**Fecha de este paquete:** 2025-09-24 05:56 UTC

> Propósito. Poner a cualquier sesión de ChatGPT en modo **exactitud + trazabilidad** desde el primer turno, alineando Conducta, CI (3), Memoria y archivos del proyecto, y obligando `web.run` cuando la información sea inestable. Este SOP es **obligatorio** al iniciar sesión antes de responder cualquier solicitud.

---

## 0) Contrato de entrega (acuerdos no negociables)

- **Un turno, valor real**. No prometas “lo hago luego”. Entrega algo útil **ya**, aunque sea parcial bien explicado.
- **No trabajes en background**. Si vas a necesitar datos nuevos, dilo y **pídelos**.
- **`web.run` obligatorio** cuando la información sea inestable (probabilidad ≥10% de haber cambiado desde la última verificación).
- **Etiquetado de fuentes**: marca como **[Oficial]** (docs del proveedor/autor) o **[Comunidad/Prensa]** (blogs, foros, medios).
- **Citas claras** y enlaces por cada afirmación crítica o que haya podido cambiar (librerías, APIs, precios, políticas, leyes, etc.).

> Nota: Este SOP es para la sesión actual. No depende de memoria persistente. Si Memoria está activa, se valida su contenido y límites explícitamente.

---

## 1) Lectura y fijación de contexto (previo a la 1ª respuesta)

1. **Project Instructions**. Lee/recita el contrato del proyecto (tono, formato, límites, políticas de verificación, calidad, backups).
2. **Custom Instructions (3 campos)**. Trae el texto visible de los 3 campos y resume qué cambia para esta sesión.
3. **Memoria**. Confirma si está **OFF** o limitada al proyecto. Si está ON, pide ver su contenido para esta sesión.
4. **Archivos del proyecto**. Lista los archivos cargados y su propósito (nombre, tipo, ~tamaño). Si no hay archivos, dilo.

> Salida mínima: mini-resumen con 4 bullets (PI, CI(3), Memoria, Archivos).

---

## 2) `web.run` (verificación de realidad)

- **Cuándo**: si hay ≥10% de probabilidad de cambio (software, APIs, precios, leyes, noticias, políticas de proveedores, etc.).
- **Cómo**:
  - Prioriza fuentes **[Oficial]** (docs, changelogs, repos del autor).
  - Si usas **[Comunidad/Prensa]**, contrasta y marca la etiqueta.
  - Cita **5** afirmaciones críticas con su fuente.
- **Qué no hacer**: No inventar. No “recordar” de otras sesiones. No asumir fechas.

---

## 3) Comprobaciones de conducta

- **Tono y formato**: ajusta al contrato del proyecto (lenguaje, secciones, CBs).
- **CBs (Code Blocks)**:
  - Sin anidados → **3 backticks**.
  - Con anidados → **envoltorio externo** con `~~~~~` y **bloques internos** con 3 backticks (un solo nivel).
- **Un turno, valor**: si algo falta, di qué necesitas y entrega lo que sí puedes ya.

---

## 4) Entregables de salida (de este SOP)

Incluye en tu **primera respuesta**:
- **Resumen AVCM** (PI, CI(3), Memoria, Archivos).
- **Riesgos/lagunas** detectados + qué datos necesitas (si aplica).
- **Citas** con etiqueta [Oficial]/[Comunidad] cuando afirmes cosas inestables.
- **Plan inmediato** (qué harás en el siguiente bloque de trabajo dentro del mismo turno si procede).

---

## 5) Prompt operativo (para uso interno)

> Ejecuta SOP_AVCM: 
> 1) Trae PI y CI(3) visibles; 
> 2) Confirma estado y contenido de Memoria (o que está OFF); 
> 3) Lista archivos (nombre, tipo, propósito); 
> 4) Usa web.run para todo lo inestable (≥10%); 
> 5) Entrega un resumen con riesgos y plan inmediato; 
> 6) Cita fuentes marcando [Oficial]/[Comunidad]. 
> **Un turno, valor**; no prometas futuro.

---

## 6) Notas

- Este SOP **se ejecuta antes** de la primera respuesta, sea cual sea la solicitud.
- No requiere herramientas adicionales salvo `web.run`.
- Compatible con proyectos sin Memoria (preferible).
'@
## [END MODULE: 5G-DOC-SOP-AVCM]
~~~~~


~~~~~
## [BEGIN MODULE: 5H-DOC-SOP-AUDITORIA]  # SOP_Auditoria (verbatim)
Set-StrictMode -Version 3.0

$Content_SOP_Auditoria = @'
# Auditoría de Configuración de Proyecto — **Protocolo General**

**Objetivo.** Evaluar si un proyecto de ChatGPT aprovecha correctamente Project Instructions, Custom Instructions, archivos y (si aplica) Memoria; verificar el cumplimiento del contrato “un turno, valor + web.run”; y proponer acciones correctivas claras.

---

## 1) Entradas

- Texto vigente de **Project Instructions** (PI).
- Texto vigente de **Custom Instructions** (3 campos).
- Estado de **Memoria** (OFF / proyecto-solo / global) y, si está ON, su contenido relevante para esta sesión.
- **Listado de archivos** del proyecto (nombre, tipo, propósito).

---

## 2) Dimensiones de evaluación (puntaje total = 100)

1. **Claridad y enfoque (20)** — PI y CI sin ambigüedad; objetivos y tono definidos.
2. **Contrato “un turno, valor” (20)** — No prometer futuro; entregar algo útil en cada turno.
3. **Trazabilidad y citas (15)** — `web.run` en temas inestables; fuentes **[Oficial]** vs **[Comunidad]** claramente etiquetadas.
4. **Arquitectura de contexto (15)** — Jerarquía PI > CI > Prompt; no depender de memoria para información contractual.
5. **Operativa de archivos (10)** — Nombres y propósito; empaquetado y validación.
6. **Actualización/UI (10)** — Comprobaciones de Memoria/estado; manejo explícito de límites.
7. **Calidad de entregables (10)** — Claridad, reproducibilidad, validaciones internas.

---

## 3) Procedimiento

1. **Inventario** — Extrae PI, CI(3), Memoria (estado/contenido), Archivos.
2. **Consistencia** — Detecta contradicciones PI↔CI; prevalece PI.
3. **Contrato** — Verifica que se exige SOP_AVCM al inicio y `web.run` para información inestable.
4. **Archivos** — Revisa nombres ASCII, propósito, y guía de validación.
5. **Citas** — Confirma uso de [Oficial] para capacidades y [Comunidad] para contexto.
6. **Entregables** — Revisa políticas de calidad, empaquetado y guía de uso.

---

## 4) Salidas

- **Puntaje por dimensión** y **score total (0–100)**.
- **Hallazgos** priorizados (Crítico/Alto/Medio/Bajo).
- **Acciones correctivas** en una línea cada una (máximo 10).

---

## 5) Plantilla de reporte

**Resumen** — score total: XX/100.  
**Hallazgos → Acción**  
- Nivel — Breve hallazgo → Acción.  
- Nivel — Breve hallazgo → Acción.

---

## 6) Prompt operativo

> Audita el proyecto con este SOP. Devuelve puntajes por dimensión, hallazgos priorizados y **acciones** concretas en un turno. Verifica que el proyecto obliga a ejecutar SOP_AVCM al inicio y a usar `web.run` para información inestable. No hagas preguntas; entrega el informe en un turno.
'@
## [END MODULE: 5H-DOC-SOP-AUDITORIA]
~~~~~

~~~~~
## [BEGIN MODULE: 5X-DOCS-FENCE-LINT]
Set-StrictMode -Version 3.0

function RepoAR-AssertCBPolicy {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Text,
    [Parameter(Mandatory)][string]$Name
  )

  $errors = New-Object System.Collections.Generic.List[string]
  $lines  = $Text -split "`r?`n"

  # Estado para bloques de backticks (solo 1er nivel permitido)
  $inTicks = $false
  $tickLen = 0
  $tickStartLine = 0

  for ($i=0; $i -lt $lines.Length; $i++) {
    $ln = $lines[$i]

    # 1) PROHIBIDO: fences de tildes dentro del contenido del documento
    if ($ln -match '^\s*~+\s*$') {
      $errors.Add("[$Name] Línea $($i+1): no se permiten fences de tildes (~) dentro del contenido del documento. " +
                  "Los ~ se usan SOLO como envoltorio externo del doc.")
      continue
    }

    # 2) Validación de backticks
    if ($ln -match '^(`+)\s*$') {
      $len = $Matches[1].Length

      if (-not $inTicks) {
        if ($len -lt 3) {
          $errors.Add("[$Name] Línea $($i+1): fence con $len backticks; se requieren ≥3.")
        } else {
          # Apertura
          $inTicks = $true; $tickLen = $len; $tickStartLine = $i+1
        }
      } else {
        # Cierre: DEBE coincidir la longitud
        if ($len -ne $tickLen) {
          $errors.Add("[$Name] Línea $($i+1): cierre con $len backticks no coincide con apertura de $tickLen (línea $tickStartLine).")
        }
        $inTicks = $false; $tickLen = 0; $tickStartLine = 0
      }
      continue
    }

    # 3) Prevención de “segundo nivel”: si ya estamos dentro de un bloque de backticks,
    # no se permite abrir otro fence (ni backticks ni tildes).
    if ($inTicks) {
      if ($ln -match '^\s*(`+)\s*$') {
        $errors.Add("[$Name] Línea $($i+1): intento de anidar un segundo bloque de backticks dentro de otro bloque. No permitido.")
      }
      elseif ($ln -match '^\s*~+\s*$') {
        $errors.Add("[$Name] Línea $($i+1): intento de usar tildes dentro de un bloque de backticks. No permitido.")
      }
    }
  }

  if ($inTicks) {
    $errors.Add("[$Name] Fin de documento: bloque de backticks abierto en línea $tickStartLine sin cierre.")
  }

  if ($errors.Count -gt 0) {
    throw ([string]::Join([Environment]::NewLine, $errors))
  }
}

# Ejecutar sobre todas las plantillas $Content_*
Get-Variable -Scope Global,Script |
  Where-Object { $_.Name -like 'Content_*' -and $_.Value -is [string] } |
  ForEach-Object { RepoAR-AssertCBPolicy -Text $_.Value -Name $_.Name }

## [END MODULE: 5X-DOCS-FENCE-LINT]
~~~~~





## Thoughts
Tengo que ser detallado, pero sin ser excesivo. El enfoque debe ser conciso, aunque el análisis debe ser exhaustivo. Es importante revisar aspectos como estilo de código, gestión de excepciones, variables globales, y solo lectura. También debo considerar posibles conflictos con el uso de Write-Host, considerando políticas previas.
El proyecto parece evitar el uso de Write-Host, lo cual se debe mencionar como posible mejora. En cuanto a los comentarios de ayuda, el uso de campos como .NOMBRE y .SINOPSIS en español no será reconocido por Get-Help. Recomiendo usar etiquetas estándar en inglés o una versión dual con contenido en español para compatibilidad.
La inclusión de .SYNOPSIS con texto en español está bien, pero "Name" no es una palabra clave reconocida para CBH. Además, se usan extensiones como .LINK y .EXAMPLE, que son correctas. El uso de StrictMode 3.0 es adecuado, pero se podría limitar el alcance de $PSDefaultParameterValues para evitar posibles conflictos.
En PowerShell 5.1, el uso de OutputEncoding está correcto. Se define una versión global con `$Global:RepoAR_InitModuleVersion` y `$Global:RepoAR_InitModo`. Con respecto a Write-Log, utilizan Write-Host para mostrar información, lo cual puede entrar en conflicto si el archivo de log aún no se ha definido al momento de ejecutar.
El uso de Write-Host para Info en lugar de Write-Information puede crear conflictos con políticas previas, pero es posible recomendar el cambio por flexibilidad. También se observan precauciones con el manejo de variables globales, que deberían tener prefijos para evitar colisiones. Además, el enfoque de StrictMode 3.0 es adecuado con PowerShell 5.1.
La implementación utiliza correctamente las variables globales y el registro, pero se puede sugerir el uso de Write-Information en lugar de Write-Host para una mejor estructura de logs. Además, sería útil unificar claves de espacios reservados en el contenido de los documentos y revisar la lógica de protección de variables de solo lectura para mayor consistencia.

## ASSISTANT
¡Listo! Leí todo el material y aquí tienes una **auditoría técnica** y **mejoras concretas** para el paquete de módulos (1-INFO, 2A–2E, 3A–3E, 4A–4B, 5A–5H, 5X).

# Resumen ejecutivo
- **Lo mejor:** inicialización sólida (modo Real/Prueba + DRY-RUN), logging unificado, verificación de escritura, estructura de rutas reproducible, utilitarios coherentes (UTF-8 sin BOM, backups con mirror/ZIP), “lint” de fences para documentos embebidos, y SOPs claros para verificación/patching.
- **Riesgos puntuales (prioridad):**
  1) **Cabecera 1-INFO no compatible con Get-Help** (usa `.NOMBRE/.SINOPSIS/.DESCRIPCION` en lugar de las claves oficiales **en inglés**).  
  2) **Placeholders vs variables exportadas** (p. ej., `{{PATH_Verification}}` vs `Path_VERIFICATION`): posible fallo de render si el motor de reemplazo es case/clave-sensible.  
  3) **Uso de `Write-Host`** en logger (difícil de redirigir/automatizar; choca con guías que prefieren `Write-Information`).  
  4) **Alcance agresivo de `$PSDefaultParameterValues['*:ErrorAction']`** (puede alterar comportamiento de cmdlets de terceros).  
  5) **ReadOnly “shallow”** en config/paths (hashtable mutable; variable sólo protegida de reemplazo).  
  6) **Orden de inicialización implícito**: no se muestra una “secuencia canónica” de carga/ejecución (qué módulo va primero y cómo).  
- **Calidad global del paquete:** **Alto**. Con los ajustes propuestos, queda “lista enterprise”.

---

# Hallazgos detallados y fixes

## 1) Módulo 1-INFO (encabezado)
**Problema:** Las claves de **Comment-Based Help** que entiende PowerShell son en **inglés** (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.NOTES`, `.LINK`, etc.). Tus campos `.NOMBRE/.SINOPSIS/.DESCRIPCION` **no serán parseados por `Get-Help`**.

**Acción correctiva (patch mínimo):**
- Conserva el español **en el contenido**, pero usa **claves estándar**:
```powershell
#requires -Version 5.1
<#
.SYNOPSIS
  (Resumen corto en una sola línea, en español)
.DESCRIPTION
  (Explicación detallada y propósito del SOP/script)
.NOTES
  Autor: (Nombre/alias)
  Compatibilidad: Windows 10/11; PowerShell 5.1 / 7.x
  Versión: 1.0.0
  Fecha: AAAA-MM-DD
.LINK
  CHANGELOG.md
#>
```
*(Si quieres “Nombre”, inclúyelo dentro de `.NOTES` o nómbralo en el propio archivo/función.)*

---

## 2) 2A-INIT-ENV (modo y preferencias)
- **Bien:** autodetección `REPO_AR_MODE/DEBUG/DRY_RUN`, DRY-RUN global, StrictMode 3.0, UTF-8 sin BOM.
- **Riesgo controlado:** `$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'` (Real) y `= 'Continue'` (Prueba) impacta **todo**. Puede sorprender a cmdlets de terceros.
  - **Fix sugerido:** limitar a cmdlets típicos (`Get-Item`, `Copy-Item`, `Remove-Item`, etc.) o encapsular en funciones propias (p. ej., `RepoAR-Invoke`).

---

## 3) 2B-INIT-LOG (logger)
- **Bien:** niveles (Info/Warn/Error/DryRun/Debug), integración con `-Verbose/-Debug`, log a archivo UTF-8 sin BOM.
- **Mejora importante:** **evitar `Write-Host`** para `Info/Debug/DryRun`. Propón `Write-Information` (redirigible) y deja `Write-Warning/Write-Error` para lo demás.
  - **Patch ilustrativo (núcleo):**
    ```powershell
    switch ($Level) {
      'Info'   { Write-Information $Message }
      'Warn'   { Write-Warning     $Message }
      'Error'  { Write-Error       $Message -ErrorAction Stop }
      'DryRun' { Write-Information "[DRY-RUN] $Message" }
      'Debug'  { Write-Debug       $Message }
    }
    if ($Level -eq 'Info') { Write-Verbose $Message }
    ```
- **Orden:** El log a archivo depende de `RepoAR_InitConfig` (2E). Está **bien protegido** por if-guards; hasta 2E la salida irá a consola.

---

## 4) 2C-INIT-CHECKS (writability)
- **Bien:** prueba real en modo Real con archivo temporal UTF-8; dry-run retorna True y lo deja registrado.
- **Nota:** correcta limpieza del temporal y manejo de excepciones.

---

## 5) 2D-INIT-PATHS (rutas/settings)
- **Bien:** resolución de `RepoRoot`, import opcional `.psd1`, creación/simulación de carpetas, **fail-fast** de escritura en Real, `ExecTS` UTC.
- **Mejora menor:** registrar (Info) la ruta efectiva de `RepoRoot` y si se aplicó override por settings (ya lo haces para override; añade siempre el log del valor final).

---

## 6) 2E-INIT-CONFIG (config consolidada)
- **Bien:** objeto único, `LogToFile/LogFilePath`, `IsReadOnly` (variable).
- **Limitación consciente:** la variable es ReadOnly, pero el **hashtable interno** sigue siendo mutable.
  - **Alternativas:** usar `[pscustomobject]` con propiedades sin setter, o convertir a `System.Collections.Immutable` (si cargas ensamblado), o clonar a `Hashtable` + `AsReadOnly()` (wrapper) para consumo.

---

## 7) 3A/3B (utils core/IO)
- **Bien:** `RepoAR-NewTS`, `RepoAR-EnsureDir` con `ShouldProcess`, validaciones de path, `RepoAR-WriteUtf8NoBom` (Append/NoClobber), DRY-RUN respetado.
- **Sugerencia:** en `EnsureDir`, además de invalid chars, podrías **bloquear nombres reservados** en Windows (CON, PRN, AUX, NUL, COM1…). No crítico.

---

## 8) 3C/3D (backup policy/backup)
- **Bien:** política global, auto-compresión por extensión+tamaño, ZIP para carpetas/archivos, mirror configurable, DRY-RUN, retorno con metadatos.
- **Detalle:** `Copy-Item -Container` en filesystem no es necesario; `-Recurse` basta. No rompe, pero es superfluo.
- **Sugerencia:** si el backup primario está en la **misma carpeta** del destino, considera excluir patrones `*.bak`/`*.zip` para evitar cascadas si el target es un **directorio** ya versionado.

---

## 9) 3E (aliases)
- **Bien:** compat formal, ámbito local.

---

## 10) 4A/4B (tabla de rutas + export)
- **Bien:** tabla `$Global:RepoAR_Paths` + `Set-Variable` de compat; endurecimiento ReadOnly en Real.
- **Riesgo de **placeholders**:** en documentos usas `{{PATH_Verification}}`, pero exportas `Path_VERIFICATION`.  
  - **Fix inmediato (elige una):**  
    a) Estandariza los **placeholders** a `{{Path_VERIFICATION}}` (igual que la variable), **o**  
    b) Añade un **diccionario de sustitución** que mapee ambos nombres (`PATH_Verification` → `Path_VERIFICATION`).  
  - **Recomendación:** convenciones **PascalCase** con prefijo común (`Path_...`) en ambos lados.

---

## 11) 5A–5H (documentos SOP/PI/manual/verify/patch/blindado/auditoría)
- **Muy bien redactados** y consistentes con el flujo de calidad (PSSA/Pester/manifiestos).  
- **SOP_CB_Blindado + 5X Lint**: buena defensa para fences (tildes solo afuera, backticks adentro, un nivel).
- **SOP_AVCM / SOP_Auditoria:** adecuados para sesiones “un turno, valor + web.run”.  
- **Sugerencia de trazabilidad:** añade a todos los front-matter un campo `render_engine_version` y **checksum** real al momento de escribir (ahora pones `{{CHECKSUM_PLACEHOLDER}}`).

---

## 12) 5X-DOCS-FENCE-LINT (linter de CBs)
- **Bien:** detecta tildes como línea completa, backticks desbalanceados, evita segundo nivel.
- **Edge case cubierto:** referencias a `~~~~~` dentro de *inline code* (entre backticks simples) **no** disparan error (correcto).
- **Mejora opcional:** reportar **n° de bloques** por doc para ayudar a revisar densidad.

---

# Secuencia canónica de inicialización (recomendada)
1) **1-INFO** (cabecera CBH compatible con Get-Help).  
2) **2A-INIT-ENV** `param([ValidateSet('Real','Prueba')]$Modo)`  
3) **2B-INIT-LOG** (define `Write-Log`)  
4) **2C-INIT-CHECKS**  
5) **2D-INIT-PATHS** `[-RepoRoot ...] [-RunVerification]`  
6) **2E-INIT-CONFIG** (consolidación + ReadOnly)  
7) **3A/3B/3C/3D/3E** (utils/backup/aliases)  
8) **4A/4B** (paths table + export/ReadOnly)  
9) **5A–5H** (render de docs y SOPs)  
10) **5X** (lint final de fences sobre `$Content_*`)  

> **Nota:** hasta que 2E no establezca `RepoAR_InitConfig`, el logger debe comportarse **solo a consola** (como ya hace).

---

# Parches rápidos (copiar/pegar)

### A) Cabecera compatible Get-Help (sustituye el bloque de 1-INFO)
```powershell
#requires -Version 5.1
<#
.SYNOPSIS
  (Resumen corto en una sola línea)
.DESCRIPTION
  (Explicación detallada, propósito del SOP/script)
.NOTES
  Autor: (Nombre/alias)
  Compatibilidad: Windows 10/11; PowerShell 5.1/7.x
  Versión: 1.0.0
  Fecha: AAAA-MM-DD
#>
```

### B) Logger sin `Write-Host` (núcleo del switch)
```powershell
switch ($Level) {
  'Info'   { Write-Information $Message }
  'Warn'   { Write-Warning     $Message }
  'Error'  { Write-Error       $Message -ErrorAction Stop }
  'DryRun' { Write-Information "[DRY-RUN] $Message" }
  'Debug'  { Write-Debug       $Message }
}
if ($Level -eq 'Info') { Write-Verbose $Message }
```

### C) Mapeo de placeholders (ejemplo mínimo de render)
```powershell
$map = @{
  'PATH_ProjectInstructions' = $Global:Path_ProjectInstructions
  'PATH_SOP'                 = $Global:Path_SOP
  'PATH_SOP_Backups'         = $Global:Path_SOP_Backups
  'PATH_Verification'        = $Global:Path_VERIFICATION
  'PATH_BACKUPS'             = $Global:Path_BACKUPS
  'PATH_PSSA_Settings'       = $Global:Path_PSSA_Settings
  'PATH_CHANGELOG'           = $Global:Path_CHANGELOG
}
# Reemplazo simple:
foreach ($k in $map.Keys) { $Content = $Content -replace "\{\{$k\}\}", [regex]::Escape($map[$k]) }
```

---

# Checklist de verificación (rápida)
- [ ] `Get-Help` sobre el script muestra `SYNOPSIS/DESCRIPTION` (ok tras parche 1-INFO).  
- [ ] `2A→2E` fija `RepoAR_InitConfig` y `RepoAR_ExecTS`.  
- [ ] `Write-Log` usa Information/Warning/Error (redirigible).  
- [ ] `4A/4B` + render: placeholders resueltos (paths correctos).  
- [ ] `5X` linter: **sin errores**.  
- [ ] Backups: ZIP de carpetas y crudo/ZIP de archivos según política; mirror poblado.

---

# Acciones correctivas (una línea)
1) Cambiar 1-INFO a **Comment-Based Help estándar** (claves en inglés).  
2) Sustituir `Write-Host` por `Write-Information` en `Write-Log`.  
3) Reducir alcance de `$PSDefaultParameterValues` o encapsular invocaciones.  
4) Unificar **placeholders ⇄ variables** (o agregar mapeo de render).  
5) Opcional: endurecer `RepoAR_InitConfig/RepoAR_Paths` a objetos inmutables.  
6) Eliminar `-Container` en `Copy-Item` (3D) o condicionarlo sólo para providers que lo necesiten.  
7) Añadir `render_engine_version` y `checksum` real en front-matter al escribir docs.  
8) Documentar la **secuencia canónica** de carga en el README/SOP.  
9) Bloquear nombres reservados de Windows en `EnsureDir`.  
10) Registrar siempre `RepoRoot` efectivo y origen (param/env/settings).

---

¿Quieres que te entregue estos **patches aplicados** como un único `.ps1` listo para correr (con la secuencia canónica y el render de placeholders integrado)? Puedo generarlo en este mismo turno.

