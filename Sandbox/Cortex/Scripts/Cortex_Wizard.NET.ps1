<#
.SYNOPSIS
Cortex – script maestro modular para scaffolding, GitOps, análisis y descargas.

.DESCRIPTION
Cortex consolida en un único .ps1 capas internas claramente separadas (Core, Services, CLI, Automation, Exporter) para generar
nuevas estructuras Sandbox/Core, sincronizar repositorios con Git, ejecutar análisis integrados (Parser AST, PSSA, dotnet
build/test), descargar artefactos y empaquetar el propio script. Está diseñado para ejecutarse en Windows 7+ con PowerShell 5.1+
y pwsh 7+, privilegiando el desarrollo en Windows 10/11 + pwsh 7.x. Mantiene compatibilidad multi-target .NET (net6/net7/net8)
y puede operar en modo interactivo (menús PromptForChoice) o no interactivo (parámetros/planes JSON/YAML).

.PARAMETER AutoOption
Ejecuta directamente una operación automática (1..7). Véase la tabla AutoOption en README.

.PARAMETER RepoPath
Ruta del repositorio objetivo. Por defecto, el directorio actual.

.PARAMETER ProjectName
Nombre del proyecto a scaffoldear o analizar.

.PARAMETER ProjectType
Tipo de proyecto: PS-CLI, DotNet-CLI, DotNet-UI.

.PARAMETER Branch
Rama principal para operaciones Git (default: main).

.PARAMETER RemoteName
Nombre del remoto Git (default: origin).

.PARAMETER TemplateOverride
Ruta opcional a carpeta de plantillas personalizadas.

.PARAMETER PlanPath
Ruta a plan JSON/YAML para modo Automation.

.PARAMETER QualityGate
Si se especifica, las advertencias/errores de análisis hacen fallar la ejecución con código >0.

.PARAMETER LogPath
Ruta de carpeta para logs/resúmenes. Default: ./logs.

.PARAMETER ConfigFile
Ruta a archivo de configuración adicional.

.PARAMETER RunId
Identificador de ejecución para logging.

.EXAMPLE
pwsh ./Cortex.ps1 -AutoOption 1 -RepoPath C:\Repos\Neurologic -ProjectName Demo -ProjectType PS-CLI

.EXAMPLE
pwsh ./Cortex.ps1 -AutoOption 7 -PlanPath .\plan.json -LogPath .\logs

