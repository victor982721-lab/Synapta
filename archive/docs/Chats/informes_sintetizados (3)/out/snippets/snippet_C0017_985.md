```
$ErrorActionPreference = 'Stop'; Set-StrictMode -Version Latest; $Root='C:\Users\...\TBEA'; $SubPaths=@('01_Software'); function Convert-ToAsciiName { ... }; $destRoot=Join-Path $Root 'normalized'; New-Item -ItemType Directory -Force -Path $destRoot | Out-Null; foreach ($sub in $SubPaths) { ... }
```