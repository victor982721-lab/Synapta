```powershell
pwsh -ExecutionPolicy Bypass -File .\filemap_sha256.ps1 `
  -InputCsv .\FileList_abs.csv -PathColumn abs_path -Csv .\filemap_sha256.csv `
  -Exclude ".gradle",".venv","node_modules",".git","site-packages"

pwsh -ExecutionPolicy Bypass -File .\move_duplicates_by_hash.ps1 -Csv .\filemap_sha256.csv -DryRun
```