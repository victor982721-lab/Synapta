# Si necesitas tomar ownership en algunos archivos:
pwsh -ExecutionPolicy Bypass -File .\move_sha256_duplicates_v2.ps1 -Csv ".\duplicates_by_sha256.csv" -TakeOwnership

# Conservar por orden alfabético (en vez de mtime más antiguo):
pwsh -ExecutionPolicy Bypass -File .\move_sha256_duplicates_v2.ps1 -Csv ".\duplicates_by_sha256.csv" -KeepBy Alphabetical