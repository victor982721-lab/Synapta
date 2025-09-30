### Entrada (user)

Lee en su totalidad y analiza detalladamente lo siguiente:

~~~~~

# Protocolo de realización de parches a documentos y scripts.

---

## Módulo 1 – INFO

- **Objetivo**

Encabezado documental del script: define **nombre, sinopsis, propósito, compatibilidad, autor, versión y fecha**.  
Sirve como bloque de **identidad y trazabilidad**, útil para documentación, control de cambios y auditoría.

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

## Módulos 2A a 2E – Inicialización del Entorno

- 	**Objetivo general**

	Estos módulos forman la **fase de inicialización del proyecto**, asegurando que el script arranque en un entorno controlado, con configuración coherente, rutas estándar garantizadas y logging centralizado.  
	Su función es preparar todo antes de que se ejecute cualquier lógica de negocio.
	
	---

	### Módulo 2A – INIT-ENV

	Establece el **modo de ejecución** (`Real` o `Prueba`) y ajusta las preferencias globales de PowerShell.

	- Auto-detecta el modo desde parámetros o variables de entorno.  
	- En *Real*: detiene al primer error, `DryRun = False`.  
	- En *Prueba*: continúa ante errores, `DryRun = True`, muestra advertencia.  
	- Silencia mensajes innecesarios (`Warning`, `Information`, `Verbose`, `Progress`).  
	- Fuerza la codificación de consola a **UTF-8 sin BOM**.  
	- Expone versión del INIT y el modo efectivo.

	~~~~~
## [BEGIN MODULE: 2A-INIT-ENV]

param(
  [string]$Modo = $null
)

Set-StrictMode -Version 3.0

# --- Auto-detección de modo ---
if ([string]::IsNullOrWhiteSpace($Modo)) {
  if ($env:REPO_AR_MODE -eq 'Prueba' -or $env:DEBUG -or $env:DRY_RUN) {
    $Modo = 'Prueba'
  } else {
    $Modo = 'Real'
  }
}
$Modo = @('Real','Prueba') | Where-Object { $_ -ieq $Modo } | Select-Object -First 1
if (-not $Modo) { $Modo = 'Real' }

# --- Preferencias globales + DRY-RUN ---
switch ($Modo) {
  'Real' {
    $PSDefaultParameterValues['*:ErrorAction'] = 'Stop'
    $ErrorActionPreference = 'Stop'
    $Global:IsDryRun = $false
  }
  'Prueba' {
    $PSDefaultParameterValues['*:ErrorAction'] = 'Continue'
    $ErrorActionPreference = 'Continue'
    $Global:IsDryRun = $true
    Write-Warning "Modo PRUEBA activo → se simularán operaciones (dry-run)."
  }
}
$PSDefaultParameterValues['*:WarningAction']      = 'SilentlyContinue'
$PSDefaultParameterValues['*:InformationAction']  = 'SilentlyContinue'
$VerbosePreference  = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

