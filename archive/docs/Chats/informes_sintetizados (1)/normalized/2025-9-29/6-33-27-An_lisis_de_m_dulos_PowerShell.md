# Análisis de módulos PowerShell

https://chat.openai.com/c/68da7c94-9884-8330-bb43-ef1c64004ce0

## USER
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

## Thoughts
El usuario quiere un análisis detallado de un protocolo para parchar documentos y scripts. Debería enfocarme en los aspectos técnicos como la idempotencia, manejo de errores, principios de PowerShell (PS 5.1/7.x), estilo, y compatibilidad entre plataformas. También debo revisar posibles mejoras, preocupaciones de seguridad y recomendaciones para pruebas, además de sugerir ejemplos de pruebas unitarias sin ejecutar el código.
Debo evitar la prosa excesiva y ser conciso, como piden las instrucciones. Utilizaré encabezados (#) y listas de verificación con niveles de riesgo y sugerencias de corrección. Mantendré el tono técnico en español y añadiré sugerencias de parches en bloques de código. Utilizaré tildes de cinco para bloques anidados, sin excesos en el formato.
Debo analizar la compatibilidad del código. La versión 3.0 de StrictMode es válida en PS 5.1 y 7.x, ya que fue añadida en PowerShell 3.0 y puede usarse en versiones posteriores. También se verificó que la codificación del console mediante UTF8 funciona correctamente tanto en PS 5.1 como en PS 7, incluso en plataformas cruzadas.
El uso de `Write-Host` puede generar conflictos, ya que se prohíbe en algunos proyectos, según se indica en documentos previos. Se recomienda usar `Write-Information`, `Write-Verbose`, o `Write-Warning` como alternativas. También se pueden considerar `$Host.UI.WriteLine` o `Write-Output` para evitar el problema de `Write-Host`, especialmente en PowerShell 5.1.
El uso de `Write-Host` genera conflictos, pues se recomienda usar `Write-Information` o `Write-Error` respetando configuraciones globales. En `Prueba`, el conflicto con `Write-Error -ErrorAction Stop` debería respetar la preferencia global o usar `Write-Error` sin la acción Stop. Unificación de parámetros en módulos también es sugerida.
Se sugieren cambios en el uso de `Write-Host` y `Write-Log` para evitar conflictos en los registros, especialmente en modo "DryRun" y al manejar parámetros globales. Mencionan inconsistencias en el manejo de fechas y de la preferencia de advertencias, lo que puede generar confusión si no se ajustan las configuraciones adecuadamente.
Hay varios puntos en el código que necesitan atención, como asegurar que los registros de errores se manejen antes de escribir en los archivos para evitar que se pierdan, lo que actualmente ocurre si la ejecución se detiene. También se proponen mejoras en la organización del código y en la implementación de funciones para manejar el log correctamente, incluyendo el manejo de colores en versiones más recientes de PowerShell.
El análisis incluye ajustes clave en el código como asegurar que el registro de errores se haga antes de lanzar excepciones, unificar la marca de tiempo y evitar el uso de `Write-Host` atendiendo a la política del proyecto. También se proponen cambios en la estructura de parámetros y funciones, además de ajustes en las condiciones de los módulos según el modo de ejecución.

## ASSISTANT
# Revisión técnica — Módulos **INFO** y **2A–2E** (PowerShell 5.1/7.x)

A continuación te dejo un análisis minucioso con hallazgos priorizados y parches concretos listos para aplicarse. No usé fuentes externas; todo se basa en la lectura del material que compartiste.

---

## Resumen ejecutivo

- La **fase de inicialización** está bien separada (modo, logging, checks, paths, config) y usa prácticas sólidas: `Set-StrictMode 3.0`, codificación UTF-8 sin BOM, `Import-PowerShellDataFile`, creación idempotente de rutas y **config inmutable** en modo Real vía *class*.
- Hay **inconsistencias de comportamiento** entre lo declarado y lo implementado (p. ej., “Prueba = continuar ante errores” vs `Write-Error -ErrorAction Stop` dentro de `Write-Log`), riesgo de **múltiples bloques `param()`** si se pegan los módulos en un único script, y **uso de `Write-Host`** (que choca con lineamientos típicos del proyecto donde se prohíbe).
- Recomiendo **unificar el `param()`**, **corregir `Write-Log`** para preservar la promesa de *DryRun/Prueba no detiene*, **fijar el `ExecTS` en un único lugar (UTC)**, y **alinear Warning/Information** con lo que se pretende “silenciar”.

---

## Mapa de dependencias y orden de carga

Orden recomendado de ejecución (top-down en un mismo script):

1. **Módulo 2A – INIT-ENV** (sin `param()` adentro; se toma de la cabecera unificada)  
2. **Módulo 2B – INIT-LOG**  
3. **Módulo 2D – INIT-PATHS**  
4. **Módulo 2C – INIT-CHECKS** (opcional; utilidades, no muta estado global salvo logs)  
5. **Módulo 2E – INIT-CONFIG**

> Motivo: 2B necesita saber si debe escribir a archivo (lee `InitConfig` si existe), y 2D define `VerifyDir` para el logger. 2E consolida todo al final.

---

## Hallazgos priorizados

### Crítico
1) **Bloques `param()` múltiples** (2A y 2D).  
   Un script solo admite **un** bloque `param()`. Mezclar módulos tal cual provoca error de parseo.

