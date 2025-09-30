```powershell
pwsh -File .\New-FileMap.GUI.ps1 -NoGui `
  -RootPath "C:\Users" -OutDir "C:\Users\VictorFabianVeraVill\Desktop" `
  -EmitCsv -EmitJsonl -IncludeTree -OutputKind md `
  -ComputeHash -HashAlgorithm SHA256 -WithOwner `
  -BlockSize 5000 -ProgressInterval 500 -MaxDepth 0 `
  -ExcludeDirs ".git,node_modules,.venv,venv,env,.env,__pycache__" `
  -ExcludeExt ".tmp,.log,.bak,.map,.pyc,.class" `
  -TopBySize -TopByAge -TopN 100
```