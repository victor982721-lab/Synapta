```powershell
pwsh -ExecutionPolicy Bypass -File .\venv_quarantine.ps1 -Roots 'C:\Users' -AlsoInclude 'node_modules','.git' -TakeOwnership
```