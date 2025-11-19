[CmdletBinding()]
param(
    [string]$RepoRoot = "C:\Users\VictorFabianVeraVill\Documents\GitHub\Neurologic"
)

$rootPath   = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$adminScript = Join-Path $rootPath '=Sync=.ps1'
if (-not (Test-Path $adminScript)) {
    Write-Host "No se encontró el panel maestro (=Sync=.ps1). Ejecuta el script desde la raíz del repo Neurologic." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $RepoRoot)) {
    Write-Host "La ruta '$RepoRoot' no existe. Ajusta el parámetro -RepoRoot." -ForegroundColor Red
    exit 1
}

& $adminScript -InitialRepo $RepoRoot -AutoOption '1'
