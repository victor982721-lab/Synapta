```powershell
#requires -Version 5
param(
  [string]$Stem = "workspace-wizard-ps5-7",
  [string]$Dir  = "/mnt/data"
)
Set-Location -Path $Dir
Write-Host "# Recomputando SHA256 para $Stem*"
$files = @("$($Stem).ps1","$($Stem).txt","$($Stem).md","$($Stem).json","$($Stem).csv","$($Stem).html","$($Stem)_chart.png","$($Stem)_explanation.md","REPORT.md","manifest.json")
foreach ($f in $files) {
  if (Test-Path $f) {
    Try { Get-FileHash -Algorithm SHA256 -Path $f | ForEach-Object { "$($_.Hash.ToLower())  $($_.Path | Split-Path -Leaf)" } } Catch { Write-Error $_ }
  }
}
Write-Host "# Conteo de artefactos"
(Get-ChildItem -Name "$($Stem)*" -ErrorAction SilentlyContinue | Measure-Object).Count
```