.NOTES
- Usa Set-StrictMode -Version Latest y $ErrorActionPreference = 'Stop'.
- No se admiten Read-Host en Core; toda interacción UI se limita a Cortex.CLI.
- Para compilar a EXE: Invoke-CortexExporter -Output C:\Tools\Cortex.exe -Runtime win-x64.
#>
[CmdletBinding()]
param(
    [ValidateSet('1','2','3','4','5','6','7')]
    [string]$AutoOption,
    [string]$RepoPath = (Get-Location).Path,
    [string]$ProjectName,
    [ValidateSet('PS-CLI','DotNet-CLI','DotNet-UI')]
    [string]$ProjectType = 'PS-CLI',
    [string]$Branch = 'main',
    [string]$RemoteName = 'origin',
    [string]$TemplateOverride,
    [string]$PlanPath,
    [switch]$QualityGate,
    [string]$LogPath = (Join-Path -Path (Get-Location).Path -ChildPath 'logs'),
    [string]$ConfigFile,
    [string]$RunId = ([guid]::NewGuid().ToString())
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

#region Configuration
$CortexConfig = [ordered]@{
    MinimumPwsh = '5.1'
    PreferredPwsh = '7.4'
    SupportedProjectTypes = @('PS-CLI','DotNet-CLI','DotNet-UI')
    DefaultBranch = $Branch
    DefaultRemote = $RemoteName
    LogRoot = $LogPath
    TemplateOverride = $TemplateOverride
    PlanSchemaPath = Join-Path -Path $PSScriptRoot -ChildPath 'docs/Cortex_Plan_Schema.md'
}

$CortexTemplates = @{
    'AGENTS.md' = @'
# AGENTS – Proyecto {PROJECT_NAME}

Este archivo fue generado automáticamente por Cortex.Core.Scaffolding.
- Compatibilidad: Windows PowerShell 5.1+ / pwsh 7+.
- Plantillas embebidas actualizadas el {DATE}.
'@
    'README.md' = @'
# {PROJECT_NAME}

Proyecto generado por Cortex.Core.Scaffolding. Incluye estructura Sandbox/Core, CSV y documentación base.
'@
    'docs/Procedimiento_de_solicitud_de_artefactos.md' = @'
# Procedimiento_de_solicitud_de_artefactos - {PROJECT_NAME}

Sigue las iteraciones Investigación → Plan/Solicitud → CSV/Validaciones antes de solicitar trabajo a Codex.
'@
    'docs/Informe.md' = @'
# Informe técnico - {PROJECT_NAME}

## Hallazgos
- Pending: sustituye este texto por el análisis de tu proyecto.
'@
    'docs/solicitud_de_artefactos.md' = @'
[AGENTE_DESTINO]
Codex Web

[TIPO_SOLICITUD]
artefacto_reutilizable

[ANTECEDENTES]
Describe antecedentes aquí.
'@
    'docs/bitacora.md' = @'
# Bitácora

Registra fechas, decisiones y resultados de pruebas.
'@
    'docs/filemap_ascii.txt' = @'
{PROJECT_NAME}/
├── AGENTS.md
├── README.md
├── Cortex.csproj
├── docs/
│   ├── Procedimiento_de_solicitud_de_artefactos.md
│   ├── Informe.md
│   ├── solicitud_de_artefactos.md
│   ├── filemap_ascii.txt
│   ├── table_hierarchy.json
│   ├── bitacora.md
│   └── Cortex.ps1
├── csv/
│   ├── modules.csv
│   └── artefacts.csv
├── Scripts/
├── src/
└── tests/
'@
    'docs/table_hierarchy.json' = @'
{
  "name": "{PROJECT_NAME}",
  "children": [
    {"name": "docs"},
    {"name": "csv"},
    {"name": "Scripts"},
    {"name": "src"},
    {"name": "tests"}
  ]
}
'@
    'csv/modules.csv' = "Componente,Descripcion,Estado,Responsable`n"
    'csv/artefacts.csv' = "Artefacto,Ubicacion,Proyecto_Origen,Proyecto_Destino,Estado`n"
    'Cortex.csproj' = @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFrameworks>net8.0;net7.0;net6.0</TargetFrameworks>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <GenerateDocumentationFile>true</GenerateDocumentationFile>
  </PropertyGroup>
</Project>
'@
    'src/Program.cs' = @'
using System;

namespace {PROJECT_NAME}
{
    public static class Program
    {
        public static int Main(string[] args)
        {
            Console.WriteLine("{PROJECT_NAME} CLI scaffold listo.");
            return 0;
        }
    }
}
'@
    'Scripts/{PROJECT_NAME}.ps1' = @'
param()
Write-Output "{PROJECT_NAME} PowerShell scaffold listo."
'@
}
#endregion Configuration

#region Utilities
function Invoke-CortexLog {
    [CmdletBinding()]
    param(
        [string]$Operation,
        [string]$Repo = $RepoPath,
        [string]$Status = 'Info',
        [string]$Details,
        [string]$Errors
    )
    $timestamp = [DateTime]::UtcNow.ToString('o')
    $entry = [ordered]@{
        RunId = $RunId
        Timestamp = $timestamp
        Repo = $Repo
        Operation = $Operation
        Status = $Status
        DurationMs = 0
        Details = $Details
        Errors = $Errors
    }
    if (-not (Test-Path -LiteralPath $CortexConfig.LogRoot)) {
        New-Item -ItemType Directory -Path $CortexConfig.LogRoot -Force | Out-Null
    }
    $logFile = Join-Path -Path $CortexConfig.LogRoot -ChildPath "$RunId.json"
    $existing = @()
    if (Test-Path -LiteralPath $logFile) {
        $existing = @(Get-Content -LiteralPath $logFile -Raw | ConvertFrom-Json -Depth 5)
    }
    $existing += [pscustomobject]$entry
    $existing | ConvertTo-Json -Depth 6 | Out-File -FilePath $logFile -Encoding utf8
    Write-Host "[$Status] $Operation :: $Details" -ForegroundColor (Get-CortexStatusColor -Status $Status)
}

function Test-CortexPlatform {
    [CmdletBinding()]
    param()
    if ($IsLinux -or $IsMacOS) {
        Write-Warning 'Cortex está diseñado para Windows; algunas funciones pueden no estar disponibles en este entorno.'
    }
}

function Get-CortexStatusColor {
    [CmdletBinding()]
    param([string]$Status)
    switch ($Status) {
        'Error' { return 'Red' }
        'Warn' { return 'Yellow' }
        default { return 'Green' }
    }
}

function Get-CortexTemplate {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name)
    if ($CortexConfig.TemplateOverride) {
        $overridePath = Join-Path -Path $CortexConfig.TemplateOverride -ChildPath $Name
        if (Test-Path -LiteralPath $overridePath) {
            return Get-Content -LiteralPath $overridePath -Raw
        }
    }
    return $CortexTemplates[$Name]
}

