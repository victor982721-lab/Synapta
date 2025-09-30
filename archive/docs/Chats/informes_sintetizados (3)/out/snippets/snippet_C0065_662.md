```powershell
$env:REPO_AR_MODE = 'Prueba'
.\tu_script.ps1 -RepoRoot "$env:TEMP\ARRepo2" -RunVerification -Verbose
Get-ChildItem "$env:TEMP\ARRepo2\VERIFICATION"
```