#region ScriptMetadata
<#!
Nombre   : WorkSpace_Wizard.ps1
Sumario  : Asistente integral de workspaces con interfaz WPF y compatibilidad CLI para análisis, validación y QA resiliente.

Tabla de parámetros:
| Nombre        | Tipo                 | Descripción |
|---------------|----------------------|-------------|
| Wizard        | Switch               | Inicia la interfaz WPF del asistente. |
| Path          | String[]             | Rutas a analizar desde CLI. |
| Root          | String               | Ruta raíz obligatoria para todas las operaciones. |
| Recurse       | Switch               | Analiza archivos recursivamente. |
| Include       | String[]             | Patrones de inclusión. |
| Exclude       | String[]             | Patrones de exclusión. |
| Parallel      | Switch               | Habilita procesamiento paralelo. |
| ThrottleLimit | Int (1-128)          | Límite máximo de concurrencia. |
| HashAlgorithm | String               | Algoritmo de hash (SHA256, SHA1, MD5). |
| RebuildCache  | Switch               | Reinicia la caché incremental de hashes. |
| ValidateOnly  | Switch               | Ejecuta solo los chequeos de calidad. |
| OutputPath    | String               | Carpeta destino de reportes y logs. |
| LogLevel      | String               | Nivel mínimo de logging. |
| Format        | String               | Formato de exportación (csv, json, md, all). |
#>
#endregion ScriptMetadata

#requires -Version 7.0
[CmdletBinding(SupportsShouldProcess=$false)]
param(
    [switch]$Wizard,
    [Parameter(Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Path,
    [ValidateNotNullOrEmpty()]
    [string]$Root = (Join-Path -Path $HOME -ChildPath 'mnt'),
    [switch]$Recurse,
    [string[]]$Include,
    [string[]]$Exclude,
    [switch]$Parallel,
    [ValidateRange(1,128)]
    [int]$ThrottleLimit = [Math]::Max([Environment]::ProcessorCount - 1,1),
    [ValidateSet('SHA256','SHA1','MD5')]
    [string]$HashAlgorithm = 'SHA256',
    [switch]$RebuildCache,
    [switch]$ValidateOnly,
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = (Join-Path -Path $Root -ChildPath 'out'),
    [ValidateSet('Verbose','Information','Warning','Error')]
    [string]$LogLevel = 'Information',
    [ValidateSet('csv','json','md','all')]
    [string]$Format = 'all',
    [switch]$NoExit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region GlobalVariables
$script:ExitCode = 0
$script:RunLogPath = $null
$script:RunJsonPath = $null
$script:LogLevel = $LogLevel
$script:Root = [System.IO.Path]::GetFullPath($Root)
$script:IsWindowsPlatform = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
$script:CancellationSource = $null
$script:HashCache = @{}
$script:HashCacheChanged = $false
$script:HashCacheFile = $null
$script:DryRunIssues = New-Object System.Collections.Generic.List[string]
$script:PssaFailed = $false
$script:PesterFailed = $false
$script:ActionLogPath = Join-Path -Path $script:Root -ChildPath 'logs/actions.jsonl'
$script:BackupRoot = Join-Path -Path $script:Root -ChildPath '00.Backups'
if (-not (Test-Path -LiteralPath $script:Root)) {
    New-Item -ItemType Directory -Path $script:Root -Force | Out-Null
}
#endregion GlobalVariables
#region UtilityFunctions
function Initialize-ActionLogging {
    [CmdletBinding()]
    param()

    $logDir = Split-Path -Path $script:ActionLogPath -Parent
    if (-not (Test-Path -LiteralPath $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $script:BackupRoot)) {
        New-Item -ItemType Directory -Path $script:BackupRoot -Force | Out-Null
    }
}

function Write-ActionLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Type,
        [Parameter(Mandatory)][string]$Stage,
        [Parameter(Mandatory)][string]$Status,
        [Parameter()][hashtable]$Data
    )

    Initialize-ActionLogging
    $payload = [ordered]@{
        timestamp_utc = [DateTime]::UtcNow.ToString('o', [Globalization.CultureInfo]::InvariantCulture)
        type          = $Type
        stage         = $Stage
        status        = $Status
    }
    if ($Data) {
        foreach ($key in $Data.Keys) {
            $payload[$key] = $Data[$key]
        }
    }
    $json = $payload | ConvertTo-Json -Depth 6 -Compress
    Add-Content -LiteralPath $script:ActionLogPath -Value $json -Encoding utf8
}

function Get-FileHashValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Bytes,
        [Parameter()][string]$Algorithm = 'SHA256'
    )
    $algo = switch ($Algorithm.ToUpperInvariant()) {
        'SHA1' { [System.Security.Cryptography.SHA1]::Create() }
        'MD5'  { [System.Security.Cryptography.MD5]::Create() }
        Default { [System.Security.Cryptography.SHA256]::Create() }
    }
    try {
        $hash = $algo.ComputeHash($Bytes)
        return [BitConverter]::ToString($hash).Replace('-','').ToLowerInvariant()
    }
    finally {
        $algo.Dispose()
    }
}

function Get-RelativePathUnderRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FullPath
    )

    $normalized = [System.IO.Path]::GetFullPath($FullPath)
    $rootWithSep = if ($script:Root.EndsWith([System.IO.Path]::DirectorySeparatorChar)) { $script:Root } else { $script:Root + [System.IO.Path]::DirectorySeparatorChar }
    if (-not $normalized.StartsWith($rootWithSep, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "La ruta '$FullPath' está fuera del ROOT '$($script:Root)'."
    }
    return $normalized.Substring($rootWithSep.Length)
}

function Write-StructuredLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('Verbose','Information','Warning','Error')]
        [string]$Level,
        [Parameter(Mandatory)][string]$Message,
        [Parameter()][hashtable]$Data
    )

    $levels = @('Verbose','Information','Warning','Error')
    $thresholdIndex = $levels.IndexOf($script:LogLevel)
    if ($thresholdIndex -lt 0) { $thresholdIndex = 1 }
    $currentIndex = $levels.IndexOf($Level)
    if ($currentIndex -lt $thresholdIndex) { return }

    $payload = [ordered]@{
        timestamp = [DateTime]::UtcNow.ToString('o', [Globalization.CultureInfo]::InvariantCulture)
        level     = $Level
        message   = $Message
    }
    if ($Data) {
        foreach ($key in $Data.Keys) {
            $payload[$key] = $Data[$key]
        }
    }

    if ($script:RunJsonPath) {
        if (-not (Test-Path -LiteralPath $script:RunJsonPath)) {
            New-Item -ItemType File -Path $script:RunJsonPath -Force | Out-Null
        }
        Add-Content -LiteralPath $script:RunJsonPath -Value (($payload | ConvertTo-Json -Depth 6 -Compress)) -Encoding utf8
    }

    if ($script:RunLogPath) {
        if (-not (Test-Path -LiteralPath $script:RunLogPath)) {
            New-Item -ItemType File -Path $script:RunLogPath -Force | Out-Null
        }
        Add-Content -LiteralPath $script:RunLogPath -Value ('[{0:u}] [{1}] {2}' -f [DateTime]::UtcNow, $Level.ToUpperInvariant(), $Message) -Encoding utf8
    }

    switch ($Level) {
        'Verbose'     { Write-Verbose -Message $Message }
        'Information' { Write-Information -MessageData $Message -InformationAction Continue }
        'Warning'     { Write-Warning -Message $Message }
        'Error'       { Write-Error -Message $Message }
    }
}

function Initialize-Logging {
    param(
        [Parameter(Mandatory)][string]$OutputPath
    )
    if (-not (Test-Path -LiteralPath $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    $script:RunLogPath = Join-Path -Path $OutputPath -ChildPath 'run.log'
    $script:RunJsonPath = Join-Path -Path $OutputPath -ChildPath 'run.jsonl'
}

function Set-ExitCode {
    param(
        [Parameter(Mandatory)][int]$Code,
        [string]$Reason
    )
    $script:ExitCode = $Code
    if ($Reason) {
        Write-StructuredLog -Level 'Information' -Message "ExitCode establecido a $Code" -Data @{ Reason = $Reason }
        Write-ActionLog -Type 'lifecycle' -Stage 'exit' -Status 'notified' -Data @{ code = $Code; reason = $Reason }
    }
}

function Invoke-Safe {
    param(
        [Parameter(Mandatory)][scriptblock]$ScriptBlock,
        [Parameter()][hashtable]$Data
    )
    try {
        & $ScriptBlock
    }
    catch {
        Write-StructuredLog -Level 'Error' -Message $_.Exception.Message -Data $Data
        Write-ActionLog -Type 'error' -Stage 'execution' -Status 'failed' -Data @{ message = $_.Exception.Message }
        throw
    }
}

function New-CancellationSource {
    if ($script:CancellationSource) {
        $script:CancellationSource.Dispose()
    }
    $script:CancellationSource = [System.Threading.CancellationTokenSource]::new()
    return $script:CancellationSource
}

function ConvertTo-Hashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline=$true)]
        [object]$InputObject
    )
    process {
        if ($InputObject -is [hashtable]) { return $InputObject }
        $hash = @{}
        $InputObject.PSObject.Properties | ForEach-Object { $hash[$_.Name] = $_.Value }
        return $hash
    }
}

function Get-Percentile {
    param(
        [double[]]$Values,
        [Parameter(Mandatory)][double]$Percentile
    )
    if (-not $Values -or $Values.Count -eq 0) { return 0 }
    $sorted = $Values | Sort-Object
    $index = [math]::Round(($Percentile / 100.0) * ($sorted.Count - 1))
    if ($index -lt 0) { $index = 0 }
    if ($index -ge $sorted.Count) { $index = $sorted.Count - 1 }
    return $sorted[$index]
}

function Measure-Stopwatch {
    param([Parameter(Mandatory)][scriptblock]$ScriptBlock)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & $ScriptBlock
    $sw.Stop()
    return [pscustomobject]@{ Result = $result; Elapsed = $sw.Elapsed }
}

function Get-DefaultCultureString([double]$Value,[string]$Format='F2') {
    return [string]::Format([Globalization.CultureInfo]::InvariantCulture, "{0:$Format}", $Value)
}

