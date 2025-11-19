<#
    .SYNOPSIS
        Busca marcadores de conflictos de merge en archivos versionados del repositorio.

    .DESCRIPTION
        Este script utiliza Git para listar los archivos rastreados y comprueba si contienen las cadenas
        '<<<<<<<', '=======', o '>>>>>>>' indicativas de un conflicto de merge sin resolver. Si se encuentran,
        imprime la ruta del archivo y una advertencia. Puede ayudarte a detectar conflictos antes de hacer
        commit o push.

    .EXAMPLE
        pwsh -NoLogo -NoProfile -File .\Scripts\Detect-MergeConflicts.ps1
#>

[CmdletBinding()]
param()

try {
    # Comprueba si git está disponible
    $git = Get-Command git -ErrorAction Stop

    $files = git ls-files
    $conflictFound = $false
    foreach ($file in $files) {
        $content = Get-Content -LiteralPath $file -ErrorAction SilentlyContinue
        if ($content -match '<<<<<<<' -or $content -match '=======' -or $content -match '>>>>>>>') {
            Write-Warning "Conflictos detectados en: $file"
            $conflictFound = $true
        }
    }
    if (-not $conflictFound) {
        Write-Host "No se encontraron marcadores de conflicto en los archivos versionados." -ForegroundColor Green
    }
} catch {
    Write-Error "Ocurrió un error al ejecutar el script: $($_.Exception.Message)"
}
