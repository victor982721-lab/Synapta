[CmdletBinding()]
param(
    [string]$RepoPath = (Get-Location).Path,
    [string]$ProjectName = 'SandboxProject',
    [ValidateSet('PS-CLI','DotNet-CLI','DotNet-UI')][string]$ProjectType = 'PS-CLI',
    [string]$PlanPath,
    [string]$LogPath,
    [string]$RemoteName = 'origin',
    [string]$ExporterRuntime = 'win-x64'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$cortexScript = Join-Path $root 'Entregable/Cortex.ps1'

& $cortexScript -Interactive -RepoPath $RepoPath -ProjectName $ProjectName -ProjectType $ProjectType -PlanPath $PlanPath -LogPath $LogPath -RemoteName $RemoteName -ExporterRuntime $ExporterRuntime