# --- UTF-8 sin BOM ---
try {
  [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
  [Console]::InputEncoding  = New-Object System.Text.UTF8Encoding($false)
  $OutputEncoding           = New-Object System.Text.UTF8Encoding($false)
} catch { }

$Global:InitModuleVersion = '2.1.0'
$Global:InitModo          = $Modo

## [END MODULE: 2A-INIT-ENV]
	~~~~~

	---

	### Módulo 2B – INIT-LOG

	Define `Write-Log`, el **sistema de logging unificado**.

	- Soporta niveles: `Info`, `Warn`, `Error`, `DryRun`, `Debug`, `Verbose`.  
	- Colorea salida según severidad.  
	- Respeta `-Verbose` y `-Debug` de PowerShell.  
	- Registra en archivo `init_<timestamp>.log` dentro de `VERIFICATION` si está habilitado.  
	- Centraliza los mensajes para todo el proyecto.

	~~~~~
## [BEGIN MODULE: 2B-INIT-LOG]

function Write-Log {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][ValidateSet('Info','Warn','Error','DryRun','Debug','Verbose')]
    [string]$Level,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Message,
    [switch]$NoFile
  )

  # Normaliza para registro en archivo (una sola línea)
  $msg = [string]$Message
  $msgOneline = ($msg -replace '\s+', ' ').Trim()

  $prefix = switch ($Level) {
    'Info'    { '[INFO] ' }
    'Warn'    { '[WARN] ' }
    'Error'   { '[ERROR] ' }
    'DryRun'  { '[DRY-RUN] ' }
    'Debug'   { '[DEBUG] ' }
    'Verbose' { '[VERBOSE] ' }
  }
  $text = "$prefix$msg"

  # Salida a consola (Debug/Verbose respetan preferencias nativas)
  switch ($Level) {
    'Info'    { Write-Host $text }
    'Warn'    { Write-Warning $msg }
    'Error'   { Write-Error $msg -ErrorAction Stop }
    'DryRun'  { Write-Host $text -ForegroundColor Yellow }
    'Debug'   {
      if ($DebugPreference -ne 'SilentlyContinue') {
        Write-Host $text -ForegroundColor DarkGray
      }
    }
    'Verbose' {
      if ($VerbosePreference -ne 'SilentlyContinue') {
        Write-Host $text
      }
    }
  }

  # Log a archivo (independiente del gating de consola)
  $shouldFileLog = $false
  if (-not $NoFile -and $Global:InitConfig -and
      $Global:InitConfig.PSObject.Properties.Name -contains 'LogToFile' -and
      $Global:InitConfig.LogToFile -and
      -not $Global:IsDryRun) {
    $shouldFileLog = $true
  }

  if ($shouldFileLog) {
    $verifyDir = $null
    if ($Global:InitConfig.PSObject.Properties.Name -contains 'VerifyDir') {
      $verifyDir = $Global:InitConfig.VerifyDir
    }

    if (-not [string]::IsNullOrWhiteSpace($verifyDir)) {
      # Asegura carpeta (usa Ensure-Dir si existe; fallback básico si no)
      if (Get-Command -Name Ensure-Dir -ErrorAction SilentlyContinue) {
        try { Ensure-Dir -Path $verifyDir | Out-Null } catch { }
      } else {
        if (-not (Test-Path -LiteralPath $verifyDir)) {
          try { New-Item -ItemType Directory -Path $verifyDir -Force | Out-Null } catch { }
        }
      }

      # Timestamp de ejecución si no existe
      if (-not $Global:ExecTS) {
        $Global:ExecTS = (Get-Date).ToString('yyyyMMdd_HHmmssfff')
      }

      $logFile   = Join-Path $verifyDir "init_$($Global:ExecTS).log"
      $timestamp = Get-Date -Format s
      try {
        Add-Content -LiteralPath $logFile -Value ("{0} {1}{2}" -f $timestamp, $prefix, $msgOneline) -Encoding utf8
      } catch {
        Write-Warning ("Write-Log: no se pudo escribir en archivo de log: {0}" -f $logFile)
      }
    }
  }
}

## [END MODULE: 2B-INIT-LOG]
	~~~~~

---

~~~~~
## [BEGIN MODULE: 2C-INIT-CHECKS]

function Test-PathWritable {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return $false }
  if ($Global:IsDryRun) {
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

~~~~~
## [BEGIN MODULE: 2D-INIT-PATHS]

param(
  [string]$RepoRoot = $null,
  [switch]$RunVerification
)

# --- Fuente base de RepoRoot (parametro o autodetección)
if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  if ($PSScriptRoot) {
    $RepoRoot = $PSScriptRoot
  } elseif ($PSCommandPath) {
    $RepoRoot = Split-Path -Parent $PSCommandPath
  } else {
    $RepoRoot = (Get-Location).Path
  }
}

# --- Carga settings opcionales (.psd1) con validación
$settings = $null
try {
  $candidates = @(
    (Join-Path $RepoRoot 'RepoSettings.psd1'),
    (Join-Path $RepoRoot 'Config\RepoSettings.psd1')
  )
  foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c) {
      $tmp = Import-PowerShellDataFile -LiteralPath $c -ErrorAction Stop
      if ($tmp -is [hashtable]) {
        $settings = $tmp
        break
      } else {
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
          Write-Log -Level Warn -Message "RepoSettings.psd1 no es un hashtable. Ignorado: $c"
        }
      }
    }
  }
} catch {
  if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
    Write-Log -Level Warn -Message "No se pudo importar settings: $($_.Exception.Message)"
  }
}

# --- Si settings propone RepoRoot y NO vino por parámetro, intentar usarlo
if ($settings -and $settings.ContainsKey('RepoRoot') -and -not $PSBoundParameters.ContainsKey('RepoRoot')) {
  $proposed = [string]$settings.RepoRoot
  if (-not [string]::IsNullOrWhiteSpace($proposed)) {
    $RepoRoot = $proposed
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
      Write-Log -Level Info -Message "RepoRoot sobreescrito por settings: $RepoRoot"
    }
  }
}

