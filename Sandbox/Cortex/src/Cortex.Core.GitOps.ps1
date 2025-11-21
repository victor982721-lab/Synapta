. "$PSScriptRoot/Cortex.Common.ps1"

function Test-CortexCleanRepo {
    param([Parameter(Mandatory)][string]$RepoPath)
    $status = git -C $RepoPath status --porcelain
    return [string]::IsNullOrWhiteSpace($status)
}

function Invoke-CortexSyncUp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoPath,
        [string]$Branch = 'main',
        [string]$RemoteName = 'origin',
        [string]$CommitMessage = 'chore: sync via Cortex',
        [switch]$IncludeUntracked
    )

    Assert-CortexWindowsPlatform

    if (-not (Test-Path -Path $RepoPath)) {
        throw "No existe la ruta del repositorio: $RepoPath"
    }

    $argsAdd = @('add')
    if ($IncludeUntracked) { $argsAdd += '--all' }
    Invoke-CortexCommand -FilePath 'git' -Arguments @('-C', $RepoPath) + $argsAdd
    Invoke-CortexCommand -FilePath 'git' -Arguments @('-C', $RepoPath, 'commit', '-m', $CommitMessage)
    Invoke-CortexCommand -FilePath 'git' -Arguments @('-C', $RepoPath, 'pull', $RemoteName, $Branch)
    Invoke-CortexCommand -FilePath 'git' -Arguments @('-C', $RepoPath, 'push', $RemoteName, $Branch)
}

function Invoke-CortexSyncDown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoPath,
        [string]$Branch = 'main',
        [string]$RemoteName = 'origin',
        [string]$CodexBranch
    )

    Assert-CortexWindowsPlatform

    if (-not (Test-Path -Path $RepoPath)) {
        throw "No existe la ruta del repositorio: $RepoPath"
    }

    if (-not $CodexBranch) {
        $today = Get-Date
        $codexName = "Codex_{0}" -f $today.ToString('yyyy-MM-dd')
    }
    else {
        $codexName = $CodexBranch
    }

    Invoke-CortexCommand -FilePath 'git' -Arguments @('-C', $RepoPath, 'fetch', $RemoteName)
    Invoke-CortexCommand -FilePath 'git' -Arguments @('-C', $RepoPath, 'checkout', $Branch)
    Invoke-CortexCommand -FilePath 'git' -Arguments @('-C', $RepoPath, 'merge', "$RemoteName/$codexName")
}
