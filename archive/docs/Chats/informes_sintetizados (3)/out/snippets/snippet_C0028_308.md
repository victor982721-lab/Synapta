```powershell
pwsh -File .\filemap_sha256.ps1 -Roots "C:\Users" -Csv .\filemap_sha256.csv -Exclude "AppData",".cache",".git","node_modules","__pycache__"
pwsh -File .\move_duplicates_by_hash.ps1 -Csv .\filemap_sha256.csv -DryRun
# si todo bien:
pwsh -File .\move_duplicates_by_hash.ps1 -Csv .\filemap_sha256.csv
```