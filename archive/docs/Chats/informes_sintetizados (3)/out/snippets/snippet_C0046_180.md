```powershell
function Write-Utf8NoBom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Content,
        [switch]$NoNewLine
    )
    Set-StrictMode -Version 3.0

    $dir = Split-Path -Path $Path -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

    # Normaliza a CRLF siempre (norma del proyecto para archivos Windows)
    $crlf = "`r`n"
    $text = if ($NoNewLine) { $Content } else { $Content + $crlf }

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $text, $utf8NoBom)
}
```