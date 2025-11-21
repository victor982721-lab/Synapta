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
<<<<<<< HEAD
        [string]$RemoteName = 'origin'
=======
        [string]$RemoteName = 'origin',
        [string]$ExporterRuntime = 'win-x64'
>>>>>>> origin/codex_2025-11-21
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
<<<<<<< HEAD
        0 { Invoke-CortexScaffold -ProjectName $ProjectName -ProjectType $ProjectType -Output $RepoPath }
        1 { Invoke-CortexAnalysis -Paths @($RepoPath) -QualityGate }
        2 { Invoke-CortexSyncUp -RepoPath $RepoPath -RemoteName $RemoteName }
        3 { Invoke-CortexSyncDown -RepoPath $RepoPath -RemoteName $RemoteName }
        4 { Invoke-CortexArtifactDownload -Destination (Join-Path $RepoPath 'artifacts') }
        5 { if (-not $PlanPath) { throw 'PlanPath requerido para ejecutar plan.' } Invoke-CortexPlan -PlanPath $PlanPath -LogPath $LogPath }
        6 { Invoke-CortexExporter -Output (Join-Path $RepoPath 'Cortex.exe') }
    }
}
=======
        0 {
            $resolvedName = Read-Host "Nombre de proyecto" -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($resolvedName)) { $ProjectName = $resolvedName }
            Invoke-CortexScaffold -ProjectName $ProjectName -ProjectType $ProjectType -Output $RepoPath
        }
        1 {
            Write-Progress -Activity 'Cortex' -Status 'Ejecutando Parser/PSSA' -PercentComplete 0
            Invoke-CortexAnalysis -Paths @($RepoPath) -QualityGate
            Write-Progress -Activity 'Cortex' -Completed -Status 'Análisis completado'
        }
        2 {
            $commitMessage = Read-Host "Mensaje de commit" -ErrorAction SilentlyContinue
            Invoke-CortexSyncUp -RepoPath $RepoPath -RemoteName $RemoteName -CommitMessage ($commitMessage | ForEach-Object { if ($_) { $_ } else { 'chore: sync via Cortex' } })
        }
        3 {
            Invoke-CortexSyncDown -RepoPath $RepoPath -RemoteName $RemoteName
        }
        4 {
            $destination = Join-Path $RepoPath 'artifacts'
            Invoke-CortexArtifactDownload -Destination $destination
        }
        5 {
            if (-not $PlanPath) { throw 'PlanPath requerido para ejecutar plan.' }
            Invoke-CortexPlan -PlanPath $PlanPath -LogPath $LogPath
        }
        6 {
            Invoke-CortexExporter -Output (Join-Path $RepoPath 'Cortex.exe') -Runtime $ExporterRuntime
        }
    }
}

function Invoke-CortexWizard {
    [CmdletBinding()]
    param(
        [string]$RepoPath = (Get-Location).Path,
        [string]$ProjectName = 'Demo',
        [ValidateSet('PS-CLI','DotNet-CLI','DotNet-UI')][string]$ProjectType = 'PS-CLI',
        [string]$PlanPath,
        [string]$LogPath,
        [string]$RemoteName = 'origin',
        [string]$ExporterRuntime = 'win-x64'
    )

    do {
        Invoke-CortexMenu -RepoPath $RepoPath -ProjectName $ProjectName -ProjectType $ProjectType -PlanPath $PlanPath -LogPath $LogPath -RemoteName $RemoteName -ExporterRuntime $ExporterRuntime
        $again = $Host.UI.PromptForChoice('Cortex', '¿Ejecutar otra operación?', @(
            New-Object System.Management.Automation.Host.ChoiceDescription '&Si', 'Continuar',
            New-Object System.Management.Automation.Host.ChoiceDescription '&No', 'Salir'
        ), 1)
    }
    while ($again -eq 0)
}
>>>>>>> origin/codex_2025-11-21
