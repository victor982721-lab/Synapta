```powershell
function RepoAR-NewTS {
    [CmdletBinding()]
    param([int]$Pad = 6)
    Set-StrictMode -Version 3.0
    return (Get-Date -Format 'yyyyMMdd_HHmmssfff').PadRight($Pad,'0')
}
```