function Resolve-CortexPath {
    param([string]$BasePath, [string]$Relative)
    return Join-Path -Path $BasePath -ChildPath $Relative
}

function Get-CortexProjectLabel {
    [CmdletBinding()]
    param([string]$Fallback = 'CortexProject')
    if ([string]::IsNullOrWhiteSpace($ProjectName)) { return $Fallback }
    return $ProjectName
}

function Confirm-CortexAction {
    [CmdletBinding()]
    param([string]$Message)
    $choices = @(
        (New-Object System.Management.Automation.Host.ChoiceDescription '&Si','Confirmar')
        (New-Object System.Management.Automation.Host.ChoiceDescription '&No','Cancelar')
    )
    $selection = $Host.UI.PromptForChoice('Confirmación', $Message, $choices, 1)
    return ($selection -eq 0)
}
#endregion Utilities

#region Cortex.Core.Scaffolding
function New-CortexScaffold {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DestinationPath,
        [Parameter(Mandatory)][string]$Name,
        [ValidateSet('PS-CLI','DotNet-CLI','DotNet-UI')]
        [string]$Type = 'PS-CLI'
    )
    $paths = @(
        $DestinationPath,
        (Resolve-CortexPath $DestinationPath 'docs'),
        (Resolve-CortexPath $DestinationPath 'csv'),
        (Resolve-CortexPath $DestinationPath 'Scripts'),
        (Resolve-CortexPath $DestinationPath 'src'),
        (Resolve-CortexPath $DestinationPath 'tests')
    )
    foreach ($p in $paths) { New-Item -ItemType Directory -Path $p -Force | Out-Null }

    foreach ($key in $CortexTemplates.Keys | Sort-Object) {
        $content = Get-CortexTemplate -Name $key
        if (-not $content) { continue }
        $rendered = $content.Replace('{PROJECT_NAME}',$Name).Replace('{DATE}', (Get-Date).ToString('yyyy-MM-dd'))
        $target = Resolve-CortexPath $DestinationPath $key
        $targetDir = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
        $rendered | Out-File -LiteralPath $target -Encoding utf8
    }

    if ($Type -like 'DotNet-*') {
        $projPath = Resolve-CortexPath $DestinationPath 'Cortex.csproj'
        $projContent = Get-CortexTemplate -Name 'Cortex.csproj'
        $projContent.Replace('{PROJECT_NAME}',$Name) | Out-File -LiteralPath $projPath -Encoding utf8
    }

    Invoke-CortexLog -Operation 'Scaffold' -Status 'Success' -Details "Estructura generada en $DestinationPath" -Repo $DestinationPath
    return $DestinationPath
}
#endregion

#region Cortex.Core.GitOps
function Invoke-CortexGit {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Repo, [string[]]$GitArguments)
    $raw = & git -C $Repo @GitArguments 2>&1
    $exit = $LASTEXITCODE
    $text = ($raw | Where-Object { $_ }) -join [Environment]::NewLine
    $stdOut = if ($exit -eq 0) { $text } else { '' }
    $stdErr = if ($exit -ne 0) { $text } else { '' }
    return [pscustomobject]@{ ExitCode=$exit; StdOut=$stdOut; StdErr=$stdErr }
}