function Test-WindowsName {
    param([Parameter(Mandatory)][string]$Name)
    $invalid = [regex]'[<>:"/\\|?*]'
    if ($invalid.IsMatch($Name)) { return $false }
    if ($Name.TrimEnd() -ne $Name -or $Name.EndsWith('.')) { return $false }
    $reserved = @('CON','PRN','AUX','NUL','COM1','COM2','COM3','COM4','COM5','COM6','COM7','COM8','COM9','LPT1','LPT2','LPT3','LPT4','LPT5','LPT6','LPT7','LPT8','LPT9')
    if ($reserved -contains $Name.ToUpperInvariant()) { return $false }
    return $true
}
#endregion UtilityFunctions
#region FileSafety
function Save-FileWithBackupDryRun {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)][string]$Content,
        [switch]$Force
    )

    Initialize-ActionLogging
    $resolved = [System.IO.Path]::GetFullPath($LiteralPath)
    if (-not $resolved.StartsWith($script:Root, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "La ruta '$resolved' está fuera del ROOT '$($script:Root)'."
    }

    $targetDir = [System.IO.Path]::GetDirectoryName($resolved)
    if (-not (Test-Path -LiteralPath $targetDir)) {
        if ($PSCmdlet.ShouldProcess($targetDir,'Crear directorio')) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            Write-ActionLog -Type 'fs' -Stage 'directory' -Status 'created' -Data @{ path = $targetDir }
        }
    }

    $dryRunErrors = @()
    $timestamp = [DateTime]::UtcNow.ToString('yyMMddHHmm')
    $relativePath = Get-RelativePathUnderRoot -FullPath $resolved
    $relativeDir = Split-Path -Path $relativePath -Parent
    if ([string]::IsNullOrEmpty($relativeDir) -or $relativeDir -eq '.') {
        $backupDir = $script:BackupRoot
    }
    else {
        $backupDir = Join-Path -Path $script:BackupRoot -ChildPath $relativeDir
    }
    if (-not (Test-Path -LiteralPath $backupDir)) {
        if ($PSCmdlet.ShouldProcess($backupDir,'Crear carpeta de respaldo')) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
    }

    $backupFileName = '{0}.{1}.bak' -f (Split-Path -Path $resolved -Leaf), $timestamp
    $backupPath = Join-Path -Path $backupDir -ChildPath $backupFileName
    $originalBytes = $null
    $preExisting = Test-Path -LiteralPath $resolved

    if ($preExisting) {
        $originalBytes = [IO.File]::ReadAllBytes($resolved)
        if ($PSCmdlet.ShouldProcess($backupPath,'Crear respaldo')) {
            [IO.File]::WriteAllBytes($backupPath, $originalBytes)
        }
        $bakBytes = [IO.File]::ReadAllBytes($backupPath)
        if ($originalBytes.Length -ne $bakBytes.Length) {
            $dryRunErrors += "Backup size mismatch para '$resolved'."
        }
        else {
            $originalText = [Text.Encoding]::UTF8.GetString($originalBytes)
            $bakText = [Text.Encoding]::UTF8.GetString($bakBytes)
            if ($originalText -ne $bakText) {
                $dryRunErrors += "Backup text mismatch para '$resolved'."
            }
        }
        if ($originalBytes.Length -gt 51200) {
            $checksum = Get-FileHashValue -Bytes $originalBytes -Algorithm 'SHA256'
            $hashPath = "$backupPath.sha256"
            Set-Content -LiteralPath $hashPath -Value $checksum -Encoding utf8
        }
        Write-ActionLog -Type 'fs' -Stage 'backup' -Status 'created' -Data @{ path = $backupPath; source = $resolved; size = $originalBytes.Length }
    }

    if (-not $dryRunErrors) {
        if ($PSCmdlet.ShouldProcess($resolved,'Escribir archivo')) {
            [IO.File]::WriteAllText($resolved, $Content, [Text.Encoding]::UTF8)
            $backupValue = if ($preExisting) { $backupPath } else { $null }
            Write-ActionLog -Type 'fs' -Stage 'write' -Status 'success' -Data @{ path = $resolved; backup = $backupValue; timestamp = $timestamp }
        }
    }
    else {
        $script:DryRunIssues.AddRange($dryRunErrors)
        Write-ActionLog -Type 'fs' -Stage 'write' -Status 'aborted' -Data @{ path = $resolved; errors = $dryRunErrors }
        throw "Dry-run detectó inconsistencias en '$resolved'."
    }

    return $resolved
}
#endregion FileSafety
#region PathResolution
<#!
.SYNOPSIS
Resuelve rutas asegurando que permanezcan bajo el ROOT configurado.
.DESCRIPTION
Normaliza rutas relativas o absolutas y valida que el resultado se encuentre dentro de la carpeta raíz controlada.
.PARAMETER Root
Ruta raíz de seguridad.
.PARAMETER TargetPath
Ruta de entrada a evaluar.
.EXAMPLE
Resolve-UnderRoot -Root 'C:\\Work\\mnt' -TargetPath 'proyecto1'
#>
function Resolve-UnderRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$TargetPath
    )

    $normalizedRoot = [System.IO.Path]::GetFullPath($Root)
    $candidate = $TargetPath.Trim()
    if ([string]::IsNullOrWhiteSpace($candidate)) {
        throw 'La ruta no puede ser vacía.'
    }

    if (-not (Test-Path -LiteralPath $normalizedRoot)) {
        throw "El ROOT '$normalizedRoot' no existe."
    }

    if ($candidate.StartsWith('\\\')) {
        throw 'No se permiten rutas UNC.'
    }

    if (-not ($candidate -match '^[A-Za-z]:\\\\')) {
        if ($candidate.StartsWith('\\')) {
            $candidate = $candidate.TrimStart('\\')
        }
        $candidate = Join-Path -Path $normalizedRoot -ChildPath $candidate
    }

    $full = [System.IO.Path]::GetFullPath($candidate)
    $rootWithSep = if ($normalizedRoot.EndsWith([System.IO.Path]::DirectorySeparatorChar)) { $normalizedRoot } else { $normalizedRoot + [System.IO.Path]::DirectorySeparatorChar }
    if (-not $full.StartsWith($rootWithSep, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "La ruta '$full' está fuera del ROOT '$normalizedRoot'."
    }
    return $full
}
#endregion PathResolution
#region TreeValidation
<#!
.SYNOPSIS
Valida planes de árbol de carpetas sin crear archivos.
.DESCRIPTION
Analiza mapas de carpetas representados como hashtable/PSCustomObject detectando duplicados, nombres inválidos y límites configurables.
.PARAMETER Base
Ruta base sobre la que se evaluará el árbol.
.PARAMETER Map
Mapa de carpetas (hashtable u objeto) que describe el árbol deseado.
.PARAMETER MaxDepth
Profundidad máxima permitida.
.PARAMETER MaxNodes
Cantidad máxima de nodos evaluados.
.PARAMETER MaxPath
Longitud máxima de ruta en caracteres.
.PARAMETER ShowPlan
Muestra un plan hipotético de creación sin tocar disco.
.EXAMPLE
Test-TreePlan -Base 'C:\\Work\\mnt\\demo' -Map $estructura -ShowPlan
#>
function Test-TreePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Base,
        [Parameter(Mandatory)][object]$Map,
        [ValidateRange(1,128)][int]$MaxDepth = 32,
        [ValidateRange(1,10000)][int]$MaxNodes = 2000,
        [ValidateRange(32,260)][int]$MaxPath = 240,
        [switch]$ShowPlan
    )

    $summary = [ordered]@{
        Base = $Base
        PlannedNodes = 0
        Errors = @()
    }

    $mapHash = ConvertTo-Hashtable -InputObject $Map
    $baseResolved = Resolve-UnderRoot -Root $script:Root -TargetPath $Base
    $visited = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    $stack = New-Object System.Collections.Generic.Stack[object]
    $stack.Push([pscustomobject]@{ Path = $baseResolved; Node = $mapHash; Depth = 0 })
    while ($stack.Count -gt 0) {
        $frame = $stack.Pop()
        $currentPath = $frame.Path
        $depth = $frame.Depth
        if ($depth -gt $MaxDepth) {
            $summary.Errors += "Profundidad máxima excedida en '$currentPath'."
            continue
        }

        $nodeHash = ConvertTo-Hashtable -InputObject $frame.Node
        $names = $nodeHash.Keys
        $dups = $names | Group-Object { $_.ToUpperInvariant() } | Where-Object Count -gt 1
        foreach ($dup in $dups) {
            $summary.Errors += "Duplicados en '$currentPath': $($dup.Group -join ', ')"
        }

        foreach ($name in $names) {
            if (-not (Test-WindowsName -Name $name)) {
                $summary.Errors += "Nombre inválido '$name' en '$currentPath'"
                continue
            }
            $childPath = Join-Path -Path $currentPath -ChildPath $name
            if ($childPath.Length -gt $MaxPath) {
                $summary.Errors += "Ruta demasiado larga ($($childPath.Length)) en '$childPath'"
                continue
            }
            if (-not $visited.Add($childPath)) {
                $summary.Errors += "Ruta duplicada detectada '$childPath'"
                continue
            }
            $summary.PlannedNodes++
            if ($summary.PlannedNodes -gt $MaxNodes) {
                $summary.Errors += "MaxNodes excedido ($MaxNodes)."
                break
            }
            if ($ShowPlan) {
                Write-Information -MessageData "PLAN: $childPath" -InformationAction Continue
            }
            $childNode = $nodeHash[$name]
            if ($childNode -is [hashtable] -or $childNode -is [pscustomobject]) {
                $stack.Push([pscustomobject]@{ Path = $childPath; Node = $childNode; Depth = $depth + 1 })
            }
        }
    }

    return [pscustomobject]@{
        Base = $summary.Base
        PlannedNodes = $summary.PlannedNodes
        Errors = $summary.Errors
        ErrorsCount = $summary.Errors.Count
        IsValid = ($summary.Errors.Count -eq 0)
    }
}
#endregion TreeValidation
#region TemplateManagement
<#!
.SYNOPSIS
Inicializa las plantillas globales del workspace bajo el ROOT controlado.
.DESCRIPTION
Genera archivos de instrucciones y mapa de archivos reutilizables asegurando el protocolo de respaldo y validación.
.PARAMETER Root
Ruta raíz bajo la cual se materializarán las plantillas.
.EXAMPLE
Initialize-GlobalTemplates -Root 'C:\\Users\\demo\\mnt'
#>
function Initialize-GlobalTemplates {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory)][string]$Root
    )

    $resolvedRoot = Resolve-UnderRoot -Root $script:Root -TargetPath $Root
    $baseTemplates = Join-Path -Path $resolvedRoot -ChildPath 'config'
    $instructionPath = Join-Path -Path $baseTemplates -ChildPath 'plantillas\\workspace\\instructions.md'
    $mapPath = Join-Path -Path $baseTemplates -ChildPath 'filemaps\\standard.json'

    $instructionContent = @'