2) **`Write-Log` rompe la promesa de “Prueba = continuar”**  
   - Caso `Error`: usa `Write-Error -ErrorAction Stop`, que **termina** incluso en Prueba.  
   - Además, al hacer `Stop` **antes** de la rama de file-logging, la entrada **no se persiste** a disco.

3) **`ExecTS` inconsistente (local vs UTC)**  
   - 2B crea `ExecTS` si falta (hora local), 2D también (UTC) pero “solo si no existe”.  
   - Resultado: el **primer uso** decide el formato y la zona, generando **inconsistencia** entre log y config.

### Alto
4) **Silenciado de `Warning/Information` no efectivo/consistente**  
   - Se setean `PSDefaultParameterValues['*:WarningAction']` y `['*:InformationAction']`, pero **`Write-Warning` ignora ese default** (obedece a `$WarningPreference`).  
   - El comentario “silenciar Warning/Information” no coincide con el comportamiento real.

5) **Uso de `Write-Host`** en `Write-Log`  
   - Choca con políticas de muchos playbooks (y con tus materiales previos) que **prohíben `Write-Host`**.  
   - También dificulta redirección/automatización (no sigue *streams* nativos).

### Medio
6) **Errores no loggeados si detienes con `Stop`**  
   - El diseño actual escribe a archivo **después** de la salida a consola. Con `Stop`, no llega a la rama de archivo.

7) **Colorización no uniforme PS 5.1/7.x**  
   - En 7.x existe `$PSStyle` y ANSI; en 5.1 depende de host/VT. No hay *feature detection*.

8) **Globales dispersas**  
   - `InitConfig` + varios `$Global:_...` están bien para bootstrap, pero conviene ofrecer `Get-InitConfig` y reducir accesos directos a globales fuera de INIT.

### Bajo
9) **`Test-PathWritable` en DryRun devuelve true**  
   - Correcto para simulación, pero conviene **marcar** en `InitConfig` que las verificaciones de I/O fueron simuladas para reportes posteriores.

10) **`Ensure-Dir` referenciado pero no definido** (hay *fallback*, pero es útil tenerlo).

---

## Parches propuestos (listos para pegar)

### 1) Cabecera única (`#requires` + `param()` consolidado + `ExecTS` UTC)

```powershell
#requires -Version 5.1
Set-StrictMode -Version 3.0

param(
  [ValidateSet('Real','Prueba')]
  [string]$Modo = $null,

  [string]$RepoRoot = $null,

  [switch]$RunVerification
)

# Timestamp de ejecución — fijar una vez y en UTC
if (-not $Global:ExecTS) {
  $Global:ExecTS = [DateTime]::UtcNow.ToString('yyyyMMdd_HHmmssfff')
}
```

