# Sustituye el bloque PATH por:
$envPaths = @()
try {
  $envPaths = $env:PATH -split ';' |
    Where-Object { $_ } |
    ForEach-Object { $_.Trim() } |
    Where-Object { [System.IO.Directory]::Exists($_) -or [System.IO.File]::Exists($_) } |
    Select-Object -Unique
} catch { $errors.Add("PATH: $($_.Exception.Message)") }