# --- Conjunto de rutas simuladas en DryRun
if (-not $Global:_SimulatedPaths) { $Global:_SimulatedPaths = @() }

# --- Garantiza RepoRoot (crear o simular)
$repoRootExists = Test-Path -LiteralPath $RepoRoot
if (-not $repoRootExists) {
  if ($Global:IsDryRun) {
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
      Write-Log -Level DryRun -Message "Crearía RepoRoot: $RepoRoot"
    }
    $Global:_SimulatedPaths += $RepoRoot
  } else {
    try {
      if (Get-Command -Name Ensure-Dir -ErrorAction SilentlyContinue) {
        Ensure-Dir -Path $RepoRoot | Out-Null
      } else {
        New-Item -ItemType Directory -Path $RepoRoot -Force | Out-Null
      }
    } catch {
      throw "No se pudo crear RepoRoot '$RepoRoot': $($_.Exception.Message)"
    }
  }
}

# --- Normaliza RepoRoot (si existe usar Resolve-Path, si no, normaliza a ruta absoluta)
if (Test-Path -LiteralPath $RepoRoot) {
  $RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
  try {
    $RepoRoot = [IO.Path]::GetFullPath($RepoRoot)
  } catch {
    # fallback sin romper
  }
}

# --- Rutas estándar
$ScriptsDir = Join-Path $RepoRoot 'SCRIPTS'
$BackupsDir = Join-Path $ScriptsDir 'BACKUPS'
$VerifyDir  = Join-Path $RepoRoot 'VERIFICATION'

# --- Crear o simular directorios estándar
foreach ($dir in @($ScriptsDir,$BackupsDir,$VerifyDir)) {
  if (-not (Test-Path -LiteralPath $dir)) {
    if ($Global:IsDryRun) {
      if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
        Write-Log -Level DryRun -Message "Crearía directorio: $dir"
      }
      $Global:_SimulatedPaths += $dir
    } else {
      try {
        if (Get-Command -Name Ensure-Dir -ErrorAction SilentlyContinue) {
          Ensure-Dir -Path $dir | Out-Null
        } else {
          New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
      } catch {
        throw "No se pudo crear directorio '$dir': $($_.Exception.Message)"
      }
    }
  }
}

# --- Marca global si hubo simulaciones de rutas
$Global:_HasSimulatedPaths = ($Global:_SimulatedPaths.Count -gt 0)

# --- Timestamp de ejecución (UTC) si no existe
if (-not $Global:ExecTS) {
  $Global:ExecTS = [DateTime]::UtcNow.ToString('yyyyMMdd_HHmmssfff')
}

# --- Exponer rutas/config al resto de módulos
$Global:_RepoRoot        = $RepoRoot
$Global:_ScriptsDir      = $ScriptsDir
$Global:_BackupsDir      = $BackupsDir
$Global:_VerifyDir       = $VerifyDir
$Global:_Settings        = $settings
$Global:_RunVerification = [bool]$RunVerification

# --- Facilitar al logger la ruta de verificación (no fuerza LogToFile)
if (-not $Global:InitConfig) { $Global:InitConfig = [ordered]@{} }
$Global:InitConfig.VerifyDir = $VerifyDir

## [END MODULE: 2D-INIT-PATHS]
~~~~~

---

~~~~~
## [BEGIN MODULE: 2E-INIT-CONFIG]

# Híbrido: Prueba = flexible (hashtable); Real = objeto de solo lectura
# Requiere módulos previos: 2A-INIT-ENV, 2D-INIT-PATHS, 2B-INIT-LOG

# --- Resolver LogToFile desde settings si existe ---
$logToFile = $false
if ($Global:_Settings -and $Global:_Settings.ContainsKey('LogToFile')) {
  try { $logToFile = [bool]$Global:_Settings.LogToFile } catch { $logToFile = $false }
}

# --- Datos base (ya establecidos por los módulos previos) ---
$cfgVersion   = [string]$Global:InitModuleVersion
$cfgModo      = [string]$Global:InitModo
$cfgIsDryRun  = [bool]$Global:IsDryRun
$cfgRepoRoot  = [string]$Global:_RepoRoot
$cfgScripts   = [string]$Global:_ScriptsDir
$cfgBackups   = [string]$Global:_BackupsDir
$cfgVerify    = [string]$Global:_VerifyDir
$cfgExecTS    = [string]$Global:ExecTS
$cfgRunVerif  = [bool]$Global:_RunVerification
$cfgSettings  = $Global:_Settings

