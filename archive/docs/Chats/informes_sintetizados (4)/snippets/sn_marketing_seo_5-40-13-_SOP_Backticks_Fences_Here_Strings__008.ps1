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

            # Cierre de here-string con indentación (debe ir en col 1, sin espacios/tabs)
            if ($text -match '(?m)^\s+([\'"])@\s*$') {
                $issues += "Cierre de here-string con indentación o trailing spaces (debe ir en columna 1, sin espacios)"
            }

            # Uso de -f con llaves {}; nota: es heurística
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