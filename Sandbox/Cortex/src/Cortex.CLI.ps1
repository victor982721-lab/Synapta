. "$PSScriptRoot/Cortex.Common.ps1"
. "$PSScriptRoot/Cortex.Core.Scaffolding.ps1"
. "$PSScriptRoot/Cortex.Core.GitOps.ps1"
. "$PSScriptRoot/Cortex.Core.Analysis.ps1"
. "$PSScriptRoot/Cortex.Core.Artifacts.ps1"
. "$PSScriptRoot/Cortex.Automation.ps1"
. "$PSScriptRoot/Cortex.Exporter.ps1"

function Invoke-CortexMenu {
    [CmdletBinding()]
    param(
        [string]$RepoPath = (Get-Location).Path,
        [string]$ProjectName = 'Demo',
        [ValidateSet('PS-CLI','DotNet-CLI','DotNet-UI')][string]$ProjectType = 'PS-CLI',
        [string]$PlanPath,
        [string]$LogPath,
        [string]$RemoteName = 'origin'
    )

    $choices = @(
        New-Object System.Management.Automation.Host.ChoiceDescription '&1 Scaffold', 'Crear estructura Sandbox/Core',
        New-Object System.Management.Automation.Host.ChoiceDescription '&2 Analyze', 'Parser AST / PSSA / dotnet build',
        New-Object System.Management.Automation.Host.ChoiceDescription '&3 SyncUp', 'git add/commit/pull/push',
        New-Object System.Management.Automation.Host.ChoiceDescription '&4 SyncDown', 'merge Codex en rama principal',
        New-Object System.Management.Automation.Host.ChoiceDescription '&5 Artifacts', 'Descarga/extrae artefactos',
        New-Object System.Management.Automation.Host.ChoiceDescription '&6 Plan', 'Ejecutar plan JSON/YAML',
        New-Object System.Management.Automation.Host.ChoiceDescription '&7 Exporter', 'Compilar script a EXE'
    )

    $selection = $Host.UI.PromptForChoice('Cortex', 'Selecciona operación:', $choices, 0)

    switch ($selection) {
        0 { Invoke-CortexScaffold -ProjectName $ProjectName -ProjectType $ProjectType -Output $RepoPath }
        1 { Invoke-CortexAnalysis -Paths @($RepoPath) -QualityGate }
        2 { Invoke-CortexSyncUp -RepoPath $RepoPath -RemoteName $RemoteName }
        3 { Invoke-CortexSyncDown -RepoPath $RepoPath -RemoteName $RemoteName }
        4 { Invoke-CortexArtifactDownload -Destination (Join-Path $RepoPath 'artifacts') }
        5 { if (-not $PlanPath) { throw 'PlanPath requerido para ejecutar plan.' } Invoke-CortexPlan -PlanPath $PlanPath -LogPath $LogPath }
        6 { Invoke-CortexExporter -Output (Join-Path $RepoPath 'Cortex.exe') }
    }
}