# Guía de trabajo del workspace
- Todas las rutas deben residir bajo el ROOT configurado.
- Utiliza `Resolve-UnderRoot` antes de crear nuevas carpetas.
- Los proyectos deben crear las carpetas: docs/, src/, config/, results/.
- Mantén logs en `<root>\logs`.
'@

    $mapContent = @'
{
    "schema": "filemap@1",
    "root": "",
    "tree": {
        "data": {"proyectos": {}, "datasets": {}},
        "docs": {"manuales": {}, "notas": {}, "chatgpt": {}},
        "config": {"sistemas": {}, "proyectos": {}, "plantillas": {}},
        "archive": {"proyectos": {}, "docs": {}},
        "tmp": {}
    },
    "defaults": {
        "projectSkeleton": ["docs","src","config","results"]
    }
}
'@

    Save-FileWithBackupDryRun -LiteralPath $instructionPath -Content $instructionContent -Force:$true | Out-Null
    Save-FileWithBackupDryRun -LiteralPath $mapPath -Content $mapContent -Force:$true | Out-Null

    return [pscustomobject]@{ Instructions = $instructionPath; FileMap = $mapPath }
}

<#!
.SYNOPSIS
Instala plantillas del workspace dentro de un proyecto específico.
.DESCRIPTION
Copia los archivos de plantillas globales dentro del proyecto objetivo, ajustando el mapa y respetando protocolos de respaldo.
.PARAMETER ProjectPath
Ruta del proyecto bajo ROOT.
.PARAMETER Root
Ruta raíz de control.
.PARAMETER GlobalTemplates
Objeto con rutas de instrucciones y mapa global.
.PARAMETER Skeleton
Lista opcional de carpetas por defecto.
.PARAMETER Overwrite
Forzar reescritura de plantillas.
.EXAMPLE
Install-Workspace -ProjectPath 'C:\\Users\\demo\\mnt\\data\\proyecto' -Root 'C:\\Users\\demo\\mnt' -GlobalTemplates $templates
#>
function Install-Workspace {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory)][string]$ProjectPath,
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][psobject]$GlobalTemplates,
        [string[]]$Skeleton,
        [switch]$Overwrite
    )

    $resolvedProject = Resolve-UnderRoot -Root $script:Root -TargetPath $ProjectPath
    $workspaceDir = Join-Path -Path $resolvedProject -ChildPath '.workspace'
    if (-not (Test-Path -LiteralPath $workspaceDir)) {
        if ($PSCmdlet.ShouldProcess($workspaceDir,'Crear directorio de workspace')) {
            New-Item -ItemType Directory -Path $workspaceDir -Force | Out-Null
            Write-ActionLog -Type 'fs' -Stage 'directory' -Status 'created' -Data @{ path = $workspaceDir }
        }
    }

    $instructionTarget = Join-Path -Path $workspaceDir -ChildPath 'instructions.md'
    $mapTarget = Join-Path -Path $workspaceDir -ChildPath 'filemap.json'

    if ($Overwrite -or -not (Test-Path -LiteralPath $instructionTarget)) {
        $content = Get-Content -LiteralPath $GlobalTemplates.Instructions -Raw -ErrorAction Stop
        Save-FileWithBackupDryRun -LiteralPath $instructionTarget -Content $content -Force:$true | Out-Null
    }

    if ($Overwrite -or -not (Test-Path -LiteralPath $mapTarget)) {
        $mapContent = Get-Content -LiteralPath $GlobalTemplates.FileMap -Raw -ErrorAction Stop
        Save-FileWithBackupDryRun -LiteralPath $mapTarget -Content $mapContent -Force:$true | Out-Null
    }

    $mapJson = Get-Content -LiteralPath $mapTarget -Raw | ConvertFrom-Json -Depth 10
    $mapJson.root = $script:Root
    if ($Skeleton) { $mapJson.defaults.projectSkeleton = $Skeleton }
    ($mapJson | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath $mapTarget -Encoding utf8

    $gitIgnore = Join-Path -Path $resolvedProject -ChildPath '.gitignore'
    if (-not (Test-Path -LiteralPath $gitIgnore)) {
        Save-FileWithBackupDryRun -LiteralPath $gitIgnore -Content "# Workspace Wizard`n.workspace/`n" -Force:$true | Out-Null
    }
    else {
        $gitContent = Get-Content -LiteralPath $gitIgnore -Raw
        if ($gitContent -notmatch '\\.workspace/') {
            $gitContent += "`n.workspace/`n"
            Save-FileWithBackupDryRun -LiteralPath $gitIgnore -Content $gitContent -Force:$true | Out-Null
        }
    }

    return [pscustomobject]@{
        WorkspaceDir = $workspaceDir
        Instructions = $instructionTarget
        FileMap = $mapTarget
    }
}
#endregion TemplateManagement
#region Hashing
function Initialize-HashCache {
    param(
        [Parameter(Mandatory)][string]$OutputPath,
        [switch]$Rebuild
    )
    $cachePath = Join-Path -Path $OutputPath -ChildPath 'hash-cache.json'
    $script:HashCacheFile = $cachePath
    if ($Rebuild -and (Test-Path -LiteralPath $cachePath)) {
        Remove-Item -LiteralPath $cachePath -Force
    }
    if (Test-Path -LiteralPath $cachePath) {
        try {
            $script:HashCache = Get-Content -LiteralPath $cachePath -Raw | ConvertFrom-Json -Depth 6 | ConvertTo-Hashtable
        }
        catch {
            Write-StructuredLog -Level 'Warning' -Message "No se pudo cargar la caché de hashes: $($_.Exception.Message). Se reiniciará."
            $script:HashCache = @{}
        }
    }
    else {
        $script:HashCache = @{}
    }
    $script:HashCacheChanged = $false
}

function Save-HashCache {
    if (-not $script:HashCacheFile) { return }
    if (-not $script:HashCacheChanged) { return }
    $json = $script:HashCache | ConvertTo-Json -Depth 6
    Set-Content -LiteralPath $script:HashCacheFile -Value $json -Encoding utf8
    $script:HashCacheChanged = $false
}

function Get-HashCacheKey {
    param(
        [Parameter(Mandatory)][System.IO.FileInfo]$File,
        [Parameter(Mandatory)][string]$Algorithm
    )
    return '{0}|{1}|{2:O}|{3}' -f $File.FullName, $File.Length, $File.LastWriteTimeUtc, $Algorithm.ToUpperInvariant()
}

function New-HashAlgorithm {
    param([Parameter(Mandatory)][string]$Name)
    switch ($Name.ToUpperInvariant()) {
        'SHA1'   { return [System.Security.Cryptography.SHA1]::Create() }
        'MD5'    { return [System.Security.Cryptography.MD5]::Create() }
        default  { return [System.Security.Cryptography.SHA256]::Create() }
    }
}

function Get-IOExceptionCategory {
    param([System.IO.IOException]$Exception)
    if ($Exception -is [System.UnauthorizedAccessException]) { return 'AccessDenied' }
    if ($Exception.HResult -band 0xFFFF -eq 32) { return 'SharingViolation' }
    if ($Exception.HResult -band 0xFFFF -eq 33) { return 'Locked' }
    return 'IOError'
}

function Invoke-HashWorker {
    param(
        [Parameter(Mandatory)][System.IO.FileInfo]$File,
        [Parameter(Mandatory)][string]$Algorithm,
        [Parameter(Mandatory)][System.Threading.CancellationToken]$Token
    )

    $result = [pscustomobject]@{ Hash=$null; Status='Skipped'; Duration=0.0; Error=$null; Algorithm=$Algorithm }
    if ($Token.IsCancellationRequested) { return $result }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $maxRetry = 5
    $delay = 0.1
    for ($attempt = 1; $attempt -le $maxRetry; $attempt++) {
        if ($Token.IsCancellationRequested) { break }
        try {
            $hashAlgo = New-HashAlgorithm -Name $Algorithm
            try {
                $stream = [System.IO.File]::Open($File.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                try {
                    $buffer = New-Object byte[] 1048576
                    while (($read = $stream.Read($buffer,0,$buffer.Length)) -gt 0) {
                        if ($Token.IsCancellationRequested) { throw [OperationCanceledException]::new() }
                        $hashAlgo.TransformBlock($buffer,0,$read,$buffer,0) | Out-Null
                    }
                    $hashAlgo.TransformFinalBlock([byte[]]::new(0),0,0) | Out-Null
                    $result.Hash = [BitConverter]::ToString($hashAlgo.Hash).Replace('-','').ToLowerInvariant()
                    $result.Status = 'OK'
                    break
                }
                finally {
                    $stream.Dispose()
                }
            }
            finally {
                $hashAlgo.Dispose()
            }
        }
        catch [OperationCanceledException] {
            $result.Status = 'Skipped'
            break
        }
        catch [System.IO.IOException] {
            $category = Get-IOExceptionCategory -Exception $_.Exception
            $result.Status = "Error:$category"
            $result.Error = $category
            if ($attempt -lt $maxRetry) {
                Start-Sleep -Seconds $delay
                $delay = [Math]::Min($delay * 2, 5)
                continue
            }
            else {
                break
            }
        }
        catch {
            $result.Status = 'Error:Unhandled'
            $result.Error = $_.Exception.Message
            break
        }
    }
    $sw.Stop()
    $result.Duration = $sw.Elapsed.TotalSeconds
    return $result
}
#endregion Hashing
#region ProcessingCore
function Get-TargetFiles {
    param(
        [Parameter(Mandatory)][string[]]$Paths,
        [switch]$Recurse,
        [string[]]$Include,
        [string[]]$Exclude
    )
    $files = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    foreach ($path in $Paths) {
        $resolved = Resolve-UnderRoot -Root $script:Root -TargetPath $path
        if (-not (Test-Path -LiteralPath $resolved)) { continue }
        $items = Get-ChildItem -LiteralPath $resolved -File -Force -Recurse:$Recurse
        foreach ($item in $items) {
            $matchInclude = $true
            if ($Include) {
                $matchInclude = $false
                foreach ($pattern in $Include) {
                    if ($item.Name -like $pattern -or $item.FullName -like $pattern) { $matchInclude = $true; break }
                }
            }
            if (-not $matchInclude) { continue }
            if ($Exclude) {
                $skip = $false
                foreach ($pattern in $Exclude) {
                    if ($item.Name -like $pattern -or $item.FullName -like $pattern) { $skip = $true; break }
                }
                if ($skip) { continue }
            }
            $files.Add($item)
        }
    }
    return ,($files.ToArray())
}

function Get-DesiredThrottle {
    param(
        [Parameter(Mandatory)][double]$AverageSize,
        [Parameter(Mandatory)][double]$ErrorRate,
        [Parameter(Mandatory)][int]$MaxThrottle
    )
    $base = if ($AverageSize -le 1MB) {
        [Math]::Min($MaxThrottle, [Math]::Max(4, [Environment]::ProcessorCount))
    } elseif ($AverageSize -le 10MB) {
        [Math]::Min($MaxThrottle, [Math]::Max(2, [Math]::Ceiling([Environment]::ProcessorCount / 2)))
    } else {
        [Math]::Min($MaxThrottle, 2)
    }
    if ($ErrorRate -gt 0.05) {
        $base = [Math]::Max(1, [Math]::Floor($base / 2))
    }
    return [Math]::Max(1, [Math]::Min($MaxThrottle, $base))
}

function New-HashRunspacePool {
    param([int]$Throttle)
    $initial = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $functions = @('New-HashAlgorithm','Get-IOExceptionCategory','Invoke-HashWorker')
    foreach ($name in $functions) {
        $command = Get-Command -Name $name -CommandType Function
        $entry = [System.Management.Automation.Runspaces.SessionStateFunctionEntry]::new($command.Name, $command.ScriptBlock)
        $initial.Commands.Add($entry)
    }
    $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1,$Throttle,$initial,$Host)
    $pool.ApartmentState = [System.Threading.ApartmentState]::MTA
    $pool.Open()
    return $pool
}

