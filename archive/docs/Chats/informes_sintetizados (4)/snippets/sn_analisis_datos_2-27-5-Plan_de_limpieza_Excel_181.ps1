# Opción A: escanear rutas
pwsh -File .\filemap_sha256.ps1 -Roots "D:\Datos" "E:\Backups" -Csv .\filemap_sha256.csv

# Opción B: partir de tu CSV (columna 'path')
pwsh -File .\filemap_sha256.ps1 -InputCsv .\FileList.csv -PathColumn path -Csv .\filemap_sha256.csv