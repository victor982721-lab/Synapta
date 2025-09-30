```powershell
function Write-Utf8NoBom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Content,
        [switch]$NoNewLine
    )
    Set-StrictMode -Version 3.0
    $dir = Split-Path -Path $Path -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

    if ($PSVersionTable.PSVersion.Major -ge 7) {
        if ($NoNewLine) {
            [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
        } else {
            [System.IO.File]::WriteAllText($Path, $Content + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
        }
        return
    }

    # PS5.1: forzar UTF-8 sin BOM
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $bytes = $utf8NoBom.GetBytes($(if ($NoNewLine) { $Content } else { $Content + [Environment]::NewLine }))
    [System.IO.File]::WriteAllBytes($Path, $bytes)
}
```