<#!
.SYNOPSIS
Ejecuta el núcleo de análisis de archivos con hashing, fingerprints y reportes.
.DESCRIPTION
Procesa archivos bajo ROOT aplicando caché incremental, concurrencia adaptativa, manejo de errores y exportes múltiples.
.PARAMETER InPath
Rutas a procesar.
.PARAMETER Recurse
Analiza recursivamente.
.PARAMETER Include
Patrones de inclusión.
.PARAMETER Exclude
Patrones de exclusión.
.PARAMETER Parallel
Habilita procesamiento paralelo.
.PARAMETER ThrottleLimit
Límite máximo de concurrencia.
.PARAMETER OutputPath
Carpeta de salida para reportes.
.PARAMETER Format
Formato de exportación deseado.
.PARAMETER HashAlgorithm
Algoritmo de hashing.
.PARAMETER RebuildCache
Reinicia la caché incremental.
.PARAMETER Headless
Indica ejecución sin GUI (para logging de consola).
.EXAMPLE
Invoke-ProcessingCore -InPath 'data' -Recurse -Parallel -ThrottleLimit 8 -HashAlgorithm SHA256 -OutputPath '.\\out'
#>
function Invoke-ProcessingCore {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory)][string[]]$InPath,
        [switch]$Recurse,
        [string[]]$Include,
        [string[]]$Exclude,
        [switch]$Parallel,
        [ValidateRange(1,128)][int]$ThrottleLimit,
        [Parameter(Mandatory)][string]$OutputPath,
        [ValidateSet('csv','json','md','all')][string]$Format,
        [ValidateSet('SHA256','SHA1','MD5')][string]$HashAlgorithm,
        [switch]$RebuildCache,
        [switch]$Headless,
        [scriptblock]$ProgressCallback
    )

    $resolvedOutput = Resolve-UnderRoot -Root $script:Root -TargetPath $OutputPath
    if ($PSCmdlet.ShouldProcess($resolvedOutput,'Inicializar logging')) {
        Initialize-Logging -OutputPath $resolvedOutput
    }
    Initialize-HashCache -OutputPath $resolvedOutput -Rebuild:$RebuildCache

    $rawFiles = Get-TargetFiles -Paths $InPath -Recurse:$Recurse -Include $Include -Exclude $Exclude
    $files = if ($null -eq $rawFiles) {
        @()
    }
    elseif ($rawFiles -is [System.Array]) {
        $rawFiles
    }
    else {
        @($rawFiles)
    }
    $targetCount = if ($null -eq $rawFiles) {
        0
    }
    elseif ($rawFiles -is [System.Array]) {
        $rawFiles.Length
    }
    elseif ($rawFiles -is [System.Collections.ICollection]) {
        $rawFiles.Count
    }
    else {
        1
    }

    Write-StructuredLog -Level 'Verbose' -Message 'Archivos objetivo resueltos' -Data @{
        type  = if ($null -eq $rawFiles) { 'null' } else { $rawFiles.GetType().FullName }
        count = $targetCount
    }
    if ($targetCount -eq 0) {
        Write-StructuredLog -Level 'Warning' -Message 'No se encontraron archivos para procesar.'
        return [pscustomobject]@{ Results=@(); Fingerprints=@(); Summary=[ordered]@{ TotalFiles=0; DurationSeconds=0; CacheHits=0; Errors=@{} } }
    }

    $totalFiles = $targetCount
    $processed = 0
    $cacheHits = 0
    $errorCounts = @{}
    $fileDurations = New-Object System.Collections.Generic.List[double]
    $fileSizes = New-Object System.Collections.Generic.List[double]
    $statusData = New-Object System.Collections.Generic.List[object]
    $startTime = [DateTime]::UtcNow
    $tokenSource = New-CancellationSource
    $token = $tokenSource.Token
    $headlessCounter = 0

    $pool = $null
    $jobs = New-Object System.Collections.Generic.List[object]
    $currentThrottle = if ($Parallel) { [Math]::Min($ThrottleLimit, [Environment]::ProcessorCount) } else { 1 }

    if ($Parallel) {
        $pool = New-HashRunspacePool -Throttle $currentThrottle
    }

    try {
        foreach ($file in $files) {
            if ($token.IsCancellationRequested) { break }
            $fileSizes.Add([double]$file.Length)
            $key = Get-HashCacheKey -File $file -Algorithm $HashAlgorithm
            if ($script:HashCache.ContainsKey($key)) {
                $cacheHits++
                $processed++
                $hashValue = $script:HashCache[$key]
                $statusData.Add([pscustomobject]@{
                    Name = $file.Name
                    FullName = $file.FullName
                    Length = $file.Length
                    Directory = $file.DirectoryName
                    Hash = $hashValue
                    LastWrite = $file.LastWriteTimeUtc
                    Status = 'Cached'
                    Algorithm = $HashAlgorithm
                    DurationSeconds = 0
                })
                if ($Headless -and (++$headlessCounter % 200 -eq 0)) {
                    Write-Information -MessageData "Progreso: $processed / $totalFiles (cache hits: $cacheHits)" -InformationAction Continue
                }
                if ($ProgressCallback) {
                    $ProgressCallback.Invoke([pscustomobject]@{ Processed=$processed; Total=$totalFiles; CacheHits=$cacheHits; Errors=$errorCounts.Clone(); LastFile=$file.FullName }) | Out-Null
                }
                continue
            }

            if (-not $Parallel) {
                $jobResult = Invoke-HashWorker -File $file -Algorithm $HashAlgorithm -Token $token
                $processed++
                if ($jobResult.Status -like 'Error:*') {
                    if (-not $errorCounts.ContainsKey($jobResult.Error)) { $errorCounts[$jobResult.Error] = 0 }
                    $errorCounts[$jobResult.Error]++
                }
                elseif ($jobResult.Status -eq 'OK') {
                    $script:HashCache[$key] = $jobResult.Hash
                    $script:HashCacheChanged = $true
                }
                $fileDurations.Add([double]$jobResult.Duration)
                $statusData.Add([pscustomobject]@{
                    Name = $file.Name
                    FullName = $file.FullName
                    Length = $file.Length
                    Directory = $file.DirectoryName
                    Hash = $jobResult.Hash
                    LastWrite = $file.LastWriteTimeUtc
                    Status = $jobResult.Status
                    Algorithm = $HashAlgorithm
                    DurationSeconds = $jobResult.Duration
                })
                if ($Headless -and (++$headlessCounter % 200 -eq 0)) {
                    Write-Information -MessageData "Progreso: $processed / $totalFiles" -InformationAction Continue
                }
                if ($ProgressCallback) {
                    $ProgressCallback.Invoke([pscustomobject]@{ Processed=$processed; Total=$totalFiles; CacheHits=$cacheHits; Errors=$errorCounts.Clone(); LastFile=$file.FullName }) | Out-Null
                }
            }
            else {
                while ($jobs.Count -ge $currentThrottle) {
                    $handled = $false
                    foreach ($completed in @($jobs)) {
                        if ($completed.Handle.AsyncWaitHandle.WaitOne(10)) {
                            $outputCollection = $completed.PowerShell.EndInvoke($completed.Handle)
                            $completed.PowerShell.Dispose()
                            [void]$jobs.Remove($completed)
                            $processed++
                            $jobResult = if ($outputCollection.Count -gt 0) { $outputCollection[0].BaseObject } else { $null }
                            if ($jobResult.Status -like 'Error:*') {
                                if (-not $errorCounts.ContainsKey($jobResult.Error)) { $errorCounts[$jobResult.Error] = 0 }
                                $errorCounts[$jobResult.Error]++
                            }
                            elseif ($jobResult.Status -eq 'OK') {
                                $script:HashCache[$completed.CacheKey] = $jobResult.Hash
                                $script:HashCacheChanged = $true
                            }
                            $fileDurations.Add([double]$jobResult.Duration)
                            $statusData.Add([pscustomobject]@{
                                Name = $completed.File.Name
                                FullName = $completed.File.FullName
                                Length = $completed.File.Length
                                Directory = $completed.File.DirectoryName
                                Hash = $jobResult.Hash
                                LastWrite = $completed.File.LastWriteTimeUtc
                                Status = $jobResult.Status
                                Algorithm = $HashAlgorithm
                                DurationSeconds = $jobResult.Duration
                            })
                            if ($ProgressCallback) {
                                $ProgressCallback.Invoke([pscustomobject]@{ Processed=$processed; Total=$totalFiles; CacheHits=$cacheHits; Errors=$errorCounts.Clone(); LastFile=$completed.File.FullName }) | Out-Null
                            }
                            $handled = $true
                            break
                        }
                    }
                    if (-not $handled) { break }
                }
                $ps = [PowerShell]::Create()
                $ps.RunspacePool = $pool
                $null = $ps.AddCommand('Invoke-HashWorker').AddArgument($file).AddArgument($HashAlgorithm).AddArgument($token)
                $handle = $ps.BeginInvoke()
                $jobs.Add([pscustomobject]@{ PowerShell=$ps; Handle=$handle; File=$file; CacheKey=$key })

                $avgSize = if ($fileSizes.Count -gt 0) { ($fileSizes | Measure-Object -Average).Average } else { 0 }
                $errorSum = if ($errorCounts.Count -gt 0) { ($errorCounts.GetEnumerator() | Measure-Object -Property Value -Sum).Sum } else { 0 }
                $errorRate = if ($processed -gt 0) { $errorSum / $processed } else { 0 }
                $desired = Get-DesiredThrottle -AverageSize $avgSize -ErrorRate $errorRate -MaxThrottle $ThrottleLimit
                if ($desired -ne $currentThrottle) {
                    $pool.SetMaxRunspaces($desired)
                    $currentThrottle = $desired
                }
            }
        }

        foreach ($job in $jobs.ToArray()) {
            $outputCollection = $job.PowerShell.EndInvoke($job.Handle)
            $processed++
            $job.PowerShell.Dispose()
            $jobResult = if ($outputCollection.Count -gt 0) { $outputCollection[0].BaseObject } else { $null }
            if ($jobResult.Status -like 'Error:*') {
                if (-not $errorCounts.ContainsKey($jobResult.Error)) { $errorCounts[$jobResult.Error] = 0 }
                $errorCounts[$jobResult.Error]++
            }
            elseif ($jobResult.Status -eq 'OK') {
                $script:HashCache[$job.CacheKey] = $jobResult.Hash
                $script:HashCacheChanged = $true
            }
            $fileDurations.Add([double]$jobResult.Duration)
            $statusData.Add([pscustomobject]@{
                Name = $job.File.Name
                FullName = $job.File.FullName
                Length = $job.File.Length
                Directory = $job.File.DirectoryName
                Hash = $jobResult.Hash
                LastWrite = $job.File.LastWriteTimeUtc
                Status = $jobResult.Status
                Algorithm = $HashAlgorithm
                DurationSeconds = $jobResult.Duration
            })
            if ($ProgressCallback) {
                $ProgressCallback.Invoke([pscustomobject]@{ Processed=$processed; Total=$totalFiles; CacheHits=$cacheHits; Errors=$errorCounts.Clone(); LastFile=$job.File.FullName }) | Out-Null
            }
        }
        $jobs.Clear()
    }
    finally {
        if ($jobs) {
            foreach ($job in $jobs) {
                if ($job.PowerShell.InvocationStateInfo.State -eq 'Running') {
                    $job.PowerShell.Stop()
                }
                $job.PowerShell.Dispose()
            }
        }
        if ($pool) { $pool.Close(); $pool.Dispose() }
        Save-HashCache
    }

    $duration = ([DateTime]::UtcNow - $startTime).TotalSeconds
    $validResults = $statusData | Where-Object { $_.Hash }
    $byDirectory = $validResults | Group-Object -Property Directory
    $fingerprints = foreach ($group in $byDirectory) {
        $concat = ($group.Group | Sort-Object -Property Name | ForEach-Object { $_.Hash }) -join ''
        if ([string]::IsNullOrEmpty($concat)) { continue }
        $algo = [System.Security.Cryptography.SHA256]::Create()
        try {
            $bytes = [Text.Encoding]::UTF8.GetBytes($concat)
            $fp = [BitConverter]::ToString($algo.ComputeHash($bytes)).Replace('-','').ToLowerInvariant()
        }
        finally { $algo.Dispose() }
        [pscustomobject]@{
            Directory = $group.Name
            Fingerprint = $fp
            Files = $group.Count
            TotalSize = ($group.Group | Measure-Object -Property Length -Sum).Sum
        }
    }

    $summary = [ordered]@{
        TotalFiles = $totalFiles
        Processed = $processed
        CacheHits = $cacheHits
        DurationSeconds = [Math]::Round($duration,2)
        Throughput = if ($duration -gt 0) { [Math]::Round($processed / $duration,2) } else { $processed }
        p50 = Get-Percentile -Values $fileDurations.ToArray() -Percentile 50
        p95 = Get-Percentile -Values $fileDurations.ToArray() -Percentile 95
        p99 = Get-Percentile -Values $fileDurations.ToArray() -Percentile 99
        Errors = $errorCounts
    }

    if ($PSCmdlet.ShouldProcess($resolvedOutput,'Exportar reportes')) {
        if ($Format -in @('csv','all')) {
            $statusData | Select-Object Name,FullName,Length,Directory,Hash,LastWrite,Status,Algorithm | Export-Csv -LiteralPath (Join-Path $resolvedOutput 'results.csv') -NoTypeInformation -Encoding utf8
            $fingerprints | Export-Csv -LiteralPath (Join-Path $resolvedOutput 'fingerprints.csv') -NoTypeInformation -Encoding utf8
        }
        if ($Format -in @('json','all')) {
            ($statusData | Select-Object Name,FullName,Length,Directory,Hash,LastWrite,Status,Algorithm) | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $resolvedOutput 'results.json') -Encoding utf8
            ($fingerprints | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath (Join-Path $resolvedOutput 'fingerprints.json') -Encoding utf8
        }
        if ($Format -in @('md','all')) {
            $md = [System.Text.StringBuilder]::new()
            [void]$md.AppendLine('# Workspace Wizard Results')
            [void]$md.AppendLine('## Summary')
            foreach ($key in $summary.Keys) {
                if ($key -eq 'Errors') { continue }
                [void]$md.AppendLine("- **$($key)**: $($summary[$key])")
            }
            if ($summary.Errors.Count -gt 0) {
                [void]$md.AppendLine('- **Errores**:')
                foreach ($errKey in $summary.Errors.Keys) {
                    [void]$md.AppendLine("  - $($errKey): $($summary.Errors[$errKey])")
                }
            }
            [void]$md.AppendLine('')
            [void]$md.AppendLine('| Name | Length | Hash | Directory | Status | Algorithm |')
            [void]$md.AppendLine('| --- | ---: | --- | --- | --- | --- |')
            foreach ($row in $statusData) {
                [void]$md.AppendLine("| $($row.Name) | $([string]::Format([Globalization.CultureInfo]::InvariantCulture,'{0:N0}',$row.Length)) | $($row.Hash) | $($row.Directory) | $($row.Status) | $($row.Algorithm) |")
            }
            Set-Content -LiteralPath (Join-Path $resolvedOutput 'results.md') -Value $md.ToString() -Encoding utf8
        }
    }

    Write-StructuredLog -Level 'Information' -Message 'Procesamiento completado' -Data $summary

    return [pscustomobject]@{
        Results = $statusData
        Fingerprints = $fingerprints
        Summary = $summary
    }
}
#endregion ProcessingCore
#region QAResources
<#!
.SYNOPSIS
Inicializa los recursos internos de QA (PSSA y Pester) en la carpeta de salida.
.DESCRIPTION
Materializa archivos baseline para PSScriptAnalyzer y pruebas Pester siguiendo el protocolo de respaldo y dry-run.
.PARAMETER OutputPath
Carpeta base donde se crearán los recursos.
.PARAMETER Force
Reescribe los archivos incluso si existen.
.EXAMPLE
Initialize-QAResources -OutputPath '.\\out' -Force
#>
function Initialize-QAResources {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory)][string]$OutputPath,
        [switch]$Force
    )

    $resolvedOutput = Resolve-UnderRoot -Root $script:Root -TargetPath $OutputPath
    $qaRoot = Join-Path -Path $resolvedOutput -ChildPath '.qa'
    $testsRoot = Join-Path -Path $qaRoot -ChildPath 'Tests'
    if (-not (Test-Path -LiteralPath $qaRoot)) {
        if ($PSCmdlet.ShouldProcess($qaRoot,'Crear carpeta QA')) { New-Item -ItemType Directory -Path $qaRoot -Force | Out-Null }
    }
    if (-not (Test-Path -LiteralPath $testsRoot)) {
        if ($PSCmdlet.ShouldProcess($testsRoot,'Crear carpeta Tests')) { New-Item -ItemType Directory -Path $testsRoot -Force | Out-Null }
    }

    $pssaPath = Join-Path -Path $qaRoot -ChildPath 'PSScriptAnalyzerSettings.psd1'
    $pesterPath = Join-Path -Path $testsRoot -ChildPath 'WorkspaceWizard.Tests.ps1'

    if ($Force -or -not (Test-Path -LiteralPath $pssaPath)) {
        Save-FileWithBackupDryRun -LiteralPath $pssaPath -Content $script:BaselinePssa -Force:$true | Out-Null
    }

    if ($Force -or -not (Test-Path -LiteralPath $pesterPath)) {
        Save-FileWithBackupDryRun -LiteralPath $pesterPath -Content $script:BaselinePester -Force:$true | Out-Null
    }

    return [pscustomobject]@{
        SettingsPath = $pssaPath
        TestsPath = $pesterPath
    }
}

