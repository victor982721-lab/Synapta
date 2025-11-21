. "$PSScriptRoot/Cortex.Common.ps1"
. "$PSScriptRoot/Cortex.Core.Scaffolding.ps1"
. "$PSScriptRoot/Cortex.Core.GitOps.ps1"
. "$PSScriptRoot/Cortex.Core.Analysis.ps1"
. "$PSScriptRoot/Cortex.Core.Artifacts.ps1"
. "$PSScriptRoot/Cortex.Exporter.ps1"

function Read-CortexPlan {
    param(
        [Parameter(Mandatory)][string]$PlanPath
    )

    if (-not (Test-Path -Path $PlanPath)) {
        throw "No se encontró el archivo de plan: $PlanPath"
    }

    $ext = [IO.Path]::GetExtension($PlanPath).ToLowerInvariant()
    $content = Get-Content -Path $PlanPath -Raw -Encoding UTF8
    switch ($ext) {
        '.json' { return $content | ConvertFrom-Json }
        '.yml' { if (Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue) { return $content | ConvertFrom-Yaml } else { throw 'ConvertFrom-Yaml no disponible en esta sesión.' } }
        '.yaml' { if (Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue) { return $content | ConvertFrom-Yaml } else { throw 'ConvertFrom-Yaml no disponible en esta sesión.' } }
        default { throw 'Extensión de plan no soportada. Use JSON o YAML.' }
    }
}

function Invoke-CortexPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PlanPath,
        [string]$LogPath
    )

    Assert-CortexWindowsPlatform

    $plan = Read-CortexPlan -PlanPath $PlanPath
    if (-not $plan.jobs) { throw 'El plan no contiene trabajos.' }

    $runId = if ($plan.runId) { $plan.runId } else { "cortex-$(Get-Date -Format yyyyMMddHHmmss)" }
    $results = @{}
    foreach ($job in $plan.jobs) {
        if ($job.dependsOn) {
            foreach ($dep in $job.dependsOn) {
                if (-not $results.ContainsKey($dep) -or $results[$dep].Status -ne 'Success') {
                    throw "La dependencia '$dep' no se ejecutó correctamente."
                }
            }
        }

        $operation = $job.operation
        $repo = if ($job.repoPath) { $job.repoPath } else { (Get-Location).Path }
        $parameters = $job.parameters
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $status = 'Success'
        $details = ''
        $errors = ''

        try {
            switch ($operation) {
                'Scaffold' { Invoke-CortexScaffold -ProjectName $parameters.ProjectName -ProjectType $parameters.ProjectType -Output $parameters.Output }
                'Analyze'  { Invoke-CortexAnalysis -Paths @($repo) -QualityGate:([bool]$parameters.QualityGate) }
                'SyncUp'   { Invoke-CortexSyncUp -RepoPath $repo -Branch $parameters.Branch -RemoteName $parameters.RemoteName -CommitMessage $parameters.CommitMessage -IncludeUntracked:([bool]$parameters.IncludeUntracked) }
                'SyncDown' { Invoke-CortexSyncDown -RepoPath $repo -Branch $parameters.Branch -RemoteName $parameters.RemoteName -CodexBranch $parameters.CodexBranch }
                'Artifacts' { Invoke-CortexArtifactDownload -Destination $parameters.Destination -RunIdOrTag $parameters.RunIdOrTag -ArtifactName $parameters.ArtifactName -Repository $parameters.Repository -DownloadUrl $parameters.DownloadUrl }
                'Export' { Invoke-CortexExporter -Output $parameters.Output -Runtime $parameters.Runtime }
                default { throw "Operación no soportada en plan: $operation" }
            }
            $details = "$operation ejecutado"
        }
        catch {
            $status = 'Failed'
            $errors = $_.Exception.Message
        }
        finally {
            $sw.Stop()
        }

        $entry = New-CortexLogEntry -RunId $runId -Repo $repo -Operation $operation -Status $status -DurationMs $sw.ElapsedMilliseconds -Details $details -Errors $errors -LogPath $LogPath
        $results[$job.name] = $entry
    }

    return $results.Values
}
