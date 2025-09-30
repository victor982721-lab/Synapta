```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\filemap_sha256.ps1 `
  -Roots "C:\Users\VictorFabianVeraVill\Documents" "D:\Backups" `
  -Csv ".\filemap_sha256.csv" `
  -Exclude "AppData",".cache",".git"
```