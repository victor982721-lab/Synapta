```powershell
pwsh -File .\filemap_sha256.ps1 `
  -InputCsv .\FileList_Users_20250921_020839.csv `
  -PathColumn path `
  -Csv .\filemap_sha256.csv
```