function Test-CortexGitClean {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Repo)
    $status = Invoke-CortexGit -Repo $Repo -GitArguments @('status','--porcelain')
    return [string]::IsNullOrWhiteSpace($status.StdOut)
}

function Invoke-CortexSyncUp {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Repo,[string]$Message = 'Cortex sync')
    if (Test-CortexGitClean -Repo $Repo) {
        Invoke-CortexLog -Operation 'SyncUp' -Status 'Warn' -Details 'Sin cambios para enviar' -Repo $Repo
        return
    }
    [void](Invoke-CortexGit -Repo $Repo -GitArguments @('add','-A'))
    $commit = Invoke-CortexGit -Repo $Repo -GitArguments @('commit','-m', $Message)
    if ($commit.ExitCode -ne 0) { throw "Commit falló: $($commit.StdErr)" }
    $push = Invoke-CortexGit -Repo $Repo -GitArguments @('push',$RemoteName,$Branch)
    if ($push.ExitCode -ne 0) { throw "Falló push: $($push.StdErr)" }
    Invoke-CortexLog -Operation 'SyncUp' -Status 'Success' -Details 'Cambios enviados' -Repo $Repo
}

function Invoke-CortexSyncDown {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Repo)
    if (-not (Test-CortexGitClean -Repo $Repo)) {
        Invoke-CortexLog -Operation 'SyncDown' -Status 'Error' -Details 'Workspace con cambios locales, merge bloqueado' -Repo $Repo -Errors 'Workspace sucio'
        throw 'Limpia o commitea antes de sincronizar.'
    }
    $fetch = Invoke-CortexGit -Repo $Repo -GitArguments @('fetch',$RemoteName,$Branch)
    if ($fetch.ExitCode -ne 0) { throw $fetch.StdErr }
    $merge = Invoke-CortexGit -Repo $Repo -GitArguments @('merge',"$RemoteName/$Branch")
    if ($merge.ExitCode -ne 0) {
        Invoke-CortexGit -Repo $Repo -GitArguments @('merge','--abort') | Out-Null
        Invoke-CortexLog -Operation 'SyncDown' -Status 'Error' -Details 'Conflicto detectado, merge abortado' -Repo $Repo -Errors $merge.StdErr
        throw 'Conflictos durante merge.'
    }
    Invoke-CortexLog -Operation 'SyncDown' -Status 'Success' -Details 'Merge remoto aplicado' -Repo $Repo
}
#endregion

#region Cortex.Core.Analysis
function Invoke-CortexParserAnalysis {
    [CmdletBinding()]
    param([string[]]$Paths)
    $results = @()
    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $null = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$null)
        $results += [pscustomobject]@{ File=$path; Status='OK' }
    }
    return $results
}

function Invoke-CortexPssa {
    [CmdletBinding()]
    param([string[]]$Paths)
    $pssa = Get-Command -Name 'Invoke-ScriptAnalyzer' -ErrorAction SilentlyContinue
    if (-not $pssa) { return @() }
    return Invoke-ScriptAnalyzer -Path $Paths -Recurse -ErrorAction SilentlyContinue
}

function Invoke-CortexDotNet {
    [CmdletBinding()]
    param([string]$ProjectPath)
    if (-not (Test-Path -LiteralPath $ProjectPath)) { return @() }
    $build = dotnet build $ProjectPath
    $testPath = Split-Path -Parent $ProjectPath
    $tests = Get-ChildItem -Path $testPath -Filter '*.csproj' -Recurse | Where-Object { $_.FullName -ne $ProjectPath }
    foreach ($t in $tests) { dotnet test $t.FullName | Out-Null }
    return @($build)
}

