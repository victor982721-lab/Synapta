```powershell
function Test-FenceSafety {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Path
    )
    begin { Set-StrictMode -Version 3.0 }
    process {
        foreach ($p in $Path) {
            if (-not (Test-Path $p)) { continue }
            $text = Get-Content -Path $p -Raw

            $issues = @()

            if ($text -match '````') {  # 4 backticks
                $issues += 'Uso prohibido de 4 backticks (````)'
            }
            if ($text -match "^\s+['""]@") { # cierre here-string con indentación
                $issues += "Cierre de here-string con indentación (debe ir en columna 1)"
            }
            if ($text -match '-f\s+.*\{.*\}') {
                $issues += "Uso de -f con llaves {}; duplica llaves o evita -f"
            }

            [PSCustomObject]@{
                Path   = $p
                Issues = if ($issues) { $issues -join '; ' } else { '<OK>' }
            }
        }
    }
}
```