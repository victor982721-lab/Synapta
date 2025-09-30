```powershell
$env:REPO_AR_MODE = $null
.\tu_script.ps1 -Modo Real -RepoRoot "$env:TEMP\ARRepo" -RunVerification
$Global:InitConfig | Format-List *
```