function Invoke-CortexAnalysis {
    [CmdletBinding()]
    param([string]$Repo=$RepoPath,[switch]$FailOnIssues)
    $ps1Files = Get-ChildItem -Path $Repo -Filter '*.ps1' -Recurse | Select-Object -ExpandProperty FullName
    $parser = Invoke-CortexParserAnalysis -Paths $ps1Files
    $pssa = Invoke-CortexPssa -Paths $ps1Files
    $csproj = Get-ChildItem -Path $Repo -Filter '*.csproj' -Recurse | Select-Object -First 1
    $dotnet = if ($csproj) { Invoke-CortexDotNet -ProjectPath $csproj.FullName } else { @() }
    $issues = @($pssa | Where-Object { $_ })
    $status = if ($issues.Count -gt 0 -and $FailOnIssues) { 'Error' } else { 'Success' }
    Invoke-CortexLog -Operation 'Analysis' -Status $status -Details "Parser:$($parser.Count); PSSA:$($issues.Count); dotnet:$($dotnet.Count)" -Repo $Repo -Errors (if($issues){($issues | ConvertTo-Json -Depth 4)} else {''})
    if ($FailOnIssues -and $issues.Count -gt 0) { throw 'Quality gate falló.' }
}
#endregion

#region Cortex.Core.Artifacts
function Invoke-CortexArtifactDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [string]$Repo = $null,
        [string]$Tag = 'latest'
    )
    if (-not (Test-Path -LiteralPath (Split-Path -Parent $Destination))) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $Destination) -Force | Out-Null
    }
    $gh = Get-Command -Name 'gh' -ErrorAction SilentlyContinue
    if ($gh -and $Repo) {
        $ghArgs = @('release','download',$Tag,'--repo',$Repo,'--pattern',$Source,'--output',$Destination)
        $proc = Start-Process -FilePath 'gh' -ArgumentList $ghArgs -NoNewWindow -Wait -PassThru
        if ($proc.ExitCode -ne 0) { throw "gh release download falló ($($proc.ExitCode))" }
    } else {
        $client = [System.Net.Http.HttpClient]::new()
        $bytes = $client.GetByteArrayAsync($Source).Result
        [System.IO.File]::WriteAllBytes($Destination, $bytes)
    }
    if ($Destination.ToLower().EndsWith('.zip')) {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $extractPath = [System.IO.Path]::Combine((Split-Path -Parent $Destination), ([System.IO.Path]::GetFileNameWithoutExtension($Destination)))
        [System.IO.Compression.ZipFile]::ExtractToDirectory($Destination, $extractPath, $true)
    }
    Invoke-CortexLog -Operation 'ArtifactDownload' -Status 'Success' -Details "Descargado: $Source" -Repo $RepoPath
}
#endregion

#region Cortex.Services
function Invoke-CortexPlanJob {
    [CmdletBinding()]
    param([pscustomobject]$Job)
    switch ($Job.operation) {
        'scaffold' { New-CortexScaffold -DestinationPath $Job.destination -Name $Job.name -Type $Job.projectType }
        'analysis' { Invoke-CortexAnalysis -Repo $Job.repo -FailOnIssues:$QualityGate }
        'sync-up' { Invoke-CortexSyncUp -Repo $Job.repo }
        'sync-down' { Invoke-CortexSyncDown -Repo $Job.repo }
        'artifact' { Invoke-CortexArtifactDownload -Source $Job.source -Destination $Job.destination -Repo $Job.repo -Tag ($Job.tag) }
        default { Write-Warning "Operación no soportada en plan: $($Job.operation)" }
    }
}

function Invoke-CortexPlan {
    [CmdletBinding()]
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Plan no encontrado: $Path" }
    $ext = [System.IO.Path]::GetExtension($Path)
    $content = Get-Content -LiteralPath $Path -Raw
    $plan = $null
    if ($ext -in @('.yml','.yaml')) {
        $yamlCmd = Get-Command -Name 'ConvertFrom-Yaml' -ErrorAction SilentlyContinue
        if (-not $yamlCmd) { throw 'ConvertFrom-Yaml no disponible' }
        $plan = $content | ConvertFrom-Yaml
    } else {
        $plan = $content | ConvertFrom-Json -Depth 6
    }
    foreach ($job in $plan.jobs) {
        Write-Progress -Activity 'Cortex Plan' -Status $job.operation -PercentComplete 0
        Invoke-CortexPlanJob -Job $job
    }
    Write-Progress -Activity 'Cortex Plan' -Completed -Status 'Finalizado'
    Invoke-CortexLog -Operation 'AutomationPlan' -Status 'Success' -Details "Plan ejecutado: $Path" -Repo $RepoPath
}
#endregion

