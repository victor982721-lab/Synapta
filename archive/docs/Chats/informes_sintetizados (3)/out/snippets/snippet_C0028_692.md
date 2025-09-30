```powershell
pwsh -ExecutionPolicy Bypass -File .\move_sha256_duplicates.ps1 -Csv ".\duplicates_by_sha256.csv" -TakeOwnership
```