<#

    Synapta.Maintenance.ps1

    - Verifica versiones de pwsh y dotnet
    - Importa módulos clave (PSScriptAnalyzer)
    - Comprueba soporte de hashing (MD5, XxHash3)
    - Expone funciones de hash para scripts pequeños

#>

#Region Parámetros de versión
$RequiredPwshVersion = [Version]'7.5.4'
$RequiredDotnetMajor = 8
$RequiredDotnetMinor = 0
#EndRegion Parámetros de versión

Write-Host "[synapta] *** Mantenimiento Synapta ***"

#Region Verificación de PowerShell
$psv = $PSVersionTable.PSVersion
if ($psv -ne $RequiredPwshVersion) {
    Write-Warning ("[synapta] pwsh esperado: {0}, actual: {1}" -f $RequiredPwshVersion, $psv)
} else {
    Write-Host ("[synapta] pwsh OK -> {0}" -f $psv)
}
#EndRegion Verificación de PowerShell

#Region Verificación de dotnet
try {
    $sdks = & dotnet --list-sdks 2>$null
} catch {
    $sdks = $null
}

if (-not $sdks) {
    Write-Warning "[synapta] 'dotnet --list-sdks' no devolvió resultados."
} else {
    $hasRequired = $sdks -match "^\s*$RequiredDotnetMajor\.$RequiredDotnetMinor\."
    if ($hasRequired) {
        Write-Host "[synapta] .NET SDK 8.x detectado:"
        $sdks | Where-Object { $_ -match '^\s*8\.' } | ForEach-Object {
            Write-Host "  - $_"
        }
    } else {
        Write-Warning "[synapta] No se encontró ningún SDK 8.x en 'dotnet --list-sdks'."
    }
}
#EndRegion Verificación de dotnet

#Region Importación de módulos
Write-Host "[synapta] Importando módulos..."

$modulesToImport = @(
    'PSScriptAnalyzer'
)

foreach ($m in $modulesToImport) {
    try {
        Import-Module -Name $m -ErrorAction Stop
        $modInfo = Get-Module -Name $m
        Write-Host ("  - {0} -> {1}" -f $m, ($modInfo.Version))
    } catch {
        Write-Warning ("  - No se pudo importar módulo '{0}': {1}" -f $m, $_.Exception.Message)
    }
}
#EndRegion Importación de módulos

#Region Detección de soporte de hashing
$hasMd5Cli = $false
$hasGetFileHashMd5 = $false
$hasXxHash3 = $false

# md5sum CLI (Linux)
if (Get-Command md5sum -ErrorAction SilentlyContinue) {
    $hasMd5Cli = $true
}

# Get-FileHash con MD5
try {
    $param = (Get-Command Get-FileHash -ErrorAction Stop).Parameters['Algorithm']
    $validValues = @()
    foreach ($attr in $param.Attributes) {
        if ($attr.PSObject.Properties['ValidValues']) {
            $validValues += $attr.ValidValues
        }
    }
    if ($validValues -contains 'MD5') {
        $hasGetFileHashMd5 = $true
    }
} catch {
    $hasGetFileHashMd5 = $false
}

# System.IO.Hashing.XxHash3 (no criptográfico)
try {
    Add-Type -AssemblyName System.IO.Hashing -ErrorAction Stop
    $null = [System.IO.Hashing.XxHash3]::Hash([byte[]]@(0))
    $hasXxHash3 = $true
} catch {
    $hasXxHash3 = $false
}

Write-Host "[synapta] Soporte de hashing:"
Write-Host ("  - md5sum CLI: {0}" -f $hasMd5Cli)
Write-Host ("  - Get-FileHash MD5: {0}" -f $hasGetFileHashMd5)
Write-Host ("  - System.IO.Hashing.XxHash3: {0}" -f $hasXxHash3)

if ($hasXxHash3) {
    $Global:SynaptaPreferredHash = 'XxHash3'
} elseif ($hasGetFileHashMd5 -or $hasMd5Cli) {
    $Global:SynaptaPreferredHash = 'MD5'
} else {
    $Global:SynaptaPreferredHash = 'None'
}
Write-Host ("[synapta] Algoritmo de hash preferido: {0}" -f $Global:SynaptaPreferredHash)
#EndRegion Detección de soporte de hashing

#Region Funciones de hash para scripts pequeños
function Get-SynaptaFileMd5 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Path
    )

    if (-not $hasGetFileHashMd5) {
        throw "MD5 no está disponible vía Get-FileHash en este entorno."
    }

    process {
        $resolved = Resolve-Path -LiteralPath $Path -ErrorAction Stop
        $result = Get-FileHash -Algorithm MD5 -LiteralPath $resolved
        $result.Hash.ToLowerInvariant()
    }
}

function Get-SynaptaFileXxHash3 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Path
    )

    if (-not $hasXxHash3) {
        throw "System.IO.Hashing.XxHash3 no está disponible en este runtime."
    }

    process {
        $resolved = Resolve-Path -LiteralPath $Path -ErrorAction Stop
        $bytes = [System.IO.File]::ReadAllBytes($resolved)
        $hashBytes = [System.IO.Hashing.XxHash3]::Hash($bytes)
        -join ($hashBytes | ForEach-Object { $_.ToString('x2') })
    }
}

Write-Host "[synapta] Funciones de hash disponibles:"
Write-Host "  - Get-SynaptaFileMd5 (si MD5 está disponible)"
Write-Host "  - Get-SynaptaFileXxHash3 (si XxHash3 está disponible)"
#EndRegion Funciones de hash para scripts pequeños

Write-Host "[synapta] *** Mantenimiento completado ***"