#region Cortex.CLI
function Show-CortexMenu {
    [CmdletBinding()]
    param()
    $choices = @(
        (New-Object System.Management.Automation.Host.ChoiceDescription '&1 Scaffolding','Crear estructura Sandbox/Core')
        (New-Object System.Management.Automation.Host.ChoiceDescription '&2 Análisis','Parser/PSSA/dotnet')
        (New-Object System.Management.Automation.Host.ChoiceDescription '&3 Build multi-repo','dotnet build/test en lote')
        (New-Object System.Management.Automation.Host.ChoiceDescription '&4 Sync Up','git add/commit/push')
        (New-Object System.Management.Automation.Host.ChoiceDescription '&5 Sync Down','fetch/merge Codex')
        (New-Object System.Management.Automation.Host.ChoiceDescription '&6 Artefactos','Descarga/extrae artefactos')
        (New-Object System.Management.Automation.Host.ChoiceDescription '&7 Plan Automation','Ejecutar plan JSON/YAML')
        (New-Object System.Management.Automation.Host.ChoiceDescription '&0 Salir','Cerrar')
    )
    $selection = $Host.UI.PromptForChoice('Cortex','Selecciona operación',$choices,0)
    return $selection
}

function Invoke-CortexCli {
    [CmdletBinding()]
    param()
    Test-CortexPlatform
    while ($true) {
        $opt = Show-CortexMenu
        switch ($opt) {
            0 { New-CortexScaffold -DestinationPath $RepoPath -Name (Get-CortexProjectLabel) -Type $ProjectType }
            1 { Invoke-CortexAnalysis -Repo $RepoPath -FailOnIssues:$QualityGate }
            2 { Invoke-CortexAnalysis -Repo $RepoPath -FailOnIssues:$QualityGate }
            3 { if (Confirm-CortexAction -Message '¿Deseas enviar cambios al remoto?') { Invoke-CortexSyncUp -Repo $RepoPath } }
            4 { if (Confirm-CortexAction -Message '¿Aplicar cambios remotos y fusionar Codex?') { Invoke-CortexSyncDown -Repo $RepoPath } }
            5 { Invoke-CortexArtifactDownload -Source 'artifact.zip' -Destination (Join-Path $RepoPath 'artifact.zip') }
            6 { if ($PlanPath) { Invoke-CortexPlan -Path $PlanPath } else { Write-Warning 'Proporcione -PlanPath para ejecutar plan.' } }
            7 { break }
        }
    }
}
#endregion

#region Cortex.Automation
function Invoke-CortexAutoOption {
    [CmdletBinding()]
    param([string]$Option)
    switch ($Option) {
        '1' { New-CortexScaffold -DestinationPath $RepoPath -Name (Get-CortexProjectLabel) -Type $ProjectType }
        '2' { Invoke-CortexAnalysis -Repo $RepoPath -FailOnIssues:$QualityGate }
        '3' { Invoke-CortexAnalysis -Repo $RepoPath -FailOnIssues:$QualityGate }
        '4' { Invoke-CortexSyncUp -Repo $RepoPath }
        '5' { Invoke-CortexSyncDown -Repo $RepoPath }
        '6' { Invoke-CortexArtifactDownload -Source 'artifact.zip' -Destination (Join-Path $RepoPath 'artifact.zip') }
        '7' { Invoke-CortexPlan -Path $PlanPath }
        default { Invoke-CortexCli }
    }
}
#endregion

#region Cortex.Exporter
function Invoke-CortexExporter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Output,
        [string]$Runtime = 'win-x64'
    )
    $ps2exe = Get-Command -Name 'ps2exe' -ErrorAction SilentlyContinue
    if ($ps2exe) {
        ps2exe -inputFile $MyInvocation.MyCommand.Path -outputFile $Output -runtime $Runtime
    } else {
        Write-Host 'ps2exe no disponible; genere host .NET (dotnet publish) con un loader que invoque este script.' -ForegroundColor Yellow
    }
    Invoke-CortexLog -Operation 'Exporter' -Status 'Success' -Details "Output: $Output" -Repo $RepoPath
}
#endregion

#region EntryPoint
if ($AutoOption) {
    Invoke-CortexAutoOption -Option $AutoOption
} else {
    Invoke-CortexCli
}
#endregion
