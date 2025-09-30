```powershell
#requires -Version 5.1
Set-StrictMode -Version 3.0

param(
  [ValidateSet('Real','Prueba')]
  [string]$Modo = $null,

  [string]$RepoRoot = $null,

  [switch]$RunVerification
)

# Timestamp de ejecución — fijar una vez y en UTC
if (-not $Global:ExecTS) {
  $Global:ExecTS = [DateTime]::UtcNow.ToString('yyyyMMdd_HHmmssfff')
}
```