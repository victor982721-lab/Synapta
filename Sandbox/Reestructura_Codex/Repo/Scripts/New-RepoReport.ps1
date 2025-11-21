Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

param(
    [string]$Root = (Split-Path -Parent $MyInvocation.MyCommand.Path)
)

$repoRoot = Join-Path $Root '..'

$sections = @{
    Core      = Get-ChildItem -Path (Join-Path $repoRoot 'Core') -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    Sandbox   = Get-ChildItem -Path (Join-Path $repoRoot 'Sandbox') -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    Scripts   = Get-ChildItem -Path (Join-Path $repoRoot 'Scripts') -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
}

foreach ($section in $sections.GetEnumerator()) {
    Write-Host "[$($section.Key)]" -ForegroundColor Cyan
    if ($section.Value) {
        $section.Value | ForEach-Object { Write-Host " - $_" }
    } else {
        Write-Host ' (sin elementos)'
    }
}
