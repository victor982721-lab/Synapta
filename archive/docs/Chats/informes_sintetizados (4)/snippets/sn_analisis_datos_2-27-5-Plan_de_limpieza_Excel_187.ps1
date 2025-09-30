# Verifica dónde estás
Get-Location
# Verifica si el archivo existe ahí
Test-Path .\FileList.csv

# Si no está, apunta a la ruta real del CSV:
pwsh -NoProfile -ExecutionPolicy Bypass -File .\filemap_sha256.ps1 `
  -InputCsv "C:\RUTA\REAL\AL\CSV\FileList.csv" `
  -PathColumn path `
  -Csv ".\filemap_sha256.csv"