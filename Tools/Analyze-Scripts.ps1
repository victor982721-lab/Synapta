#Requires -Version 7.0
<#
.SYNOPSIS
    Recorre un árbol de carpetas y genera un resumen rápido de cada script PowerShell.

.DESCRIPTION
    Para cada archivo *.ps1 y *.psm1 calcula:
        - Número y nombre de funciones declaradas.
        - Comandos externos/comunes utilizados (git, dotnet, Invoke-WebRequest, etc.).
        - Uso de Read-Host / Invoke-Expression / Start-Process y otras llamadas relevantes.
        - Errores de parseo (si los hubiera).

    El resultado se muestra en tabla y también puede exportarse a CSV/JSON.

.PARAMETER RootPath
    Carpeta raíz desde la que se analizarán los scripts. Por defecto, la carpeta padre del script.

.PARAMETER OutputPath
    (Opcional) Ruta a CSV o JSON donde se guardará el resultado. Si se omite, solo escribe en pantalla.

.EXAMPLE
    ./Analyze-Scripts.ps1 -RootPath ..\Sandbox\Cortex -OutputPath cortex-analysis.csv
#>
param(
    [string]$RootPath = (Split-Path -Parent $PSScriptRoot),
    [string]$OutputPath
)

if (-not (Test-Path $RootPath)) {
    Write-Error "No existe la ruta raíz: $RootPath"
    exit 1
}

Write-Host "[analyzer] Buscando scripts en $RootPath" -ForegroundColor Cyan

$scriptFiles = Get-ChildItem -Path $RootPath -Include *.ps1, *.psm1 -File -Recurse |
    Where-Object { -not $_.FullName.ToLower().Contains('packages') }

if (-not $scriptFiles) {
    Write-Warning "No se encontraron scripts PowerShell bajo $RootPath."
    return
}

$interestingCommands = @(
    'Invoke-WebRequest','Invoke-RestMethod','Invoke-Expression','Invoke-Command',
    'Start-Process','Read-Host','Invoke-Item','New-Object','Add-Type',
    'git','dotnet','gh','Set-StrictMode','Set-ExecutionPolicy','curl'
)

$results = foreach ($file in $scriptFiles) {
    $tokens = $null
    $errors = $null
    try {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $file.FullName, [ref]$tokens, [ref]$errors
        )
    } catch {
        [pscustomobject]@{
            Script        = $file.FullName
            Functions     = ''
            FunctionCount = 0
            Interesting   = ''
            Commands      = ''
            ParseErrors   = $_.Exception.Message
        }
        continue
    }

    $functions = $ast.FindAll({
        param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true) | ForEach-Object { $_.Name } | Sort-Object -Unique

    $commandAsts = $ast.FindAll({
        param($node) $node -is [System.Management.Automation.Language.CommandAst]
    }, $true)

    $commandNames = $commandAsts |
        ForEach-Object { $_.GetCommandName() } |
        Where-Object { $_ } |
        Sort-Object

    $interestingHits = $commandNames |
        Where-Object { $interestingCommands -contains $_ } |
        Group-Object |
        ForEach-Object { "{0} (x{1})" -f $_.Name, $_.Count }

    [pscustomobject]@{
        Script        = $file.FullName
        Functions     = ($functions -join ', ')
        FunctionCount = $functions.Count
        Interesting   = ($interestingHits -join '; ')
        Commands      = ($commandNames | Get-Unique | Select-Object -First 25) -join ', '
        ParseErrors   = ($errors | ForEach-Object { $_.Message }) -join '; '
    }
}

$results | Format-Table -AutoSize

if ($OutputPath) {
    $ext = [IO.Path]::GetExtension($OutputPath)
    switch ($ext.ToLower()) {
        '.json' { $results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutputPath -Encoding UTF8 }
        default { $results | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8 }
    }
    Write-Host "[analyzer] Resultado guardado en $OutputPath" -ForegroundColor Green
}
