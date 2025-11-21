Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot
$root = Split-Path -Parent $here

. "$root/src/Cortex.Common.ps1"
. "$root/src/Cortex.Core.Scaffolding.ps1"
. "$root/src/Cortex.Core.GitOps.ps1"
. "$root/src/Cortex.Core.Analysis.ps1"
. "$root/src/Cortex.Core.Artifacts.ps1"
. "$root/src/Cortex.Automation.ps1"
. "$root/src/Cortex.CLI.ps1"
. "$root/src/Cortex.Exporter.ps1"

[CmdletBinding()]
param(
    [int]$AutoOption,
    [string]$RepoPath = (Get-Location).Path,
    [string]$ProjectName = 'SandboxProject',
    [ValidateSet('PS-CLI','DotNet-CLI','DotNet-UI')][string]$ProjectType = 'PS-CLI',
    [string]$Branch = 'main',
    [string]$RemoteName = 'origin',
    [string]$PlanPath,
    [string]$LogPath,
    [string]$TemplatesOverride,
    [switch]$QualityGate,
    [string]$CommitMessage = 'chore: sync via Cortex',
    [string]$RunId,
    [string]$ArtifactName,
    [string]$RunIdOrTag,
    [string]$ArtifactRepository,
    [string]$ArtifactDownloadUrl,
    [string]$ArtifactDestination,
    [string]$ExporterRuntime = 'win-x64',
    [switch]$ShowHelp
)

function Show-CortexHelp {
    Write-Host 'Cortex.ps1 opciones:'
    Write-Host '  -AutoOption 1  Scaffold (ProjectName, ProjectType, RepoPath, TemplatesOverride)'
    Write-Host '  -AutoOption 2  Analyze (RepoPath, QualityGate)'
    Write-Host '  -AutoOption 3  Build/Test multi-repo (usa Analyze)'
    Write-Host '  -AutoOption 4  SyncUp (RepoPath, Branch, RemoteName, CommitMessage)'
    Write-Host '  -AutoOption 5  SyncDown (RepoPath, Branch, RemoteName, CodexBranch opcional)'
    Write-Host '  -AutoOption 6  Artefactos (RunIdOrTag, ArtifactName, ArtifactRepository o DownloadUrl, ArtifactDestination)'
    Write-Host '  -AutoOption 7  Plan JSON/YAML (PlanPath, LogPath)'
    Write-Host 'Sin AutoOption se muestra menú interactivo.'
}

if ($ShowHelp) {
    Show-CortexHelp
    return
}

Assert-CortexWindowsPlatform

$runIdToUse = if ($RunId) { $RunId } else { "cortex-$(Get-Date -Format yyyyMMddHHmmss)" }
$logRoot = if ($LogPath) { $LogPath } else { Join-Path $RepoPath 'logs' }

if (-not $AutoOption) {
    Invoke-CortexMenu -RepoPath $RepoPath -ProjectName $ProjectName -ProjectType $ProjectType -PlanPath $PlanPath -LogPath $logRoot -RemoteName $RemoteName
    return
}

switch ($AutoOption) {
    1 {
        $target = Invoke-CortexScaffold -ProjectName $ProjectName -ProjectType $ProjectType -Output $RepoPath -TemplatesOverride $TemplatesOverride
        New-CortexLogEntry -RunId $runIdToUse -Repo $target -Operation 'Scaffold' -Status 'Success' -DurationMs 0 -Details 'Estructura generada' -Errors '' -LogPath $logRoot | Out-Null
    }
    2 {
        Invoke-CortexAnalysis -Paths @($RepoPath) -QualityGate:$QualityGate
    }
    3 {
        Invoke-CortexAnalysis -Paths @($RepoPath) -QualityGate:$QualityGate
    }
    4 {
        Invoke-CortexSyncUp -RepoPath $RepoPath -Branch $Branch -RemoteName $RemoteName -CommitMessage $CommitMessage
        New-CortexLogEntry -RunId $runIdToUse -Repo $RepoPath -Operation 'SyncUp' -Status 'Success' -DurationMs 0 -Details 'SyncUp completado' -Errors '' -LogPath $logRoot | Out-Null
    }
    5 {
        Invoke-CortexSyncDown -RepoPath $RepoPath -Branch $Branch -RemoteName $RemoteName
        New-CortexLogEntry -RunId $runIdToUse -Repo $RepoPath -Operation 'SyncDown' -Status 'Success' -DurationMs 0 -Details 'SyncDown completado' -Errors '' -LogPath $logRoot | Out-Null
    }
    6 {
        $destination = if ($ArtifactDestination) { $ArtifactDestination } else { Join-Path $RepoPath 'artifacts' }
        Invoke-CortexArtifactDownload -Destination $destination -RunIdOrTag $RunIdOrTag -ArtifactName $ArtifactName -Repository $ArtifactRepository -DownloadUrl $ArtifactDownloadUrl
        New-CortexLogEntry -RunId $runIdToUse -Repo $RepoPath -Operation 'Artifacts' -Status 'Success' -DurationMs 0 -Details "Artefactos descargados en $destination" -Errors '' -LogPath $logRoot | Out-Null
    }
    7 {
        if (-not $PlanPath) { throw 'PlanPath es obligatorio para AutoOption 7.' }
        Invoke-CortexPlan -PlanPath $PlanPath -LogPath $logRoot
    }
    default { throw "AutoOption no soportado: $AutoOption" }
}