function Invoke-LightweightStaticChecks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ScriptPath
    )

    $scriptContent = Get-Content -LiteralPath $ScriptPath -Raw
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$null, [ref]$null)
    $findings = New-Object System.Collections.Generic.List[pscustomobject]

    $functions = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    foreach ($function in $functions) {
        $name = $function.Name
        $hasHelp = $false
        try { $hasHelp = $function.GetHelpContent() -ne $null } catch { $hasHelp = $false }
        $attributes = @()
        if ($function.Body -and $function.Body.ParamBlock) {
            $attributes = $function.Body.ParamBlock.Attributes
        }
        $hasCmdletBinding = $attributes | Where-Object { $_.TypeName.FullName -eq 'System.Management.Automation.CmdletBindingAttribute' }
        if (-not $hasHelp -and $name -match '^[A-Z]') {
            $findings.Add([pscustomobject]@{ Severity='Warning'; Rule='HelpComment'; Message="Falta comentario de ayuda en $name." })
        }
        if ($function.Name -match 'Install|Initialize|Invoke|Save' -and -not $hasCmdletBinding) {
            $findings.Add([pscustomobject]@{ Severity='Warning'; Rule='CmdletBinding'; Message="Función $name debería exponer CmdletBinding." })
        }
        if ($function.Body -and $function.Body.EndBlock) {
            $commandUses = $function.Body.EndBlock.Statements | Where-Object { $_ -is [System.Management.Automation.Language.CommandAst] -and $_.GetCommandName() -eq 'Write-Host' }
            if ($commandUses) {
                $findings.Add([pscustomobject]@{ Severity='Warning'; Rule='AvoidWriteHost'; Message="Uso de Write-Host en $name." })
            }
        }
    }

    if ($scriptContent -notmatch 'Set-StrictMode') {
        $findings.Add([pscustomobject]@{ Severity='Error'; Rule='StrictMode'; Message='Set-StrictMode no encontrado.' })
    }
    if ($scriptContent -notmatch '\\$ErrorActionPreference\\s*=\\s*''Stop''') {
        $findings.Add([pscustomobject]@{ Severity='Error'; Rule='ErrorActionPreference'; Message='ErrorActionPreference debe ser Stop.' })
    }

    return $findings
}
#endregion QAResources
#region QualityChecks
<#!
.SYNOPSIS
Ejecuta verificaciones de calidad con PSScriptAnalyzer y Pester o sus alternativas internas.
.DESCRIPTION
Utiliza configuraciones externas si existen, o el baseline interno materializado. Soporta fallback ligero cuando los módulos no están instalados.
.PARAMETER ScriptRoot
Carpeta raíz del código a analizar.
.PARAMETER OutputPath
Directorio donde se generan los reportes.
.PARAMETER Force
Recrea los artefactos de QA internos.
.EXAMPLE
Invoke-QualityChecks -ScriptRoot $PSScriptRoot -OutputPath '.\\out'
#>
function Invoke-QualityChecks {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory)][string]$ScriptRoot,
        [Parameter(Mandatory)][string]$OutputPath,
        [switch]$Force
    )

    $resolvedOutput = Resolve-UnderRoot -Root $script:Root -TargetPath $OutputPath
    if ($PSCmdlet.ShouldProcess($resolvedOutput,'Preparar recursos QA')) {
        Initialize-QAResources -OutputPath $resolvedOutput -Force:$Force | Out-Null
    }

    $pssaResultPath = Join-Path -Path $resolvedOutput -ChildPath 'quality-pssa.json'
    $pesterResultPath = Join-Path -Path $resolvedOutput -ChildPath 'quality-pester.json'
    $coveragePath = Join-Path -Path $resolvedOutput -ChildPath 'coverage.cobertura.xml'
    $junitPath = Join-Path -Path $resolvedOutput -ChildPath 'testresults.junit.xml'

    $externalSettings = Join-Path -Path $ScriptRoot -ChildPath 'PSScriptAnalyzerSettings.psd1'
    $qaSettings = Join-Path -Path (Join-Path -Path $resolvedOutput -ChildPath '.qa') -ChildPath 'PSScriptAnalyzerSettings.psd1'
    $settingsToUse = if (Test-Path -LiteralPath $externalSettings) { $externalSettings } else { $qaSettings }

    $pssaAvailable = (Get-Module -ListAvailable -Name PSScriptAnalyzer -ErrorAction SilentlyContinue)
    $pesterAvailable = (Get-Module -ListAvailable -Name Pester -ErrorAction SilentlyContinue)

    $pssaResults = @()
    $pesterResults = $null
    $fallbackUsed = $false

    if ($pssaAvailable) {
        try {
            $pssaResults = Invoke-ScriptAnalyzer -Path $ScriptRoot -Settings $settingsToUse -Recurse -Severity @('Error','Warning') -ErrorAction Stop
        }
        catch {
            Write-StructuredLog -Level 'Warning' -Message "Fallo PSScriptAnalyzer: $($_.Exception.Message). Se usará fallback."
            $pssaResults = Invoke-LightweightStaticChecks -ScriptPath (Join-Path -Path $ScriptRoot -ChildPath (Split-Path -Leaf $PSCommandPath))
            $fallbackUsed = $true
        }
    }
    else {
        $fallbackUsed = $true
        $targetScript = Get-ChildItem -Path $ScriptRoot -Filter '*.ps1' | Select-Object -First 1
        if ($targetScript) {
            $pssaResults = Invoke-LightweightStaticChecks -ScriptPath $targetScript.FullName
        }
    }

    $pssaPayload = [ordered]@{
        'Fallback-Checks' = $fallbackUsed
        Results = $pssaResults
    }
    $pssaPayload | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $pssaResultPath -Encoding utf8

    if (-not $pssaAvailable -or $fallbackUsed) {
        $script:PssaFailed = ($pssaResults | Where-Object { $_.Severity -eq 'Error' }).Count -gt 0
    }
    else {
        $script:PssaFailed = ($pssaResults | Where-Object { $_.Severity -eq 'Error' }).Count -gt 0
    }

    if ($pesterAvailable) {
        try {
            $config = [PesterConfiguration]::Default
            $config.Run.Path = $ScriptRoot
            $config.Output.Verbosity = 'Detailed'
            $config.CodeCoverage.Enabled = $true
            $config.CodeCoverage.OutputPath = $coveragePath
            $config.Run.PassThru = $true
            $config.TestResult.Enabled = $true
            $config.TestResult.OutputPath = $junitPath
            $pesterResults = Invoke-Pester -Configuration $config
            $pesterResults | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $pesterResultPath -Encoding utf8
            $script:PesterFailed = -not $pesterResults.TestResult.WasSuccessful
        }
        catch {
            Write-StructuredLog -Level 'Warning' -Message "Fallo Pester: $($_.Exception.Message). Se usará fallback." -Data @{ stage='Pester' }
            $pesterAvailable = $false
        }
    }

    if (-not $pesterAvailable) {
        $fallbackUsed = $true
        $pesterPayload = [ordered]@{
            'Fallback-Checks' = $true
            Summary = [ordered]@{
                Tests = 0
                Passed = 0
                Failed = 0
            }
        }
        $pesterPayload | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $pesterResultPath -Encoding utf8
        '<coverage/> ' | Set-Content -LiteralPath $coveragePath -Encoding utf8
        '<testsuite name="Fallback" tests="0" failures="0" />' | Set-Content -LiteralPath $junitPath -Encoding utf8
        $script:PesterFailed = $false
    }

    return [pscustomobject]@{
        Pssa = $pssaResults
        Pester = $pesterResults
        Settings = $settingsToUse
        Fallback = $fallbackUsed
    }
}
#endregion QualityChecks
#region AnalyzerCli
<#!
.SYNOPSIS
Punto de entrada para ejecutar el analizador de manera programática o desde CLI.
.DESCRIPTION
Coordina análisis de archivos, generación de reportes y ejecución de calidad según los parámetros suministrados.
.PARAMETER Path
Rutas de entrada bajo ROOT.
.PARAMETER Recurse
Incluye subdirectorios.
.PARAMETER Include
Patrones de inclusión.
.PARAMETER Exclude
Patrones de exclusión.
.PARAMETER Parallel
Habilita procesamiento paralelo.
.PARAMETER ThrottleLimit
Máximo de concurrencia.
.PARAMETER HashAlgorithm
Algoritmo de hash.
.PARAMETER RebuildCache
Reinicia la caché.
.PARAMETER ValidateOnly
Ejecuta únicamente QA.
.PARAMETER OutputPath
Carpeta de salida bajo ROOT.
.PARAMETER Format
Formatos de exportación.
.PARAMETER LogLevel
Nivel de logging.
.EXAMPLE
Invoke-AnalyzerMain -Path 'data' -Recurse -Parallel
#>
function Invoke-AnalyzerMain {
    [CmdletBinding()]
    param(
        [string[]]$Path,
        [switch]$Recurse,
        [string[]]$Include,
        [string[]]$Exclude,
        [switch]$Parallel,
        [ValidateRange(1,128)][int]$ThrottleLimit,
        [ValidateSet('SHA256','SHA1','MD5')][string]$HashAlgorithm,
        [switch]$RebuildCache,
        [switch]$ValidateOnly,
        [ValidateSet('csv','json','md','all')][string]$Format,
        [ValidateSet('Verbose','Information','Warning','Error')][string]$LogLevel,
        [string]$OutputPath
    )

    try {
        if ($PSBoundParameters.ContainsKey('LogLevel')) { $script:LogLevel = $LogLevel }
        if ($ValidateOnly) {
            Initialize-Logging -OutputPath (Resolve-UnderRoot -Root $script:Root -TargetPath $OutputPath)
            $qc = Invoke-QualityChecks -ScriptRoot $PSScriptRoot -OutputPath $OutputPath
            if ($script:PssaFailed) {
                Set-ExitCode -Code 3 -Reason 'Errores de PSScriptAnalyzer'
            }
            elseif ($script:PesterFailed) {
                Set-ExitCode -Code 2 -Reason 'Fallos de Pester'
            }
            else {
                Set-ExitCode -Code 0 -Reason 'Validaciones exitosas'
            }
            return $script:ExitCode
        }

        if (-not $Path -or $Path.Count -eq 0) {
            Write-StructuredLog -Level 'Information' -Message 'Sin rutas de entrada. Nada que procesar.'
            Set-ExitCode -Code 0 -Reason 'Sin datos'
            return $script:ExitCode
        }

        $progressId = Get-Random
        $progressCallback = {
            param($progress)
            $percent = if ($progress.Total -gt 0) { [Math]::Min(100, [Math]::Round(($progress.Processed / $progress.Total) * 100,2)) } else { 0 }
            $status = "Procesados: {0}/{1} | Cache: {2}" -f $progress.Processed, $progress.Total, $progress.CacheHits
            if ($Host.Name -eq 'ConsoleHost' -and -not [System.Console]::IsOutputRedirected) {
                Write-Progress -Id $progressId -Activity 'Analizando archivos' -Status $status -PercentComplete $percent
            }
            else {
                Write-Information -MessageData $status -InformationAction Continue
            }
        }

        $result = Invoke-ProcessingCore -InPath $Path -Recurse:$Recurse -Include $Include -Exclude $Exclude -Parallel:$Parallel -ThrottleLimit $ThrottleLimit -OutputPath $OutputPath -Format $Format -HashAlgorithm $HashAlgorithm -RebuildCache:$RebuildCache -Headless -ProgressCallback $progressCallback
        if ($Host.Name -eq 'ConsoleHost' -and -not [System.Console]::IsOutputRedirected) {
            Write-Progress -Id $progressId -Activity 'Analizando archivos' -Completed
        }

        if ($script:PssaFailed) {
            Set-ExitCode -Code 3 -Reason 'Errores de PSScriptAnalyzer'
        }
        elseif ($script:PesterFailed) {
            Set-ExitCode -Code 2 -Reason 'Fallos de Pester'
        }
        else {
            Set-ExitCode -Code 0 -Reason 'Procesamiento completado'
        }
        return $result
    }
    catch [System.Management.Automation.ParameterBindingException] {
        Write-StructuredLog -Level 'Error' -Message $_.Exception.Message
        Set-ExitCode -Code 5 -Reason 'Error de parámetros'
        return $script:ExitCode
    }
    catch {
        Write-StructuredLog -Level 'Error' -Message $_.Exception.Message
        Set-ExitCode -Code 4 -Reason 'Excepción no controlada'
        return $script:ExitCode
    }
}
#endregion AnalyzerCli
#region WizardUI
<#!
.SYNOPSIS
Inicia la interfaz WPF del asistente de workspaces.
.DESCRIPTION
Provee una UI con pestañas para configuración, validación de árboles, análisis, QA y revisión de logs, operando sobre el ROOT seguro.
.EXAMPLE
Start-WorkspaceWizard
#>
function Start-WorkspaceWizard {
    [CmdletBinding()]
    param()

    if (-not $script:IsWindowsPlatform) {
        Write-StructuredLog -Level 'Warning' -Message 'WPF no soportado en este sistema. Ejecuta en modo CLI.'
        return
    }

    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase | Out-Null
    Add-Type -AssemblyName System.Windows.Forms | Out-Null

    $xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Synapta Workspace Wizard" Height="720" Width="1000" WindowStartupLocation="CenterScreen">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>
        <TextBlock Text="Synapta Workspace Wizard" FontSize="20" Margin="12" />
        <TabControl x:Name="MainTabs" Grid.Row="1" Margin="12">
            <TabItem Header="Setup">
                <Grid Margin="12" >
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="*" />
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                        <ColumnDefinition Width="Auto" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Text="Root:" VerticalAlignment="Center" Margin="0,0,8,0" />
                    <TextBox x:Name="TxtRoot" Grid.Column="1" Width="400" />
                    <Button x:Name="BtnBrowseRoot" Grid.Column="2" Content="Buscar" Margin="8,0,0,0" Width="80" />

                    <TextBlock Grid.Row="1" Text="Proyecto:" VerticalAlignment="Center" Margin="0,12,8,0" />
                    <TextBox x:Name="TxtProject" Grid.Row="1" Grid.Column="1" Margin="0,12,0,0" />
                    <Button x:Name="BtnBrowseProject" Grid.Row="1" Grid.Column="2" Content="Buscar" Margin="8,12,0,0" Width="80" />

                    <TextBlock Grid.Row="2" Text="Output:" VerticalAlignment="Center" Margin="0,12,8,0" />
                    <TextBox x:Name="TxtOutput" Grid.Row="2" Grid.Column="1" Margin="0,12,0,0" />
                    <Button x:Name="BtnBrowseOutput" Grid.Row="2" Grid.Column="2" Content="Buscar" Margin="8,12,0,0" Width="80" />

                    <StackPanel Grid.Row="3" Grid.ColumnSpan="3" Orientation="Horizontal" Margin="0,16,0,0" HorizontalAlignment="Left">
                        <Button x:Name="BtnInstall" Content="Instalar Plantillas" Width="160" Margin="0,0,12,0" />
                        <Button x:Name="BtnInstallOverwrite" Content="Instalar (overwrite)" Width="180" Margin="0,0,12,0" />
                        <Button x:Name="BtnInitializeGlobal" Content="Inicializar Global" Width="160" />
                    </StackPanel>

                    <TextBlock x:Name="TxtSetupStatus" Grid.Row="4" Grid.ColumnSpan="3" TextWrapping="Wrap" Margin="0,16,0,0" />
                </Grid>
            </TabItem>
            <TabItem Header="Tree Validation">
                <Grid Margin="12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="*" />
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                        <ColumnDefinition Width="Auto" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Text="Filemap JSON:" VerticalAlignment="Center" />
                    <TextBox x:Name="TxtTreeFile" Grid.Column="1" Width="400" Margin="8,0,0,0" />
                    <Button x:Name="BtnBrowseTree" Grid.Column="2" Content="Buscar" Width="80" Margin="8,0,0,0" />

                    <StackPanel Grid.Row="1" Grid.ColumnSpan="3" Orientation="Horizontal" Margin="0,12,0,0" >
                        <TextBlock Text="MaxDepth:" VerticalAlignment="Center" />
                        <TextBox x:Name="TxtMaxDepth" Width="60" Margin="4,0,12,0" Text="32" />
                        <TextBlock Text="MaxNodes:" VerticalAlignment="Center" />
                        <TextBox x:Name="TxtMaxNodes" Width="80" Margin="4,0,12,0" Text="2000" />
                        <TextBlock Text="MaxPath:" VerticalAlignment="Center" />
                        <TextBox x:Name="TxtMaxPath" Width="80" Margin="4,0,12,0" Text="240" />
                        <Button x:Name="BtnValidateTree" Content="Validar" Width="120" />
                    </StackPanel>

                    <TextBox x:Name="TxtTreeResults" Grid.Row="3" Grid.ColumnSpan="3" Margin="0,12,0,0" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" />
                </Grid>
            </TabItem>
            <TabItem Header="Analyze">
                <Grid Margin="12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="*" />
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                        <ColumnDefinition Width="Auto" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Text="Path:" VerticalAlignment="Center" />
                    <TextBox x:Name="TxtAnalyzePath" Grid.Column="1" Margin="8,0,0,0" />
                    <Button x:Name="BtnBrowseAnalyze" Grid.Column="2" Content="Buscar" Width="80" Margin="8,0,0,0" />

                    <TextBlock Grid.Row="1" Text="Include:" VerticalAlignment="Center" />
                    <TextBox x:Name="TxtInclude" Grid.Row="1" Grid.Column="1" Margin="8,0,0,0" />

                    <TextBlock Grid.Row="2" Text="Exclude:" VerticalAlignment="Center" />
                    <TextBox x:Name="TxtExclude" Grid.Row="2" Grid.Column="1" Margin="8,0,0,0" />

                    <StackPanel Grid.Row="3" Grid.ColumnSpan="3" Orientation="Horizontal" Margin="0,12,0,0">
                        <CheckBox x:Name="ChkRecurse" Content="Recurse" Margin="0,0,12,0" />
                        <CheckBox x:Name="ChkParallel" Content="Parallel" Margin="0,0,12,0" />
                        <CheckBox x:Name="ChkRebuildCache" Content="Rebuild Cache" />
                    </StackPanel>

                    <StackPanel Grid.Row="4" Grid.ColumnSpan="3" Orientation="Horizontal" Margin="0,12,0,0">
                        <TextBlock Text="Throttle:" VerticalAlignment="Center" />
                        <Slider x:Name="SldThrottle" Minimum="1" Maximum="128" Width="200" Value="8" Margin="8,0,12,0" />
                        <TextBlock x:Name="TxtThrottleValue" Text="8" VerticalAlignment="Center" />
                        <TextBlock Text="Hash:" Margin="24,0,4,0" VerticalAlignment="Center" />
                        <ComboBox x:Name="CmbHash" Width="120">
                            <ComboBoxItem Content="SHA256" IsSelected="True" />
                            <ComboBoxItem Content="SHA1" />
                            <ComboBoxItem Content="MD5" />
                        </ComboBox>
                    </StackPanel>

                    <StackPanel Grid.Row="5" Grid.ColumnSpan="3" Orientation="Horizontal" Margin="0,12,0,0">
                        <Button x:Name="BtnAnalyzeStart" Content="Start" Width="100" Margin="0,0,12,0" />
                        <Button x:Name="BtnAnalyzeCancel" Content="Cancel" Width="100" />
                        <TextBlock x:Name="TxtAnalyzeStatus" Margin="16,0,0,0" VerticalAlignment="Center" />
                    </StackPanel>

                    <StackPanel Grid.Row="6" Grid.ColumnSpan="3" Margin="0,12,0,0">
                        <ProgressBar x:Name="PbAnalyze" Height="18" Minimum="0" Maximum="100" />
                        <TextBlock x:Name="TxtAnalyzeCounters" Margin="0,8,0,0" />
                        <DataGrid x:Name="DgResults" Margin="0,8,0,0" AutoGenerateColumns="True" Height="250" />
                    </StackPanel>
                </Grid>
            </TabItem>
            <TabItem Header="QA">
                <StackPanel Margin="12">
                    <Button x:Name="BtnRunQA" Content="Ejecutar QA" Width="140" />
                    <TextBlock x:Name="TxtQAStatus" Margin="0,12,0,0" TextWrapping="Wrap" />
                </StackPanel>
            </TabItem>
            <TabItem Header="Logs/Reports">
                <Grid Margin="12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="*" />
                        <RowDefinition Height="*" />
                        <RowDefinition Height="Auto" />
                    </Grid.RowDefinitions>
                    <StackPanel Orientation="Horizontal" Grid.Row="0">
                        <Button x:Name="BtnRefreshLogs" Content="Refrescar" Width="100" Margin="0,0,12,0" />
                        <Button x:Name="BtnOpenOutput" Content="Abrir carpeta" Width="120" />
                    </StackPanel>
                    <TextBox x:Name="TxtLogContent" Grid.Row="1" Margin="0,12,0,0" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" />
                    <TextBox x:Name="TxtJsonlContent" Grid.Row="2" Margin="0,12,0,0" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" />
                    <TextBlock Grid.Row="3" Text="Los reportes se generan en OutputPath." Margin="0,12,0,0" />
                </Grid>
            </TabItem>
        </TabControl>
        <StatusBar Grid.Row="2">
            <StatusBarItem>
                <TextBlock x:Name="TxtStatusBar" Text="Listo" />
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
'@

    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)

    $TxtRoot = $window.FindName('TxtRoot')
    $TxtProject = $window.FindName('TxtProject')
    $TxtOutput = $window.FindName('TxtOutput')
    $BtnBrowseRoot = $window.FindName('BtnBrowseRoot')
    $BtnBrowseProject = $window.FindName('BtnBrowseProject')
    $BtnBrowseOutput = $window.FindName('BtnBrowseOutput')
    $BtnInstall = $window.FindName('BtnInstall')
    $BtnInstallOverwrite = $window.FindName('BtnInstallOverwrite')
    $BtnInitializeGlobal = $window.FindName('BtnInitializeGlobal')
    $TxtSetupStatus = $window.FindName('TxtSetupStatus')
    $TxtStatusBar = $window.FindName('TxtStatusBar')
    $TxtTreeFile = $window.FindName('TxtTreeFile')
    $BtnBrowseTree = $window.FindName('BtnBrowseTree')
    $TxtMaxDepth = $window.FindName('TxtMaxDepth')
    $TxtMaxNodes = $window.FindName('TxtMaxNodes')
    $TxtMaxPath = $window.FindName('TxtMaxPath')
    $BtnValidateTree = $window.FindName('BtnValidateTree')
    $TxtTreeResults = $window.FindName('TxtTreeResults')
    $TxtAnalyzePath = $window.FindName('TxtAnalyzePath')
    $BtnBrowseAnalyze = $window.FindName('BtnBrowseAnalyze')
    $TxtInclude = $window.FindName('TxtInclude')
    $TxtExclude = $window.FindName('TxtExclude')
    $ChkRecurse = $window.FindName('ChkRecurse')
    $ChkParallel = $window.FindName('ChkParallel')
    $ChkRebuildCache = $window.FindName('ChkRebuildCache')
    $SldThrottle = $window.FindName('SldThrottle')
    $TxtThrottleValue = $window.FindName('TxtThrottleValue')
    $CmbHash = $window.FindName('CmbHash')
    $BtnAnalyzeStart = $window.FindName('BtnAnalyzeStart')
    $BtnAnalyzeCancel = $window.FindName('BtnAnalyzeCancel')
    $PbAnalyze = $window.FindName('PbAnalyze')
    $TxtAnalyzeStatus = $window.FindName('TxtAnalyzeStatus')
    $TxtAnalyzeCounters = $window.FindName('TxtAnalyzeCounters')
    $DgResults = $window.FindName('DgResults')
    $BtnRunQA = $window.FindName('BtnRunQA')
    $TxtQAStatus = $window.FindName('TxtQAStatus')
    $BtnRefreshLogs = $window.FindName('BtnRefreshLogs')
    $BtnOpenOutput = $window.FindName('BtnOpenOutput')
    $TxtLogContent = $window.FindName('TxtLogContent')
    $TxtJsonlContent = $window.FindName('TxtJsonlContent')

    $TxtRoot.Text = $script:Root
    $TxtOutput.Text = (Join-Path -Path $script:Root -ChildPath 'out')

    $selectFolder = {
        param($textbox)
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.SelectedPath = $textbox.Text
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $textbox.Text = $dialog.SelectedPath
        }
    }

    $BtnBrowseRoot.Add_Click({ & $selectFolder.Invoke($TxtRoot) })
    $BtnBrowseProject.Add_Click({ & $selectFolder.Invoke($TxtProject) })
    $BtnBrowseOutput.Add_Click({ & $selectFolder.Invoke($TxtOutput) })
    $BtnBrowseAnalyze.Add_Click({ & $selectFolder.Invoke($TxtAnalyzePath) })

    $BtnBrowseTree.Add_Click({
        $dialog = New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Filter = 'JSON (*.json)|*.json|Todos (*.*)|*.*'
        if ($dialog.ShowDialog()) {
            $TxtTreeFile.Text = $dialog.FileName
        }
    })

    $SldThrottle.Add_ValueChanged({ param($s,$e) $TxtThrottleValue.Text = [Math]::Round($SldThrottle.Value) })

    $updateStatus = {
        param($message)
        $window.Dispatcher.Invoke([action]{
            $TxtStatusBar.Text = $message
        })
    }

    $BtnInitializeGlobal.Add_Click({
        try {
            $templates = Initialize-GlobalTemplates -Root $TxtRoot.Text
            $TxtSetupStatus.Text = "Plantillas globales en: $($templates.FileMap)"
            & $updateStatus.Invoke('Plantillas globales listas')
        }
        catch {
            $TxtSetupStatus.Text = $_.Exception.Message
            & $updateStatus.Invoke('Error en plantillas globales')
        }
    })

    $installAction = {
        param($overwrite)
        try {
            $templates = Initialize-GlobalTemplates -Root $TxtRoot.Text
            $result = Install-Workspace -ProjectPath $TxtProject.Text -Root $TxtRoot.Text -GlobalTemplates $templates -Overwrite:$overwrite
            $TxtSetupStatus.Text = "Workspace instalado en $($result.WorkspaceDir)"
            & $updateStatus.Invoke('Workspace instalado')
        }
        catch {
            $TxtSetupStatus.Text = $_.Exception.Message
            & $updateStatus.Invoke('Error instalando workspace')
        }
    }

    $BtnInstall.Add_Click({ & $installAction.Invoke($false) })
    $BtnInstallOverwrite.Add_Click({ & $installAction.Invoke($true) })

    $BtnValidateTree.Add_Click({
        try {
            $mapContent = Get-Content -LiteralPath $TxtTreeFile.Text -Raw | ConvertFrom-Json -Depth 10
            $summary = Test-TreePlan -Base $mapContent.root -Map $mapContent.tree -MaxDepth ([int]$TxtMaxDepth.Text) -MaxNodes ([int]$TxtMaxNodes.Text) -MaxPath ([int]$TxtMaxPath.Text)
            $TxtTreeResults.Text = ($summary.Errors -join [Environment]::NewLine)
            if ($summary.IsValid) {
                & $updateStatus.Invoke('Tree válido')
            }
            else {
                & $updateStatus.Invoke("Errores: $($summary.ErrorsCount)")
            }
        }
        catch {
            $TxtTreeResults.Text = $_.Exception.Message
            & $updateStatus.Invoke('Error validando tree')
        }
    })

    $analysisTask = $null
    $BtnAnalyzeStart.Add_Click({
        if ($analysisTask -and -not $analysisTask.IsCompleted) { return }
        $BtnAnalyzeStart.IsEnabled = $false
        $BtnAnalyzeCancel.IsEnabled = $true
        $PbAnalyze.Value = 0
        $TxtAnalyzeStatus.Text = 'Procesando...'
        $TxtAnalyzeCounters.Text = ''
        $TxtStatusBar.Text = 'Analizando'
        $hash = ($CmbHash.SelectedItem.Content)
        $paths = $TxtAnalyzePath.Text -split ';' | Where-Object { $_ }
        $include = if ([string]::IsNullOrWhiteSpace($TxtInclude.Text)) { $null } else { $TxtInclude.Text -split ',' }
        $exclude = if ([string]::IsNullOrWhiteSpace($TxtExclude.Text)) { $null } else { $TxtExclude.Text -split ',' }
        $parallel = $ChkParallel.IsChecked
        $recurse = $ChkRecurse.IsChecked
        $rebuild = $ChkRebuildCache.IsChecked
        $throttle = [int][Math]::Round($SldThrottle.Value)
        $output = $TxtOutput.Text

        $progressCallback = {
            param($progress)
            $window.Dispatcher.Invoke([action]{
                if ($progress.Total -gt 0) {
                    $PbAnalyze.Maximum = $progress.Total
                    $PbAnalyze.Value = [Math]::Min($progress.Processed, $progress.Total)
                }
                $TxtAnalyzeCounters.Text = "Procesados: {0}/{1} | Cache: {2}" -f $progress.Processed, $progress.Total, $progress.CacheHits
            })
        }

        $analysisTask = [System.Threading.Tasks.Task]::Run({
            try {
                $result = Invoke-ProcessingCore -InPath $paths -Recurse:$recurse -Include $include -Exclude $exclude -Parallel:$parallel -ThrottleLimit $throttle -OutputPath $output -Format 'all' -HashAlgorithm $hash -RebuildCache:$rebuild -Headless -ProgressCallback $progressCallback
                $window.Dispatcher.Invoke([action]{
                    $DgResults.ItemsSource = $result.Results
                    $TxtAnalyzeStatus.Text = 'Completado'
                    $TxtStatusBar.Text = 'Análisis completo'
                    $PbAnalyze.Value = $PbAnalyze.Maximum
                })
            }
            catch {
                $window.Dispatcher.Invoke([action]{
                    $TxtAnalyzeStatus.Text = $_.Exception.Message
                    $TxtStatusBar.Text = 'Error en análisis'
                })
            }
            finally {
                $window.Dispatcher.Invoke([action]{
                    $BtnAnalyzeStart.IsEnabled = $true
                    $BtnAnalyzeCancel.IsEnabled = $false
                })
            }
        })
    })

    $BtnAnalyzeCancel.Add_Click({
        if ($script:CancellationSource) {
            $script:CancellationSource.Cancel()
            $TxtAnalyzeStatus.Text = 'Cancelado'
            $TxtStatusBar.Text = 'Operación cancelada'
        }
    })

    $BtnRunQA.Add_Click({
        try {
            $TxtQAStatus.Text = 'Ejecutando QA...'
            $qa = Invoke-QualityChecks -ScriptRoot $PSScriptRoot -OutputPath $TxtOutput.Text
            $TxtQAStatus.Text = "QA finalizado. Fallback: $($qa.Fallback)"
            $TxtStatusBar.Text = 'QA completo'
        }
        catch {
            $TxtQAStatus.Text = $_.Exception.Message
            $TxtStatusBar.Text = 'Error en QA'
        }
    })

    $refreshLogs = {
        try {
            $logPath = Join-Path -Path $TxtOutput.Text -ChildPath 'run.log'
            $jsonlPath = Join-Path -Path $TxtOutput.Text -ChildPath 'run.jsonl'
            if (Test-Path -LiteralPath $logPath) { $TxtLogContent.Text = Get-Content -LiteralPath $logPath -Raw } else { $TxtLogContent.Text = '' }
            if (Test-Path -LiteralPath $jsonlPath) { $TxtJsonlContent.Text = Get-Content -LiteralPath $jsonlPath -Raw } else { $TxtJsonlContent.Text = '' }
        }
        catch {
            $TxtLogContent.Text = $_.Exception.Message
        }
    }

    $BtnRefreshLogs.Add_Click({ & $refreshLogs.Invoke() })
    $BtnOpenOutput.Add_Click({
        if (Test-Path -LiteralPath $TxtOutput.Text) {
            Start-Process -FilePath 'explorer.exe' -ArgumentList $TxtOutput.Text
        }
    })

    $window.ShowDialog() | Out-Null
}
#endregion WizardUI
#region QA Tests
$script:BaselinePssa = @'
@{ 
    Severity      = @(''Error'',''Warning'')
    IncludeRules  = @(
        ''PSUseApprovedVerbs'',
        ''PSUseConsistentIndentation'',
        ''PSAvoidUsingWriteHost'',
        ''PSAvoidUsingEmptyCatchBlock'',
        ''PSPossibleIncorrectComparisonWithNull'',
        ''PSUseDeclaredVarsMoreThanAssignments'',
        ''PSReviewUnusedParameter''
    )
    ExcludeRules  = @()
    Rules         = @{
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = ''IncreaseIndentationForFirstPipeline''
        }
    }
}
'@

$script:BaselinePester = @'
Describe ''Workspace Wizard Smoke Tests'' {
    Context ''Core functions'' {
        It ''Exports required public functions'' {
            $functions = ''Test-TreePlan'',''Initialize-GlobalTemplates'',''Install-Workspace'',''Resolve-UnderRoot'',''Invoke-ProcessingCore'',''Invoke-QualityChecks'',''Invoke-AnalyzerMain'',''Start-WorkspaceWizard''
            foreach ($fn in $functions) {
                (Get-Command -Name $fn -ErrorAction Stop).Name | Should -Be $fn
            }
        }
    }
}
'@
#endregion QA Tests
#region EntryPoint
if ($Wizard) {
    Start-WorkspaceWizard
}
else {
    $result = Invoke-AnalyzerMain -Path $Path -Recurse:$Recurse -Include $Include -Exclude $Exclude -Parallel:$Parallel -ThrottleLimit $ThrottleLimit -HashAlgorithm $HashAlgorithm -RebuildCache:$RebuildCache -ValidateOnly:$ValidateOnly -Format $Format -LogLevel $LogLevel -OutputPath $OutputPath
    if ($NoExit) { return $result }
    exit $script:ExitCode
}
#endregion EntryPoint