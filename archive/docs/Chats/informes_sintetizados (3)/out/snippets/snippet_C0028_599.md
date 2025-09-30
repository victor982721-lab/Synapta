```powershell
pwsh -ExecutionPolicy Bypass -File "C:\Users\VictorFabianVeraVill\Desktop\PowerShell\venv_quarantine.ps1" -Roots "C:\Users" -AlsoInclude "node_modules",".git" -TakeOwnership -Execute
```