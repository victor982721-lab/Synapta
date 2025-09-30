function New-AtomicUtf8File {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Content,
    [switch]$Utf8NoBOM
  )
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  $tmp = "$Path.tmp"
  $bak = "$Path.bak"
  $enc = if ($Utf8NoBOM) { New-Object System.Text.UTF8Encoding($false) } else { New-Object System.Text.UTF8Encoding($true) }
  [System.IO.File]::WriteAllText($tmp, $Content, $enc)
  if (Test-Path -LiteralPath $Path) {
    # Reemplazo atómico en la misma unidad; conserva .bak
    [System.IO.File]::Replace($tmp, $Path, $bak, $true)
  } else {
    Move-Item -LiteralPath $tmp -Destination $Path -Force
  }
}