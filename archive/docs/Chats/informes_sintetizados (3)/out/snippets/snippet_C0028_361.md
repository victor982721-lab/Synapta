```powershell
# 1) Crear CSV con columna 'path' correcta
$CSV = '.\FileList_Users_20250921_020839.csv'
Import-Csv $CSV |
  Select-Object *, @{n='path';e={ Join-Path 'C:\Users' $_.relpath }} |
  Export-Csv .\FileList_with_path.csv -NoTypeInformation -Encoding utf8

# 2) Generar hashes y probar movimiento (sin mover nada)
pwsh -ExecutionPolicy Bypass -File .\filemap_sha256.ps1 -InputCsv .\FileList_with_path.csv -PathColumn path -Csv .\filemap_sha256.csv
pwsh -ExecutionPolicy Bypass -File .\move_duplicates_by_hash.ps1 -Csv .\filemap_sha256.csv -DryRun
```