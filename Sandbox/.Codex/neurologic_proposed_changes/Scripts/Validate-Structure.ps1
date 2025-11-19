<#
    .SYNOPSIS
        Valida la estructura de proyectos dentro de la carpeta Sandbox.

    .DESCRIPTION
        Este script recorre todas las subcarpetas de Sandbox (cada una asumida como un proyecto) y comprueba la existencia de:
          - `AGENTS.md`
          - `README.md`
          - carpeta `docs/`
          - carpeta `csv/`
        También muestra un resumen indicando qué proyectos cumplen con la estructura mínima y cuáles no.

    .PARAMETER RepoRoot
        Ruta al directorio raíz del repositorio. Si no se especifica, se usa el directorio en el que reside este script.

    .EXAMPLE
        pwsh -NoLogo -NoProfile -File .\Scripts\Validate-Structure.ps1 -RepoRoot "C:\Users\user\Documents\GitHub\Neurologic"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$RepoRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path)
)

function Test-ProjectStructure {
    param(
        [string]$ProjectPath,
        [string]$ProjectName
    )

    $requiredItems = @(
        'AGENTS.md',
        'README.md',
        'docs',
        'csv'
    )

    $ok = $true
    foreach ($item in $requiredItems) {
        $fullPath = Join-Path $ProjectPath $item
        if (-not (Test-Path $fullPath)) {
            Write-Warning "$ProjectName: falta $item"
            $ok = $false
        }
    }
    return $ok
}

try {
    $sandboxPath = Join-Path $RepoRoot 'Sandbox'
    if (-not (Test-Path $sandboxPath)) {
        Write-Error "No se encontró la carpeta 'Sandbox' en $RepoRoot"
        exit 1
    }

    $projects = Get-ChildItem -Path $sandboxPath -Directory
    if ($projects.Count -eq 0) {
        Write-Host "No hay subproyectos en Sandbox."
        exit 0
    }

    $allOk = $true
    foreach ($proj in $projects) {
        Write-Host "Revisando $($proj.Name)..." -ForegroundColor Cyan
        $projectOk = Test-ProjectStructure -ProjectPath $proj.FullName -ProjectName $proj.Name
        if ($projectOk) {
            Write-Host "  ✓ Estructura mínima completa" -ForegroundColor Green
        } else {
            $allOk = $false
        }
    }
    if ($allOk) {
        Write-Host "Todos los proyectos cumplen con la estructura mínima." -ForegroundColor Green
    } else {
        Write-Host "Se detectaron proyectos con estructura incompleta." -ForegroundColor Yellow
    }
} catch {
    Write-Error "Error durante la validación: $($_.Exception.Message)"
}
