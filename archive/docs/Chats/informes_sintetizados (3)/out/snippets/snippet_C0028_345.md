```powershell
pwsh -ExecutionPolicy Bypass -File .\filemap_sha256.ps1 -InputCsv .\FileList_with_path.csv -PathColumn path -Csv .\filemap_sha256.csv

pwsh -ExecutionPolicy Bypass -File .\move_duplicates_by_hash.ps1 -Csv .\filemap_sha256.csv -DryRun
```