if (-not $cfgIsDryRun) {
  # --- Modo REAL: exponer objeto inmutable (read-only) con propiedades .NET ---
  if (-not ('RepoInitConfig' -as [type])) {
    class RepoInitConfig {
      hidden [string]   $_Version
      hidden [string]   $_Modo
      hidden [bool]     $_IsDryRun
      hidden [string]   $_RepoRoot
      hidden [string]   $_ScriptsDir
      hidden [string]   $_BackupsDir
      hidden [string]   $_VerifyDir
      hidden [string]   $_ExecTS
      hidden [bool]     $_RunVerification
      hidden [hashtable] $_Settings
      hidden [bool]     $_LogToFile
      hidden [bool]     $_IsReadOnly

      RepoInitConfig(
        [string]$Version,
        [string]$Modo,
        [bool]$IsDryRun,
        [string]$RepoRoot,
        [string]$ScriptsDir,
        [string]$BackupsDir,
        [string]$VerifyDir,
        [string]$ExecTS,
        [bool]$RunVerification,
        [hashtable]$Settings,
        [bool]$LogToFile
      ) {
        $this._Version        = $Version
        $this._Modo           = $Modo
        $this._IsDryRun       = $IsDryRun
        $this._RepoRoot       = $RepoRoot
        $this._ScriptsDir     = $ScriptsDir
        $this._BackupsDir     = $BackupsDir
        $this._VerifyDir      = $VerifyDir
        $this._ExecTS         = $ExecTS
        $this._RunVerification= $RunVerification
        # Copia superficial para evitar que cambien la referencia externa
        if ($Settings) { $this._Settings = @{} + $Settings } else { $this._Settings = @{} }
        $this._LogToFile      = $LogToFile
        $this._IsReadOnly     = $true
      }

      [string]   Version         { get { return $this._Version } }
      [string]   Modo            { get { return $this._Modo } }
      [bool]     IsDryRun        { get { return $this._IsDryRun } }
      [string]   RepoRoot        { get { return $this._RepoRoot } }
      [string]   ScriptsDir      { get { return $this._ScriptsDir } }
      [string]   BackupsDir      { get { return $this._BackupsDir } }
      [string]   VerifyDir       { get { return $this._VerifyDir } }
      [string]   ExecTS          { get { return $this._ExecTS } }
      [bool]     RunVerification { get { return $this._RunVerification } }
      [hashtable] Settings       { get { return $this._Settings } }
      [bool]     LogToFile       { get { return $this._LogToFile } }
      [bool]     IsReadOnly      { get { return $this._IsReadOnly } }
    }
  }

  $Global:InitConfig = [RepoInitConfig]::new(
    $cfgVersion,
    $cfgModo,
    $cfgIsDryRun,
    $cfgRepoRoot,
    $cfgScripts,
    $cfgBackups,
    $cfgVerify,
    $cfgExecTS,
    $cfgRunVerif,
    $cfgSettings,
    $logToFile
  )

} else {
  # --- Modo PRUEBA: hashtable flexible (mutable) y consistente con acceso por punto ---
  $Global:InitConfig = [ordered]@{
    Version         = $cfgVersion
    Modo            = $cfgModo
    IsDryRun        = $cfgIsDryRun
    RepoRoot        = $cfgRepoRoot
    ScriptsDir      = $cfgScripts
    BackupsDir      = $cfgBackups
    VerifyDir       = $cfgVerify
    ExecTS          = $cfgExecTS
    RunVerification = $cfgRunVerif
    Settings        = $cfgSettings
    LogToFile       = $logToFile
    IsReadOnly      = $false
  }
}

# --- Mensaje de salida coherente para ambos modos ---
Write-Log -Level Info -Message ("INIT listo. Modo={0}; DryRun={1}; RepoRoot='{2}'; ReadOnly={3}." -f `
  $Global:InitConfig.Modo, $Global:InitConfig.IsDryRun, $Global:InitConfig.RepoRoot, `
  ($(if ($Global:InitConfig.PSObject.Properties.Name -contains 'IsReadOnly') { $Global:InitConfig.IsReadOnly } else { $true })))


## [END MODULE: 2E-INIT-CONFIG]
~~~~~

### Salida (assistant)

{"content_type": "model_editable_context", "model_set_context": "", "repository": null, "repo_summary": null, "structured_context": null}