> Luego elimina las líneas `param(...)` de 2A y 2D.

---

### 2) `Write-Log` sin `Write-Host`, con file-log garantizado y semántica “Prueba = no detener”

```powershell
function Write-Log {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][ValidateSet('Info','Warn','Error','DryRun','Debug','Verbose')]
    [string]$Level,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Message,
    [switch]$NoFile
  )

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

  # ---------- File logging (intentar SIEMPRE antes de lanzar error)
  $shouldFileLog = $false
  try {
    if (-not $NoFile -and $Global:InitConfig `
        -and ($Global:InitConfig.PSObject.Properties.Name -contains 'LogToFile') `
        -and $Global:InitConfig.LogToFile `
        # Si quieres registrar también en DryRun, quita esta línea:
        #-and -not $Global:IsDryRun
    ) { $shouldFileLog = $true }

    if ($shouldFileLog) {
      if (-not $Global:ExecTS) { $Global:ExecTS = [DateTime]::UtcNow.ToString('yyyyMMdd_HHmmssfff') }
      $verifyDir = if ($Global:InitConfig.PSObject.Properties.Name -contains 'VerifyDir') { $Global:InitConfig.VerifyDir } else { $null }
      if ($verifyDir) {
        if (-not (Test-Path -LiteralPath $verifyDir)) { New-Item -ItemType Directory -Path $verifyDir -Force | Out-Null }
        $logFile = Join-Path $verifyDir "init_$($Global:ExecTS).log"
        $ts = (Get-Date).ToUniversalTime().ToString('s') + 'Z'
        Add-Content -LiteralPath $logFile -Value ("{0} {1}{2}" -f $ts, $prefix, $msgOneline) -Encoding utf8
      }
    }
  } catch { }

  # ---------- Salida por streams nativos (sin Write-Host)
  switch ($Level) {
    'Info' {
      # Forzar visibilidad de Information solo dentro de esta llamada
      $prev = $InformationPreference
      try { $script:InformationPreference = 'Continue'; Write-Information $text -Tags 'INFO' }
      finally { $script:InformationPreference = $prev }
    }
    'Warn'    { Write-Warning $msg }
    'Error'   {
      if ($Global:IsDryRun) {
        # En Prueba NO detenemos
        Write-Error $msg -ErrorAction Continue
      } else {
        # En Real detenemos
        Write-Error $msg -ErrorAction Stop
      }
    }
    'DryRun'  {
      $prev = $InformationPreference
      try { $script:InformationPreference = 'Continue'; Write-Information "[DRY-RUN] $msg" -Tags 'DRYRUN' }
      finally { $script:InformationPreference = $prev }
    }
    'Debug'   { Write-Debug $text }
    'Verbose' { Write-Verbose $text }
  }
}
```

> Ventajas: (a) conserva logs de **Error** en archivo aunque luego detengas, (b) respeta “Prueba = continuar”, (c) evita `Write-Host` y usa *streams* PowerShell, (d) fuerza `Information` solo dentro del *scope* de la llamada.

---

### 3) Alineación de preferencias (comentarios vs comportamiento real)

En 2A, si de verdad quieres **silenciar Warning/Information** del resto de cmdlets *sin* afectar tu logger:

```powershell
# Preferencias globales
$VerbosePreference   = 'SilentlyContinue'
$ProgressPreference  = 'SilentlyContinue'
$WarningPreference   = 'SilentlyContinue'      # <-- añade esto para Warning
$PSDefaultParameterValues['*:InformationAction'] = 'SilentlyContinue'
# NO toques $InformationPreference global; lo maneja Write-Log localmente.
```

---

### 4) `Ensure-Dir` mínima (para evitar ramas condicionales y unificar)

```powershell
function Ensure-Dir {
  [CmdletBinding()]
  param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
  return (Get-Item -LiteralPath $Path)
}
```

Sustituye los *fallbacks* manuales por **`Ensure-Dir`** en 2B y 2D.

---

### 5) Fijar `ExecTS` y timestamps a UTC en todo el pipeline

- **Quita** la creación de `ExecTS` en 2B y 2D; ya se fija en la cabecera.
- En 2B, cambia el timestamp de línea de log a **UTC** (ya incluido arriba: `ToUniversalTime()` y sufijo `Z`).

---

### 6) Módulo 2D — retirar `param()` interno y pequeños ajustes

- Elimina el `param()` de 2D; usa las variables del **param unificado**.
- Donde se usa `PSBoundParameters.ContainsKey('RepoRoot')`, en script superior funciona; si encapsulas en función, añade `[CmdletBinding()]` para garantizar `PSBoundParameters`.

---

### 7) Señalización de simulaciones (DryRun)

En 2D, después de `$_SimulatedPaths`:

```powershell
$Global:_HasSimulatedPaths = ($Global:_SimulatedPaths.Count -gt 0)
if ($Global:_HasSimulatedPaths) {
  Write-Log -Level DryRun -Message ("Se simularon {0} rutas." -f $Global:_SimulatedPaths.Count)
}
```

En 2E, podrías reflejarlo:

```powershell
# En ambos modos añade propiedad:
# Real (class): agrega hidden [bool] $_HasSimulatedPaths y property pública
# Prueba (hashtable): HasSimulatedPaths = $Global:_HasSimulatedPaths
```

---

## Comprobaciones rápidas (manual)

1) **Modo Real** (debe detener en Error y loggear en archivo):
```powershell
$env:REPO_AR_MODE = $null
.\tu_script.ps1 -Modo Real -RepoRoot "$env:TEMP\ARRepo" -RunVerification
$Global:InitConfig | Format-List *
```

2) **Modo Prueba** (no detener en Error, sí avisar):
```powershell
$env:REPO_AR_MODE = 'Prueba'
.\tu_script.ps1 -RepoRoot "$env:TEMP\ARRepo2" -RunVerification -Verbose
Get-ChildItem "$env:TEMP\ARRepo2\VERIFICATION"
```

3) **Verifica UTC en logs** (líneas con sufijo `Z`):
- `VERIFICATION\init_<ExecTS>.log` debe mostrar timestamps ISO UTC (`2025-09-29T12:34:56Z`).

---

## Compatibilidad y notas PS 5.1/7.x

- `Set-StrictMode -Version 3.0` ✅ válido en 5.1/7.x.  
- Clases (`class RepoInitConfig`) ✅ 5.0+; no anidar en funciones.  
- `::new()` ✅ 5.0+ (`[Text.UTF8Encoding]::new($false)`).  
- `$PSStyle` (si optas por ANSI y colores) solo existe en 7.x; en 5.1 detecta antes de usarlo.

---

## Sugerencias adicionales (opcionales)

- **`Get-InitConfig`**: función que devuelve un objeto *pscustomobject* con el *snapshot* clave (modo, rutas, UTC, simulaciones) para auditorías rápidas.
- **`SupportsShouldProcess`** en operaciones críticas posteriores a INIT; permitirá `-WhatIf` natural además de tu *DryRun*.
- **Rotación de logs**: en 2B, opcionalmente elimina archivos antiguos (p. ej., >30 días) del directorio `VERIFICATION`.

---

## Conclusión

La arquitectura es sólida y modular. Con los parches anteriores:
- respetas la semántica **Real vs Prueba**,  
- evitas **`Write-Host`**,  
- garantizas **trazabilidad en disco incluso en errores**,  
- eliminas conflictos de `param()` y de **zonas horarias**,  
- y alineas lo que se “silencia” con lo que realmente ocurre.

Si quieres, te lo empaqueto como un único archivo `.ps1` ya parchado (con el `param()` unificado y los módulos en orden).

