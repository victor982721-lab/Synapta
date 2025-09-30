```powershell
pwsh -ExecutionPolicy Bypass -File .\build_sha256_duplicates.ps1 -Root "C:\Users" -OutCsv ".\duplicates_by_sha256.csv" -OutJson ".\duplicates_by_sha256.json"
```