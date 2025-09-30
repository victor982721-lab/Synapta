```powershell
$body = @'
# Título
Contenido con `$ variables, ```backticks``` y { llaves } sin expandir.
'@

$footer = @"
© 2025 — Proyecto Anastasis Revenari · Versión: $version · Fecha: $fecha
"@

($body + "`r`n`r`n" + $footer) | Out-File $dest -Encoding utf8
```