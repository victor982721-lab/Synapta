. "$PSScriptRoot/Cortex.Common.ps1"

function Invoke-CortexExporter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Output,
        [string]$Runtime = 'win-x64',
        [string]$SourceScript
    )

    Assert-CortexWindowsPlatform

    if (-not $SourceScript) {
        $SourceScript = Join-Path (Split-Path -Parent $PSScriptRoot) 'Entregable/Cortex.ps1'
    }

    if (Test-CortexCommand -Name 'ps2exe') {
        Invoke-CortexCommand -FilePath 'ps2exe' -Arguments @($SourceScript, $Output, '-noConsole', '-runtime', $Runtime)
    }
    else {
        $message = "ps2exe no está instalado. Ejecuta: Install-Module ps2exe -Scope CurrentUser; luego ps2exe $SourceScript $Output"
        Write-Warning $message
        $message | Out-File -FilePath "$Output.txt" -Encoding utf8
    }
}
