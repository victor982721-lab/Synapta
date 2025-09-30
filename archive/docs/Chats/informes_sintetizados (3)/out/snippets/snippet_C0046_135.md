```powershell
$version = '1.2.3'
$fecha   = (Get-Date).ToString('yyyy-MM-dd')

$body = @'
# Título
Contenido con `$ y ``` sin expandir.
'@

$footer = @"
© 2025 — Proyecto Anastasis Revenari · Versión: $version · Fecha: $fecha
"@

Write-BacktickSafeFile -Path (Join-Path $PSScriptRoot 'salida\documento.md') -BodyLiteral $body -FooterExpandable $footer -WhatIf

# Validación rápida
Test-FenceSafety -Path (Join-Path $PSScriptRoot 'salida\documento.md')
```